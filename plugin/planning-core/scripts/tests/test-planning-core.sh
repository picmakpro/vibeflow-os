#!/usr/bin/env bash
# test-planning-core.sh — Tests du moteur léger (check-planning-state.sh).
# Portable, sans réseau. Crée des fixtures temporaires et vérifie les exit codes.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CHECK="$SCRIPT_DIR/check-planning-state.sh"
PASS=0; FAIL=0

check_exit() { # <description> <expected_code> <actual_code>
  if [ "$2" -eq "$3" ]; then echo "  ✓ $1 (exit $3)"; PASS=$((PASS+1));
  else echo "  ✗ $1 — attendu $2, obtenu $3"; FAIL=$((FAIL+1)); fi
}

# Date portable BSD/GNU pour fabriquer un last_updated frais ou périmé.
days_ago() { date -v-"$1"d +%Y-%m-%d 2>/dev/null || date -d "-$1 days" +%Y-%m-%d 2>/dev/null; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

echo "== test-planning-core =="

# Cas 1 : .planning absent → exit 3
( cd "$TMP" && bash "$CHECK" --quiet ); check_exit ".planning absent" 3 $?

# Cas 2 : .planning présent, STATE absent → exit 2
mkdir -p "$TMP/.planning"
( cd "$TMP" && bash "$CHECK" --quiet ); check_exit "STATE.md absent" 2 $?

# Cas 3 : STATE frais (aujourd'hui) → exit 0
printf -- '---\nlast_updated: "%s"\n---\n' "$(days_ago 0)" > "$TMP/.planning/STATE.md"
( cd "$TMP" && bash "$CHECK" --quiet ); check_exit "STATE frais" 0 $?

# Cas 4 : STATE périmé (20j, seuil 7) → exit 1
printf -- '---\nlast_updated: "%s"\n---\n' "$(days_ago 20)" > "$TMP/.planning/STATE.md"
( cd "$TMP" && bash "$CHECK" --quiet ); check_exit "STATE périmé (20j)" 1 $?

# Cas 5 : STATE sans last_updated → exit 1
printf -- '---\nstatus: "en cours"\n---\n' > "$TMP/.planning/STATE.md"
( cd "$TMP" && bash "$CHECK" --quiet ); check_exit "STATE sans last_updated" 1 $?

# Cas 6 : seuil custom — 20j avec --max-age-days 30 → frais → exit 0
printf -- '---\nlast_updated: "%s"\n---\n' "$(days_ago 20)" > "$TMP/.planning/STATE.md"
( cd "$TMP" && bash "$CHECK" --quiet --max-age-days 30 ); check_exit "seuil custom 30j" 0 $?

# --- Durcissement PLN-06 : dates non paddées (2026-7-5) — l'ancien sed laissait passer
# la ligne entière → message confus « Impossible de parser last_updated='last_updated: … » ---
has()  { echo "$1" | grep -q "$2" && { echo "  ✓ $3"; PASS=$((PASS+1)); } || { echo "  ✗ $3 — sortie : $1"; FAIL=$((FAIL+1)); }; }
hasnt(){ echo "$1" | grep -q "$2" && { echo "  ✗ $3 — sortie : $1"; FAIL=$((FAIL+1)); } || { echo "  ✓ $3"; PASS=$((PASS+1)); }; }
unpad() { echo "$1" | sed -E 's/-0([0-9])/-\1/g'; }   # 2026-07-05 → 2026-7-5

# Cas 7 : date non paddée FRAÎCHE (aujourd'hui) → parsée correctement → exit 0
printf -- '---\nlast_updated: %s\n---\n' "$(unpad "$(days_ago 0)")" > "$TMP/.planning/STATE.md"
( cd "$TMP" && bash "$CHECK" --quiet ); check_exit "date non paddée fraîche" 0 $?

# Cas 8 : date non paddée ANCIENNE (2026-1-5) → périmé (exit 1), message avec la date NORMALISÉE
printf -- '---\nlast_updated: 2026-1-5\n---\n' > "$TMP/.planning/STATE.md"
out=$( cd "$TMP" && bash "$CHECK" ); code=$?
check_exit "date non paddée ancienne → périmé" 1 $code
has   "$out" "périmé"      "cas 8 : message périmé (pas la branche parse-error)"
has   "$out" "2026-01-05"  "cas 8 : date normalisée YYYY-MM-DD dans le message"
hasnt "$out" "Impossible de parser" "cas 8 : aucun message de parse confus"

# Cas 9 : valeur en forme mais invalide (2026-13-99) → exit 1, message avec la SEULE valeur
printf -- '---\nlast_updated: 2026-13-99\n---\n' > "$TMP/.planning/STATE.md"
out=$( cd "$TMP" && bash "$CHECK" ); code=$?
check_exit "date invalide (2026-13-99)" 1 $code
has   "$out" "last_updated='2026-13-99'"    "cas 9 : le message cite la seule valeur extraite"
hasnt "$out" "last_updated='last_updated:"  "cas 9 : la ligne entière n'est plus recrachée"

echo "== résultat : $PASS passés, $FAIL échoués =="
[ "$FAIL" -eq 0 ]
