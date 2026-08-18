#!/usr/bin/env bash
# test-windows-crlf.sh — Portabilité Windows (ADR-054). Reproduit les DEUX pannes du rapport
# terrain 2026-07-22 (Windows 11 + Git Bash) SANS poste Windows :
#   A. jq Windows natif émettant du CRLF (mode texte) → shim `jq` qui suffixe \r\n à chaque ligne
#   B. jq totalement absent du PATH → PATH minimal sans jq
# Convention TESTING.md (pass/fail, ok/ko, fixtures mktemp, invocation via bash).
# BASH_BIN surchargeable (ex. BASH_BIN=/bin/bash pour valider bash 3.2 macOS).
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "$HERE/../.." && pwd)"
RESOLVE="$PLUGIN_ROOT/_internal/resolve-deps.sh"
CATALOG="$PLUGIN_ROOT/installer/scripts/build-module-catalog.sh"
FRAMEWORK_VERSION="$PLUGIN_ROOT/conductor/scripts/framework-version.sh"
BASH_BIN="${BASH_BIN:-bash}"

pass=0; fail=0
ok() { echo "  ✓ $1"; pass=$((pass+1)); }
ko() { echo "  ✗ $1"; fail=$((fail+1)); }

echo "== test-windows-crlf (ADR-054) =="

REAL_JQ="$(command -v jq)" || { echo "jq requis pour lancer ce test" >&2; exit 2; }
CR="$(printf '\r')"

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# ---------- Shim A : jq CRLF (fidèle au binaire Windows natif en mode texte) ----------
mkdir -p "$WORK/crlf-bin"
cat > "$WORK/crlf-bin/jq" <<SHIM
#!/bin/bash
set -o pipefail
"$REAL_JQ" "\$@" | awk '{printf "%s\r\n", \$0}'
SHIM
chmod +x "$WORK/crlf-bin/jq"

if printf '{}' | PATH="$WORK/crlf-bin:$PATH" jq -c . | LC_ALL=C command grep -q "$CR"; then
  ok "sanity : shim CRLF opérationnel"
else
  ko "sanity : shim CRLF inopérant — test invalide"; echo "== $pass ok · $fail ko =="; exit 1
fi

# ---------- Fixture modules : boss(mandatory)→alpha→beta ; wip(proposable:false) ----------
FIX="$WORK/modules"
mkdir -p "$FIX/boss" "$FIX/alpha" "$FIX/beta" "$FIX/wip"
cat > "$FIX/boss/module.json" <<'J'
{ "name": "boss", "version": "v1.0.0", "type": "agent", "description": "Mandatory de test.", "mandatory": true, "requires": ["alpha"] }
J
cat > "$FIX/alpha/module.json" <<'J'
{ "name": "alpha", "version": "v1.0.0", "type": "single-skill", "description": "Optionnel de test.", "requires": ["beta"] }
J
cat > "$FIX/beta/module.json" <<'J'
{ "name": "beta", "version": "v1.0.0", "type": "single-skill", "description": "Feuille de test.", "requires": [] }
J
cat > "$FIX/wip/module.json" <<'J'
{ "name": "wip", "version": "v1.0.0", "type": "doc-only", "description": "WIP caché.", "proposable": false, "requires": [] }
J

# ---------- T1-T2 : resolve-deps sous jq CRLF → fermeture complète, LF pur, rc=0 ----------
out=$(PATH="$WORK/crlf-bin:$PATH" VF_MODULES_ROOT="$FIX" "$BASH_BIN" "$RESOLVE" boss 2>"$WORK/t1.err"); rc=$?
want="$(printf 'alpha\nbeta\nboss')"
if [ "$rc" -eq 0 ] && [ "$out" = "$want" ]; then
  ok "T1 resolve-deps CRLF : fermeture transitive complète (alpha beta boss), rc=0"
else
  ko "T1 resolve-deps CRLF : rc=$rc out=[$out] err=[$(cat "$WORK/t1.err" 2>/dev/null)]"
fi
if printf '%s' "$out" | LC_ALL=C command grep -q "$CR"; then
  ko "T2 resolve-deps CRLF : \\r résiduel dans la sortie"
else
  ok "T2 resolve-deps CRLF : sortie LF pure (aucun \\r)"
fi

# ---------- T3-T5 : catalogue sous jq CRLF → mandatory conservé, WIP exclu, TSV pur ----------
cat_out=$(PATH="$WORK/crlf-bin:$PATH" VF_MODULES_ROOT="$FIX" "$BASH_BIN" "$CATALOG" 2>/dev/null)
role_boss=$(printf '%s\n' "$cat_out" | command grep '^boss' | cut -f3)
if [ "$role_boss" = "mandatory" ]; then
  ok "T3 catalog CRLF : boss reste role=mandatory"
else
  ko "T3 catalog CRLF : boss role=[$role_boss] (attendu mandatory — dégradation silencieuse)"
fi
if printf '%s\n' "$cat_out" | command grep -q '^wip'; then
  ko "T4 catalog CRLF : module proposable:false FUIT dans le catalogue"
else
  ok "T4 catalog CRLF : proposable:false exclu"
fi
if printf '%s' "$cat_out" | LC_ALL=C command grep -q "$CR"; then
  ko "T5 catalog CRLF : \\r résiduel dans le TSV"
else
  ok "T5 catalog CRLF : TSV LF pur"
fi

# ---------- T6 : framework-version drift sous jq CRLF → pas de faux RETARD ----------
FAKEPLUG="$WORK/fakeplug"; mkdir -p "$FAKEPLUG/.claude-plugin"
printf '{ "name": "vibeflow", "version": "9.9.9" }\n' > "$FAKEPLUG/.claude-plugin/plugin.json"
LAB="$WORK/lab"; mkdir -p "$LAB/.claude"; printf '9.9.9\n' > "$LAB/.claude/.vibeflow-framework-version"
if PATH="$WORK/crlf-bin:$PATH" "$BASH_BIN" "$FRAMEWORK_VERSION" drift --plugin-root "$FAKEPLUG" --lab-root "$LAB" >/dev/null 2>&1; then
  ok "T6 framework-version CRLF : versions égales → à jour (pas de faux RETARD)"
else
  ko "T6 framework-version CRLF : faux RETARD signalé (\\r dans la comparaison)"
fi

# ---------- T7 : gate anti-régression — jq NU interdit hors wrapper jqx (5 scripts) ----------
raw=0
for f in "$RESOLVE" "$CATALOG" "$FRAMEWORK_VERSION" \
         "$PLUGIN_ROOT/kpi-analyst/scripts/kpis-writer.sh" \
         "$PLUGIN_ROOT/kpi-analyst/scripts/extractor-template.sh"; do
  hits=$(command grep -nE '(^|[|&(;`[:space:]=])jq[[:space:]]' "$f" \
    | command grep -v 'jqx()' \
    | command grep -vE '^[0-9]+:[[:space:]]*#' \
    | command grep -v 'command -v jq' || true)
  if [ -n "$hits" ]; then
    raw=1
    echo "    jq nu dans $(basename "$f"):"
    printf '%s\n' "$hits" | sed 's/^/      /'
  fi
done
if [ "$raw" -eq 0 ]; then
  ok "T7 gate : aucun jq nu hors wrapper jqx dans les 5 scripts"
else
  ko "T7 gate : invocation(s) jq nue(s) détectée(s) — utiliser jqx (ADR-054)"
fi

# ---------- T8-T9 : jq ABSENT → échec BRUYANT + message d'install par OS ----------
mkdir -p "$WORK/nojq-bin"
for t in dirname sort awk sed grep cat head printf tr uname env; do
  p=$(command -v "$t" 2>/dev/null) && ln -s "$p" "$WORK/nojq-bin/$t" 2>/dev/null
done
ln -s "$(command -v bash)" "$WORK/nojq-bin/bash" 2>/dev/null || true
nout=$(env PATH="$WORK/nojq-bin" VF_MODULES_ROOT="$FIX" "$BASH_BIN" "$RESOLVE" boss 2>&1); nrc=$?
if [ "$nrc" -ne 0 ]; then
  ok "T8 resolve-deps sans jq : échec BRUYANT (rc=$nrc — plus jamais de fermeture incomplète rc=0)"
else
  ko "T8 resolve-deps sans jq : rc=0 avec sortie [$nout] (régression : fermeture incomplète silencieuse)"
fi
if printf '%s' "$nout" | command grep -q 'winget install jqlang.jq'; then
  ok "T9 resolve-deps sans jq : message d'install par OS présent"
else
  ko "T9 resolve-deps sans jq : message d'install absent [$nout]"
fi

# ---------- T10-T12 : dev-orchestrator, ledger d'exigences (LEDG-01/02) sous CRLF ----------
# Symptôme distinct de T1-T9 (jamais un jq CRLF) : sous `core.autocrlf=true` (défaut Git for
# Windows, cité par l'en-tête ADR-054 de `.gitattributes`), un `.md` de LAB — que ce dépôt ne
# contrôle pas — peut porter des fins de ligne CRLF. Correctif ciblé 2026-08-18 (correction
# post-vérification, BLOQUANT G1) : normalisation `tr -d '\r'` au point de lecture dans les trois
# scripts, jamais une réécriture des fichiers du lab. Trois symptômes reproduits par exécution
# AVANT correctif, rejoués ici rouge-avant/vert-après.
CHECK_SURV="$PLUGIN_ROOT/dev-orchestrator/scripts/check-requirements-survival.sh"
RESTORE_LEDGER="$PLUGIN_ROOT/dev-orchestrator/scripts/restore-requirements-ledger.sh"
LEDGWORK="$WORK/ledger-crlf"; mkdir -p "$LEDGWORK/.planning/milestones"
printf '# Milestones\r\n\r\n## \xe2\x9c\x85 demo-v1\r\n' > "$LEDGWORK/.planning/MILESTONES.md"
printf -- '- [x] **AAAA-01**: item livre\r\n- [ ] **BBBB-01**: item en attente\r\n\r\n## Traceability\r\n\r\n| Requirement | Phase | Status |\r\n|---|---|---|\r\n| AAAA-01 | Phase 1 | Done - plan 1 |\r\n| BBBB-01 | Phase 1 | Planned - plan 2 |\r\n' > "$LEDGWORK/.planning/milestones/demo-v1-REQUIREMENTS.md"

t10_out="$("$BASH_BIN" "$CHECK_SURV" --path "$LEDGWORK" 2>/dev/null)"; t10_rc=$?
t10_has=0; case "$t10_out" in "[ledger-absent]"*"demo-v1"*) t10_has=1 ;; esac
t10_leaked=0; printf '%s' "$t10_out" | command grep -q 'label_rejected' && t10_leaked=1
if [ "$t10_rc" -eq 0 ] && [ "$t10_has" -eq 1 ] && [ "$t10_leaked" -eq 0 ]; then
  ok "T10 check-requirements-survival CRLF : titre H2 clos sans description → [ledger-absent] normal, jamais label_rejected"
else
  ko "T10 check-requirements-survival CRLF : rc=$t10_rc out=[$t10_out]"
fi

t11_out="$("$BASH_BIN" "$RESTORE_LEDGER" --path "$LEDGWORK" --write 2>/dev/null)"; t11_rc=$?
t11_counts=0; case "$t11_out" in *"Garanties: 1, Voyage: 1"*) t11_counts=1 ;; esac
T11_F="$LEDGWORK/.planning/REQUIREMENTS.md"
t11_no_cr=0; if [ -f "$T11_F" ] && ! command grep -q "$CR" "$T11_F"; then t11_no_cr=1; fi
if [ "$t11_rc" -eq 0 ] && [ "$t11_counts" -eq 1 ] && [ "$t11_no_cr" -eq 1 ]; then
  ok "T11 restore-requirements-ledger CRLF : Garanties: 1, Voyage: 1 (baseline LF), fichier écrit sans \\r résiduel"
else
  ko "T11 restore-requirements-ledger CRLF : rc=$t11_rc out=[$t11_out] cr_absent=$t11_no_cr"
fi
rm -f "$T11_F"

LEDGWORK2="$WORK/ledger-crlf-trace"; mkdir -p "$LEDGWORK2/.planning"
printf '# Milestones\n\n## \xe2\x9c\x85 demo-v1 \xe2\x80\x94 Un jalon clos\n' > "$LEDGWORK2/.planning/MILESTONES.md"
printf '# Requirements\r\n- [ ] **SSSS-01**: exigence voyageuse carried-from: v1.2\r\n' > "$LEDGWORK2/.planning/REQUIREMENTS.md"
t12_out="$("$BASH_BIN" "$CHECK_SURV" --path "$LEDGWORK2" 2>/dev/null)"; t12_rc=$?
if [ "$t12_rc" -eq 3 ] && [ -z "$t12_out" ]; then
  ok "T12 check-requirements-survival CRLF : trace carried-from: bien formée en CRLF → silence, jamais trace_malformed"
else
  ko "T12 check-requirements-survival CRLF : rc=$t12_rc out=[$t12_out] (attendu rc=3, silence)"
fi

echo "== $pass ok · $fail ko =="
[ "$fail" -eq 0 ]
