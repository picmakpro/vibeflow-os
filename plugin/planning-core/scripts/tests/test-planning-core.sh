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

echo "== résultat : $PASS passés, $FAIL échoués =="
[ "$FAIL" -eq 0 ]
