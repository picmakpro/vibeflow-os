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

# --- Durcissement PLN-01 : les dossiers vendorés sont ÉLAGUÉS (volume, activité, latence) ---
# timeout portable : macOS n'a pas timeout(1) de base → repli perl (le timer alarm survit à exec).
with_timeout() { # <secondes> <cmd...>
  if command -v timeout >/dev/null 2>&1; then timeout "$@"; else perl -e 'alarm shift; exec @ARGV' "$@"; fi
}

# Cas 8 : volume UNIQUEMENT vendoré (node_modules + .venv) → non compté → pas de dette → exit 0
rm -rf "$TMP/projects"; make_compartment "$TMP/projects/appli" 2   # 2 fichiers utilisateur < seuil 5
mkdir -p "$TMP/projects/appli/node_modules/pkg" "$TMP/projects/appli/.venv/lib"
( cd "$TMP/projects/appli/node_modules/pkg" && printf 'dep%s.js ' $(seq 1 200) | xargs touch )
( cd "$TMP/projects/appli/.venv/lib" && printf 'mod%s.py ' $(seq 1 50) | xargs touch )
( cd "$TMP" && bash "$DETECT" --quiet ); check_exit "volume vendoré non compté (node_modules/.venv)" 0 $?

# Cas 9 : fichiers utilisateur ANCIENS + node_modules FRAIS (npm install récent) → pas actif → exit 0
rm -rf "$TMP/projects"; make_compartment "$TMP/projects/dormant" 8
find "$TMP/projects/dormant" -type f -exec touch -t "$(old_ts)" {} +
mkdir -p "$TMP/projects/dormant/node_modules"
( cd "$TMP/projects/dormant/node_modules" && printf 'dep%s.js ' $(seq 1 20) | xargs touch )   # mtime = maintenant
( cd "$TMP" && bash "$DETECT" --quiet ); check_exit "npm install récent ≠ activité (prune)" 0 $?

# Cas 10 : latence — gros node_modules (3000 fichiers) : le scan reste quasi instantané ET la
# dette réelle est bien détectée (avant fix : 1 stat spawné PAR fichier → gel du SessionStart).
rm -rf "$TMP/projects"; make_compartment "$TMP/projects/lourd" 8
mkdir -p "$TMP/projects/lourd/node_modules/deps"
( cd "$TMP/projects/lourd/node_modules/deps" && printf 'f%s ' $(seq 1 3000) | xargs touch )
( cd "$TMP" && with_timeout 10 bash "$DETECT" --quiet ); check_exit "3000 fichiers vendorés scannés sans gel (dette réelle détectée)" 1 $?

echo "== résultat : $PASS passés, $FAIL échoués =="
[ "$FAIL" -eq 0 ]
