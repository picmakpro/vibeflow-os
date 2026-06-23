#!/usr/bin/env bash
# test-detect-planning-debt.sh — Tests du détecteur de dette de planning (v2).
# Portable, sans réseau. Crée des fixtures temporaires et vérifie les exit codes.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DETECT="$SCRIPT_DIR/detect-planning-debt.sh"
PASS=0; FAIL=0

check_exit() { # <description> <expected_code> <actual_code>
  if [ "$2" -eq "$3" ]; then echo "  ✓ $1 (exit $3)"; PASS=$((PASS+1));
  else echo "  ✗ $1 — attendu $2, obtenu $3"; FAIL=$((FAIL+1)); fi
}

# Crée un compartiment avec N fichiers (volume).
make_compartment() { # <dir> <nb_files>
  mkdir -p "$1"
  for i in $(seq 1 "$2"); do echo "contenu $i" > "$1/f$i.md"; done
}

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

echo "== test-detect-planning-debt =="

# Cas 1 : racine projects/ absente → exit 3
( cd "$TMP" && bash "$DETECT" --quiet ); check_exit "racine absente" 3 $?

# Cas 2 : compartiment volumineux, actif, SANS plan → dette → exit 1
make_compartment "$TMP/projects/formation" 8
( cd "$TMP" && bash "$DETECT" --quiet ); check_exit "compartiment actif sans plan" 1 $?

# Cas 3 : même compartiment MAIS avec un STATE.md → plus de dette → exit 0
echo "state" > "$TMP/projects/formation/STATE.md"
( cd "$TMP" && bash "$DETECT" --quiet ); check_exit "plan présent (STATE.md)" 0 $?

# Cas 4 : plan sous forme de .planning/ → pas de dette → exit 0
rm -f "$TMP/projects/formation/STATE.md"; mkdir -p "$TMP/projects/formation/.planning"
( cd "$TMP" && bash "$DETECT" --quiet ); check_exit "plan présent (.planning/)" 0 $?

# Cas 5 : compartiment sous le seuil de volume (2 fichiers < 5) → pas de dette → exit 0
rm -rf "$TMP/projects"; make_compartment "$TMP/projects/petit" 2
( cd "$TMP" && bash "$DETECT" --quiet ); check_exit "sous le seuil (volume)" 0 $?

# Cas 6 : seuil custom --min-tasks 2 → le petit compartiment devient en dette → exit 1
( cd "$TMP" && bash "$DETECT" --quiet --min-tasks 2 ); check_exit "seuil custom min-tasks=2" 1 $?

# Cas 7 : compartiment volumineux mais INACTIF (fenêtre courte) → pas de dette → exit 0
rm -rf "$TMP/projects"; make_compartment "$TMP/projects/vieux" 8
# rendre les fichiers anciens : touch à une date passée (portable BSD/GNU)
old_ts() { date -v-40d +%Y%m%d0000 2>/dev/null || date -d "-40 days" +%Y%m%d0000 2>/dev/null; }
find "$TMP/projects/vieux" -type f -exec touch -t "$(old_ts)" {} +
( cd "$TMP" && bash "$DETECT" --quiet --active-window 14 ); check_exit "inactif (hors fenêtre)" 0 $?

echo "== résultat : $PASS passés, $FAIL échoués =="
[ "$FAIL" -eq 0 ]
