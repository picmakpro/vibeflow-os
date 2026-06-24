#!/usr/bin/env bash
# test-proportion-capabilities.sh — Tests du plafond de capacités (déterministe, sans réseau).
set -uo pipefail

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/proportion-capabilities.sh"
PASS=0; FAIL=0

check_exit() { # <desc> <expected> <actual>
  if [ "$2" -eq "$3" ]; then echo "  ✓ $1 (exit $3)"; PASS=$((PASS+1));
  else echo "  ✗ $1 — attendu $2, obtenu $3"; FAIL=$((FAIL+1)); fi
}
check_out() { # <desc> <expected_substr> <actual>
  case "$3" in *"$2"*) echo "  ✓ $1"; PASS=$((PASS+1)) ;; *) echo "  ✗ $1 — '$2' absent de '$3'"; FAIL=$((FAIL+1)) ;; esac
}

echo "== test-proportion-capabilities =="

# Plafonds par profil
out=$(bash "$SCRIPT" --profile leger);    check_out "léger = 1 3" "1 3" "$out"
out=$(bash "$SCRIPT" --profile standard); check_out "standard = 4 8" "4 8" "$out"
out=$(bash "$SCRIPT" --profile complet);  check_out "complet = 9 20" "9 20" "$out"

# Profil invalide → exit 64
bash "$SCRIPT" --profile foo >/dev/null 2>&1; check_exit "profil invalide" 64 $?

# count dans le plafond → exit 0
bash "$SCRIPT" --profile standard --count 6 >/dev/null 2>&1; check_exit "count 6 ≤ standard(8)" 0 $?
# count au-dessus → exit 1
bash "$SCRIPT" --profile standard --count 12 >/dev/null 2>&1; check_exit "count 12 > standard(8)" 1 $?
out=$(bash "$SCRIPT" --profile standard --count 12 2>/dev/null); check_out "message AU-DESSUS" "AU-DESSUS" "$out"
# count non entier → exit 64
bash "$SCRIPT" --profile leger --count abc >/dev/null 2>&1; check_exit "count non entier" 64 $?
# count limite (=max) → OK
bash "$SCRIPT" --profile complet --count 20 >/dev/null 2>&1; check_exit "count 20 = complet(20)" 0 $?

echo "== résultat : $PASS passés, $FAIL échoués =="
[ "$FAIL" -eq 0 ]
