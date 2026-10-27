#!/usr/bin/env bash
# test-product-team-bundle.sh — Suite de composition du module product-team-bundle (Phase 59,
# P59-D-18, P59-PL-06). Distincte de test-check-prd.sh (qui prouve le script par mutants) : cette
# suite prouve que le bundle est bien composé et que chaque garde peut rougir.
#
# Règle de la suite (preuve incapable de rougir = preuve nulle) : chaque contrôle est une fonction
# qui prend la RACINE d'un module en argument, imprime ses motifs de rouge (KO-<CAS>:<détail>) et
# rend 0 ou 1. Il est joué sur le module réel (témoin positif) ET sur une COPIE MUTÉE, qui doit
# rougir avec le motif attendu, pas seulement avec un code non nul. Copie identique = NON OPPOSABLE.
#
#   PTB-COMPO    — fichiers du module, frontmatters (description/model/memory), noms
#   PTB-MODULE   — module.json : version=VERSION, proposable:false, roles, requires
#   PTB-LIGNES   — corpus <= 250 lignes, skill <= 500
#   PTB-MUT-*    — mutants des cas ci-dessus (un par garde)
# <!-- gsd:suite-cases -->
#
# Convention : helpers ok()/ko()/skip(), exit 1 si au moins un KO (SKIP non bloquant).
# Portabilité : bash 3.2, awk POSIX (mawk), aucun chemin de machine ; les copies vivent sous $TMP.

set -uo pipefail

MOD="$(cd "$(dirname "$0")/../.." && pwd)"
REPO="$(cd "$MOD/.." && pwd)"

pass=0; fail=0; skipped=0
ok()   { echo "  ✓ $1"; pass=$((pass+1)); }
ko()   { echo "  ✗ $1"; fail=$((fail+1)); }
skip() { echo "  ⊘ SKIP $1"; skipped=$((skipped+1)); }

# grep insensible aux alias (ugrep) : binaire système.
GREP="$(command -v grep)"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
TMPW="$TMP/w.out"

AGENTS="vf-product-manager vf-product-analyst vf-product-pm prd-gate"
CORPUS="AGENT.md agents/vf-product-manager.md agents/vf-product-analyst.md agents/vf-product-pm.md agents/prd-gate.md"

echo "== test-product-team-bundle (module: $MOD) =="

# ---------------------------------------------------------------------------
# Outils de mutation (aucune écriture hors de $TMP)
# ---------------------------------------------------------------------------
has() { "$GREP" -qF -- "$2" "$1"; }                       # fichier, motif fixe
need() { has "$2" "$4" || { echo "KO-$1:$3"; return 1; }; return 0; }   # CAS fichier id motif

# subst <fichier> <ancien> <nouveau> : remplace TOUTES les occurrences (texte fixe, pas de regex).
subst() {
  OLD="$2" NEW="$3" awk '{
    o = ENVIRON["OLD"]; n = ENVIRON["NEW"]; out = ""; s = $0
    while ((i = index(s, o)) > 0) { out = out substr(s, 1, i - 1) n; s = substr(s, i + length(o)) }
    print out s }' "$1" > "$TMPW" && cp "$TMPW" "$1"
}
# dropline <fichier> <préfixe> : supprime les lignes qui COMMENCENT par ce texte fixe.
dropline() {
  PFX="$2" awk '{ p = ENVIRON["PFX"]; if (substr($0, 1, length(p)) != p) print }' "$1" > "$TMPW" && cp "$TMPW" "$1"
}
# mkmut <étiquette> : copie du module sous $TMP, imprime le chemin.
mkmut() { rm -rf "$TMP/m.$1"; cp -R "$MOD" "$TMP/m.$1" && echo "$TMP/m.$1"; }

LAST_OUT=""
run_ctl() { LAST_OUT="$("$1" "$2" 2>&1)"; return $?; }
brief() { printf '%s' "$LAST_OUT" | tr '\n' ' ' | cut -c1-220; }

# case_ctl <étiquette> <contrôle> <racine> : cas direct, vert attendu.
case_ctl() {
  if run_ctl "$2" "$3"; then ok "$1"; else ko "$1 — $(brief)"; fi
}

# mutant_ptb <étiquette> <motif> <contrôle> <original> <copie mutée>
# Exige : (1) contrôle vert sur l'original, (2) copie différente, (3) contrôle rouge sur la copie,
# (4) la sortie contient le motif attendu.
mutant_ptb() {
  local label="$1" pat="$2" ctl="$3" orig="$4" mut="$5"
  if ! run_ctl "$ctl" "$orig"; then ko "PTB-MUT-$label témoin positif rouge sur l'original — $(brief)"; return; fi
  if diff -rq "$orig" "$mut" >/dev/null 2>&1; then ko "PTB-MUT-$label NON OPPOSABLE (copie identique à l'original)"; return; fi
  if run_ctl "$ctl" "$mut"; then ko "PTB-MUT-$label SURVIVANT : contrôle vert sur la copie mutée"; return; fi
  if printf '%s' "$LAST_OUT" | "$GREP" -qF -- "$pat"; then
    ok "PTB-MUT-$label rouge attendu (« $pat »)"
  else
    ko "PTB-MUT-$label rouge pour une autre raison (attendu « $pat ») — $(brief)"
  fi
}

# ---------------------------------------------------------------------------
# Contrôles (argument : racine d'un module)
# ---------------------------------------------------------------------------
ctl_compo() {
  local r=0 f a field
  for f in $CORPUS skills/vf-product/SKILL.md references/BRIEF.template.md scripts/check-prd.sh; do
    [ -f "$1/$f" ] || { echo "KO-COMPO:absent $f"; r=1; }
  done
  "$GREP" -q '^name: vibeflow-product$' "$1/AGENT.md" 2>/dev/null || { echo "KO-COMPO:name AGENT.md"; r=1; }
  for a in $AGENTS; do
    for field in description model memory; do
      "$GREP" -q "^${field}:" "$1/agents/$a.md" 2>/dev/null || { echo "KO-COMPO:$a sans $field"; r=1; }
    done
    "$GREP" -q "^name: $a\$" "$1/agents/$a.md" 2>/dev/null || { echo "KO-COMPO:$a name != nom de fichier"; r=1; }
  done
  "$GREP" -q '^name: vf-product$' "$1/skills/vf-product/SKILL.md" 2>/dev/null || { echo "KO-COMPO:name skill"; r=1; }
  "$GREP" -q '^vf-invocation: model$' "$1/skills/vf-product/SKILL.md" 2>/dev/null || { echo "KO-COMPO:vf-invocation skill"; r=1; }
  return $r
}

ctl_module() {
  local r=0 j="$1/module.json" ver vf req
  [ -f "$j" ] && [ -f "$1/VERSION" ] || { echo "KO-MODULE:module.json ou VERSION absent"; return 1; }
  ver="$(jq -r '.version' "$j")"; vf="$(tr -d '[:space:]' < "$1/VERSION")"
  # Triade module.json <-> VERSION ; la valeur v1.0.0 est celle de la naissance (CHANGELOG), pas une case
  # permanente : un bump normal ne doit pas rougir cette suite.
  { [ "$ver" = "$vf" ] && printf '%s' "$vf" | "$GREP" -qE '^v[0-9]+\.[0-9]+\.[0-9]+$'; } || { echo "KO-MODULE:version module.json=$ver VERSION=$vf"; r=1; }
  [ "$(jq -r '.proposable' "$j")" = "false" ] || { echo "KO-MODULE:proposable != false"; r=1; }
  [ "$(jq -c '.roles' "$j")" = '["product"]' ] || { echo "KO-MODULE:roles = $(jq -c '.roles' "$j")"; r=1; }
  req="$(jq -r '(.requires // []) | sort | join(",")' "$j")"
  [ "$req" = "audit-architecture,conductor,consolidator,planning-core,software-architecture" ] || { echo "KO-MODULE:requires = $req"; r=1; }
  return $r
}

ctl_lignes() {
  local r=0 f n
  for f in $CORPUS; do
    [ -f "$1/$f" ] || { echo "KO-LIGNES:absent $f"; r=1; continue; }
    n="$(wc -l < "$1/$f" | tr -d ' ')"
    [ "${n:-999}" -le 250 ] || { echo "KO-LIGNES:$f $n >250"; r=1; }
  done
  f="skills/vf-product/SKILL.md"
  [ -f "$1/$f" ] || { echo "KO-LIGNES:absent $f"; return 1; }
  n="$(wc -l < "$1/$f" | tr -d ' ')"
  [ "${n:-999}" -le 500 ] || { echo "KO-LIGNES:$f $n >500"; r=1; }
  return $r
}

# ---------------------------------------------------------------------------
# PTB-COMPO / PTB-MODULE / PTB-LIGNES — cas directs puis mutants
# ---------------------------------------------------------------------------
case_ctl "PTB-COMPO : fichiers, frontmatters (description/model/memory) et noms du module" ctl_compo "$MOD"
case_ctl "PTB-MODULE : version=VERSION, proposable:false, roles=[product], requires fermé" ctl_module "$MOD"
case_ctl "PTB-LIGNES : corpus <= 250 lignes, skill <= 500 (P59-D-12)" ctl_lignes "$MOD"

M="$(mkmut compo)"; dropline "$M/agents/vf-product-analyst.md" "memory:"
mutant_ptb COMPO-MEMORY "KO-COMPO:vf-product-analyst sans memory" ctl_compo "$MOD" "$M"

M="$(mkmut proposable)"; jq '.proposable = true' "$M/module.json" > "$TMPW" && cp "$TMPW" "$M/module.json"
mutant_ptb MODULE-PROPOSABLE "KO-MODULE:proposable" ctl_module "$MOD" "$M"

M="$(mkmut roles)"; jq 'del(.roles)' "$M/module.json" > "$TMPW" && cp "$TMPW" "$M/module.json"
mutant_ptb MODULE-ROLES "KO-MODULE:roles" ctl_module "$MOD" "$M"

M="$(mkmut requires)"; jq '.requires += ["design-orchestrator"]' "$M/module.json" > "$TMPW" && cp "$TMPW" "$M/module.json"
mutant_ptb MODULE-REQUIRES "KO-MODULE:requires" ctl_module "$MOD" "$M"

M="$(mkmut lignes)"
n="$(wc -l < "$M/agents/prd-gate.md" | tr -d ' ')"
awk -v k="$((251 - n))" '{ print } END { for (i = 0; i < k; i++) print "<!-- mutant -->" }' "$M/agents/prd-gate.md" > "$TMPW" && cp "$TMPW" "$M/agents/prd-gate.md"
mutant_ptb LIGNES-251 "KO-LIGNES:agents/prd-gate.md 251 >250" ctl_lignes "$MOD" "$M"

echo "== résultat : $pass OK / $fail KO / $skipped SKIP =="
[ "$fail" -eq 0 ]
