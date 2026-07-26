#!/usr/bin/env bash
# test-detect-gsd-engine.sh — Tests du détecteur de moteur de planning GSD.
# Portable, sans réseau. Fixtures temporaires + vérification des exit codes.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DETECT="$SCRIPT_DIR/detect-gsd-engine.sh"
PASS=0; FAIL=0

check_exit() { # <description> <expected_code> <actual_code>
  if [ "$2" -eq "$3" ]; then echo "  ✓ $1 (exit $3)"; PASS=$((PASS+1));
  else echo "  ✗ $1 — attendu $2, obtenu $3"; FAIL=$((FAIL+1)); fi
}

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# Faux GSD_HOME présent (le script ne teste que l'existence du dossier).
FAKE_GSD="$TMP/gsd-home"; mkdir -p "$FAKE_GSD"
ABSENT_GSD="$TMP/nulle-part"

mk_state() { # <dir> <première_clé_frontmatter>
  mkdir -p "$1/.planning"
  printf -- '---\n%s: 1.0\nlast_updated: "2026-07-25"\n---\n\n# État\n' "$2" > "$1/.planning/STATE.md"
}

echo "== test-detect-gsd-engine =="

# Cas 1 : chaîne GSD absente → exit 1, priorité maximale (même avec un STATE GSD parfait).
LAB="$TMP/lab1"; mk_state "$LAB" "gsd_state_version"
( cd "$LAB" && GSD_HOME="$ABSENT_GSD" bash "$DETECT" --quiet ); check_exit "chaîne GSD absente" 1 $?

# Cas 2 : moteur GSD actif (STATE porte gsd_state_version) → exit 0.
LAB="$TMP/lab2"; mk_state "$LAB" "gsd_state_version"
( cd "$LAB" && GSD_HOME="$FAKE_GSD" bash "$DETECT" --quiet ); check_exit "moteur GSD actif" 0 $?

# Cas 3 : format planning-core + signal de code → signalement de migration → exit 2.
LAB="$TMP/lab3"; mk_state "$LAB" "planning_version"; echo '{}' > "$LAB/package.json"
( cd "$LAB" && GSD_HOME="$FAKE_GSD" bash "$DETECT" --quiet ); check_exit "migration à examiner" 2 $?

# Cas 4 : format planning-core SANS aucun signal de code (lab non-dev) → terrain libre → exit 3.
LAB="$TMP/lab4"; mk_state "$LAB" "planning_version"
( cd "$LAB" && GSD_HOME="$FAKE_GSD" bash "$DETECT" --quiet ); check_exit "lab non-dev, terrain libre" 3 $?

# Cas 5 : aucun .planning/ → terrain libre → exit 3.
LAB="$TMP/lab5"; mkdir -p "$LAB"
( cd "$LAB" && GSD_HOME="$FAKE_GSD" bash "$DETECT" --quiet ); check_exit "pas de .planning/" 3 $?

# Cas 6 : .planning/ présent mais STATE.md absent → terrain libre → exit 3.
LAB="$TMP/lab6"; mkdir -p "$LAB/.planning"
( cd "$LAB" && GSD_HOME="$FAKE_GSD" bash "$DETECT" --quiet ); check_exit "STATE.md absent" 3 $?

# Cas 7 : le marqueur GSD prime sur les signaux de code (projet dev déjà sous GSD) → exit 0.
LAB="$TMP/lab7"; mk_state "$LAB" "gsd_state_version"; echo '{}' > "$LAB/package.json"
( cd "$LAB" && GSD_HOME="$FAKE_GSD" bash "$DETECT" --quiet ); check_exit "marqueur GSD prime sur le code" 0 $?

# Cas 8 : --path explicite (socle hors du cwd).
LAB="$TMP/lab8"; mk_state "$LAB" "gsd_state_version"
( cd "$TMP" && GSD_HOME="$FAKE_GSD" bash "$DETECT" --quiet --path "$LAB/.planning" ); check_exit "--path explicite" 0 $?

# Cas 9 : argument inconnu → exit 64 (convention des scripts frères).
( cd "$TMP" && GSD_HOME="$FAKE_GSD" bash "$DETECT" --nawak 2>/dev/null ); check_exit "argument inconnu" 64 $?

# Cas 10 : signal de code alternatif (go.mod) reconnu comme les autres.
LAB="$TMP/lab10"; mk_state "$LAB" "planning_version"; echo 'module x' > "$LAB/go.mod"
( cd "$LAB" && GSD_HOME="$FAKE_GSD" bash "$DETECT" --quiet ); check_exit "signal de code go.mod" 2 $?

# --- Cas 11-12 : le marqueur est une clé du FRONTMATTER, pas une chaîne du fichier (M1) ---
# Un grep non borné prendrait un `gsd_state_version:` cité dans le corps pour le marqueur réel et
# sortirait 0 « moteur actif » sur un socle planning-core — les deux hooks qui câblent ce script en
# `&& exit 0` se retireraient alors à tort.

# Cas 11 : socle planning-core citant gsd_state_version en colonne 1 DANS LE CORPS + code → 2, pas 0.
LAB="$TMP/lab11"; mkdir -p "$LAB/.planning"
{
  printf -- '---\nplanning_version: 1.0\nlast_updated: "2026-07-25"\n---\n\n'
  printf '# État\n\nFormat attendu par l'"'"'outillage de dev :\n\n```yaml\n'
  printf 'gsd_state_version: 1.0\n```\n'
} > "$LAB/.planning/STATE.md"
echo '{}' > "$LAB/package.json"
( cd "$LAB" && GSD_HOME="$FAKE_GSD" bash "$DETECT" --quiet ); check_exit "marqueur GSD hors frontmatter ignoré" 2 $?

# Cas 12 : symétrique — planning_version cité hors frontmatter n'est pas non plus un marqueur.
LAB="$TMP/lab12"; mkdir -p "$LAB/.planning"
{
  printf -- '---\ngsd_state_version: 1.0\n---\n\n# État\n\nAncien format :\n\n'
  printf 'planning_version: 1.0\n'
} > "$LAB/.planning/STATE.md"
( cd "$LAB" && GSD_HOME="$FAKE_GSD" bash "$DETECT" --quiet ); check_exit "frontmatter GSD prime sur mention en corps" 0 $?

# --- Cas 13-19 : dual-layout GSD_HOME (D-01, amendement D1) — GSD_HOME NON fourni, résolution
# par défaut testée. mk_state pose un STATE.md GSD-actif (gsd_state_version) pour que « exit 0 »
# soit la preuve indirecte que le dossier attendu a bien été trouvé par la cascade.

# Cas 13 : $HOME redirigé, seul .claude/gsd-core/ présent (pas de get-shit-done/) → gsd-core trouvé.
LAB="$TMP/lab13"; mk_state "$LAB" "gsd_state_version"
FAKE_HOME13="$TMP/home13"; mkdir -p "$FAKE_HOME13/.claude/gsd-core"
( cd "$LAB" && env -u GSD_HOME HOME="$FAKE_HOME13" bash "$DETECT" --quiet ); check_exit "cas 13 : gsd-core seul sous \$HOME → trouvé" 0 $?

# Cas 14 : $HOME redirigé, seul .claude/get-shit-done/ présent (layout legacy pur) → trouvé (repli).
LAB="$TMP/lab14"; mk_state "$LAB" "gsd_state_version"
FAKE_HOME14="$TMP/home14"; mkdir -p "$FAKE_HOME14/.claude/get-shit-done"
( cd "$LAB" && env -u GSD_HOME HOME="$FAKE_HOME14" bash "$DETECT" --quiet ); check_exit "cas 14 : legacy seul sous \$HOME → trouvé (repli)" 0 $?

# Cas 15 : $HOME redirigé, aucun des deux dossiers → chaîne GSD absente → exit 1.
LAB="$TMP/lab15"; mk_state "$LAB" "gsd_state_version"
FAKE_HOME15="$TMP/home15"; mkdir -p "$FAKE_HOME15"
( cd "$LAB" && env -u GSD_HOME HOME="$FAKE_HOME15" bash "$DETECT" --quiet ); check_exit "cas 15 : rien sous \$HOME → absent" 1 $?

# Cas 16 : les deux dossiers présents sous $HOME → gsd-core gagne (priorité explicite).
LAB="$TMP/lab16"; mk_state "$LAB" "gsd_state_version"
FAKE_HOME16="$TMP/home16"; mkdir -p "$FAKE_HOME16/.claude/gsd-core" "$FAKE_HOME16/.claude/get-shit-done"
( cd "$LAB" && env -u GSD_HOME HOME="$FAKE_HOME16" bash "$DETECT" --quiet ); check_exit "cas 16 : gsd-core prime sur legacy sous \$HOME" 0 $?

# Cas 17 (DISCRIMINANT — D1) : $HOME vide, payload posé à l'échelle PROJET (cwd), pas sous $HOME.
# Doit échouer avec une implémentation qui ne teste que $HOME.
LAB="$TMP/lab17"; mk_state "$LAB" "gsd_state_version"
mkdir -p "$LAB/.claude/gsd-core"
FAKE_HOME17="$TMP/home17"; mkdir -p "$FAKE_HOME17"
( cd "$LAB" && env -u GSD_HOME HOME="$FAKE_HOME17" bash "$DETECT" --quiet ); check_exit "cas 17 (DISCRIMINANT) : gsd-core projet-local trouvé, \$HOME vide" 0 $?

# Cas 18 : les deux présents (projet-local ET \$HOME/.claude/gsd-core) → projet-local gagne.
LAB="$TMP/lab18"; mk_state "$LAB" "gsd_state_version"
mkdir -p "$LAB/.claude/gsd-core"
FAKE_HOME18="$TMP/home18"; mkdir -p "$FAKE_HOME18/.claude/gsd-core"
( cd "$LAB" && env -u GSD_HOME HOME="$FAKE_HOME18" bash "$DETECT" --quiet ); check_exit "cas 18 : projet-local prime sur \$HOME" 0 $?

# Cas 19 : CLAUDE_CONFIG_DIR distinct de \$HOME/.claude, aucun payload projet-local → résolu via
# CLAUDE_CONFIG_DIR (preuve que la variable est honorée, pas seulement \$HOME/.claude en dur).
LAB="$TMP/lab19"; mk_state "$LAB" "gsd_state_version"
FAKE_HOME19="$TMP/home19"; mkdir -p "$FAKE_HOME19/.claude"
FAKE_CCD19="$TMP/ccd19"; mkdir -p "$FAKE_CCD19/gsd-core"
( cd "$LAB" && env -u GSD_HOME HOME="$FAKE_HOME19" CLAUDE_CONFIG_DIR="$FAKE_CCD19" bash "$DETECT" --quiet ); check_exit "cas 19 : résolution via CLAUDE_CONFIG_DIR" 0 $?

echo ""
echo "== résultat : $PASS ok, $FAIL ko =="
[ "$FAIL" -eq 0 ]
