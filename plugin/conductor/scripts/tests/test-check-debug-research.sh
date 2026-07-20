#!/usr/bin/env bash
# test-check-debug-research.sh — Suite du gate « recherche documentaire avant debug » (ADR-045).
#
# check-debug-research.sh :
#   T1 — brique debug qui référence doc-research-before-debug → conforme (exit 0)
#   T2 — brique debug qui mentionne context7 → conforme (exit 0)
#   T3 — brique debug sans aucun marqueur recherche doc → exit 1 (erreur bloquante)
#   T4 — brique hors périmètre (pas de signature debug) → ignorée (exit 0)
#   T5 — wrapper mince qui délègue sans marqueur → warning (exit 0), ERREUR en --strict (exit 1)
#   T6 — --hook : exit 0 même non conforme, signalement compact
#   T7 — --file sur une brique conforme réelle (vf-debug) → exit 0
#   T8 — labels désambiguïsés : deux skills SKILL.md distincts identifiés par dossier parent
#   T9 — aucune brique → exit 0 (rien à vérifier)

set -uo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS_DIR="$(cd "$TESTS_DIR/.." && pwd)"
CHECK="$SCRIPTS_DIR/check-debug-research.sh"

pass=0; fail=0
ok() { echo "  ✓ $1"; pass=$((pass+1)); }
ko() { echo "  ✗ $1"; fail=$((fail+1)); }

echo "== test-check-debug-research (gate: $CHECK) =="

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
AG="$WORK/agents"; SK="$WORK/skills"
mkdir -p "$AG"

skill() { # $1 = dossier · $2 = description · $3 = corps
  mkdir -p "$SK/$1"
  printf -- '---\nname: %s\ndescription: %s\n---\n%s\n' "$1" "$2" "$3" > "$SK/$1/SKILL.md"
}
run_check() { bash "$CHECK" --agents-dir="$AG" --skills-dir="$SK" "$@"; }
reset_sk() { rm -rf "$SK"; mkdir -p "$SK"; }

# T1 — référence la règle
reset_sk
skill "vf-debug-like" "Débugge un crash, stack trace, ça plante" "Pré-étape : voir doc-research-before-debug."
if run_check >/dev/null 2>&1; then ok "T1 référence doc-research-before-debug → conforme"; else ko "T1 rejeté à tort"; fi

# T2 — mentionne context7
reset_sk
skill "diag" "Diagnostique un bug, erreur" "D'abord context7 (resolve-library-id) puis on investigue."
if run_check >/dev/null 2>&1; then ok "T2 mention context7 → conforme"; else ko "T2 rejeté à tort"; fi

# T3 — aucun marqueur
reset_sk
skill "raw-debug" "Débugge un bug, erreur, crash" "Reproduis, hypothèse, teste, corrige."
OUT="$(run_check 2>&1)"; RC=$?
if [ $RC -eq 1 ] && echo "$OUT" | grep -q "SANS phase recherche documentaire"; then
  ok "T3 brique debug sans recherche doc → erreur bloquante"
else
  ko "T3 (rc=$RC) : $OUT"
fi

# T4 — hors périmètre
reset_sk
skill "marketing-report" "Génère un rapport marketing" "Aucune notion de dépannage ici."
OUT="$(run_check 2>&1)"; RC=$?
if [ $RC -eq 0 ] && echo "$OUT" | grep -q "aucune brique de dépannage"; then
  ok "T4 brique hors périmètre → ignorée"
else
  ko "T4 (rc=$RC) : $OUT"
fi

# T5 — wrapper qui délègue : warning en défaut, erreur en --strict
reset_sk
skill "thin-wrapper" "Diagnostique un problème, ça plante" "Invoque le skill gsd-debug."
RC_DEF=0; run_check >/dev/null 2>&1 || RC_DEF=$?
RC_STRICT=0; run_check --strict >/dev/null 2>&1 || RC_STRICT=$?
if [ "$RC_DEF" -eq 0 ] && [ "$RC_STRICT" -eq 1 ]; then
  ok "T5 wrapper qui délègue : warning en défaut, ERREUR en --strict"
else
  ko "T5 (défaut=$RC_DEF strict=$RC_STRICT)"
fi

# T6 — hook mode
reset_sk
skill "raw-debug" "Débugge un crash" "Reproduis et corrige."
OUT="$(run_check --hook 2>&1)"; RC=$?
if [ $RC -eq 0 ] && echo "$OUT" | grep -q "sans recherche documentaire"; then
  ok "T6 --hook : exit 0 + signalement compact"
else
  ko "T6 (rc=$RC) : $OUT"
fi

# T7 — --file sur la brique réelle vf-debug
VF_DEBUG="$SCRIPTS_DIR/../../dev-orchestrator/skills/vf-debug/SKILL.md"
if [ -f "$VF_DEBUG" ]; then
  if bash "$CHECK" --file "$VF_DEBUG" >/dev/null 2>&1; then
    ok "T7 vf-debug réel → conforme (--file)"
  else
    ko "T7 vf-debug réel rejeté"
  fi
else
  ok "T7 vf-debug introuvable dans ce contexte — skip"
fi

# T8 — labels désambiguïsés
reset_sk
skill "alpha-debug" "Débugge un crash" "Reproduis."
skill "beta-debug" "Diagnostique un bug" "Corrige."
OUT="$(run_check 2>&1)"; RC=$?
if [ $RC -eq 1 ] && echo "$OUT" | grep -q "alpha-debug/SKILL.md" && echo "$OUT" | grep -q "beta-debug/SKILL.md"; then
  ok "T8 labels par dossier parent (deux SKILL.md distingués)"
else
  ko "T8 (rc=$RC) : $OUT"
fi

# T9 — aucune brique
reset_sk
if run_check >/dev/null 2>&1; then ok "T9 aucune brique → exit 0"; else ko "T9 exit non-0 sur répertoire vide"; fi

# ---------- durcissements audit S061 (CND-06) ----------

# T10 — 'crash-free' (KPI mobile) et 'Diagnostique la santé du funnel' ne sont PAS du dépannage
reset_sk
skill "perf-mobile" "Surveille le crash-free rate et les KPI de stabilite de l app" "Rapporte les metriques."
skill "funnel-sante" "Diagnostique la sante du funnel d acquisition et propose des optimisations" "Analyse le funnel."
if run_check >/dev/null 2>&1; then
  ok "T10 crash-free / diagnostic métier → hors périmètre (CND-06)"
else
  ko "T10 faux positif : $(run_check 2>&1 | tail -2)"
fi

# T11 — 'diagnostic' + contexte bug/erreur reste bien capturé
reset_sk
skill "vrai-depannage" "Diagnostique les erreurs de build et remonte la cause racine" "Corrige direct."
RC=0; run_check >/dev/null 2>&1 || RC=$?
[ "$RC" -eq 1 ] && ok "T11 diagnostic + erreur → toujours capturé" || ko "T11 faux négatif (rc=$RC)"

# T12 — dogfood : les briques debug-adjacentes LIVRÉES passent le linter livré
reset_sk
DOGFOOD_FAIL=""
for f in "$SCRIPTS_DIR/../../mobile-test-team/agents/vf-test-runner.md" \
         "$SCRIPTS_DIR/../../mobile-test-team/agents/vf-app-fixer.md" \
         "$SCRIPTS_DIR/../../mobile-test-team/agents/vf-test-orchestrator.md"; do
  [ -f "$f" ] || continue
  bash "$CHECK" --file "$f" >/dev/null 2>&1 || DOGFOOD_FAIL="$DOGFOOD_FAIL $(basename "$f")"
done
[ -z "$DOGFOOD_FAIL" ] && ok "T12 dogfood : briques mobile-test-team conformes au linter livré" || ko "T12 briques livrées flaguées :$DOGFOOD_FAIL"

echo ""
echo "== Résultat : $pass OK · $fail KO =="
[ "$fail" -eq 0 ]
