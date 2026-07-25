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

echo ""
echo "== résultat : $PASS ok, $FAIL ko =="
[ "$FAIL" -eq 0 ]
