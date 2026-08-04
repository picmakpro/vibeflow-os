#!/usr/bin/env bash
# test-driver-lock.sh — Suite de tests pour driver-lock.sh (ADR-053, Pattern A)
#
# T1 acquisition franche · T2 double-acquisition refusée · T3 ré-acquisition idempotente (reentrant)
# T4 heartbeat préserve le step · T5 release owner mismatch refusé · T6 release owner correct
# T7 récupération de claim périmé (heartbeat antidaté > TTL) · T8 recover sur lock frais refusé
# T9 status présent/absent · T10 heartbeat sans lock → erreur
#
# Exit 0 si tout passe, 1 sinon.

set -uo pipefail
cd "$(dirname "$0")/../.."
SCRIPT="$(pwd)/scripts/driver-lock.sh"

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT
export VF_DRIVER_LOCK="$WORK_DIR/DRIVER.lock"

PASS=0; FAIL=0
assert()     { if [[ "$2" == *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: $3"; echo "     obtenu:  $2"; FAIL=$((FAIL+1)); fi; }
assert_exit(){ if [ "$2" -eq "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1 (exit $2 ≠ $3)"; FAIL=$((FAIL+1)); fi; }

# Antidate un lock existant AU-DELÀ du TTL, sans présumer de sa forme interne. Les tests exigent
# un lock périmé ; ils n'ont pas à savoir COMMENT l'âge est stocké. Un test qui édite le meta à la
# main est un test qui casse au premier changement de protocole — et qui, pire, peut se mettre à
# mesurer autre chose sans rougir.
age_stale() {
  local lock="$1" old; old=$(( $(date +%s) - 999999 ))
  if [ -L "$lock" ]; then                      # forme lien : l'âge vit dans la cible du lien
    local gen; gen="$(readlink "$lock")"
    [ -f "$lock/meta" ] && sed -i.bak "s/^heartbeat_epoch=.*/heartbeat_epoch=$old/" "$lock/meta" 2>/dev/null
    rm -f "$lock/meta.bak" 2>/dev/null
    touch -t 202001010000 "$(dirname "$lock")/$gen" 2>/dev/null || true
  elif [ -f "$lock/meta" ]; then               # forme dossier+meta
    sed -i.bak "s/^heartbeat_epoch=.*/heartbeat_epoch=$old/" "$lock/meta" && rm -f "$lock/meta.bak"
  else
    touch -t 202001010000 "$lock" 2>/dev/null || true
  fi
}

echo "=== T1 — acquisition franche ==="
out=$("$SCRIPT" acquire --owner=A --step=phase-9); rc=$?
assert "T1.1 — acquired true" "$out" '"acquired": true'
assert_exit "T1.2 — exit 0" "$rc" 0

echo "=== T2 — double-acquisition (autre owner) refusée ==="
out=$("$SCRIPT" acquire --owner=B --step=phase-9); rc=$?
assert "T2.1 — acquired false" "$out" '"acquired": false'
assert "T2.2 — held_by A" "$out" '"held_by": "A"'
assert_exit "T2.3 — exit 1 (refus)" "$rc" 1

echo "=== T3 — ré-acquisition idempotente (même owner) ==="
out=$("$SCRIPT" acquire --owner=A --step=phase-10)
assert "T3.1 — reentrant true" "$out" '"reentrant": true'
assert "T3.2 — step mis à jour" "$("$SCRIPT" status)" '"step": "phase-10"'

echo "=== T4 — heartbeat préserve le step ==="
"$SCRIPT" heartbeat --owner=A >/dev/null
assert "T4.1 — step préservé après heartbeat" "$("$SCRIPT" status)" '"step": "phase-10"'

echo "=== T5 — release owner mismatch refusé ==="
out=$("$SCRIPT" release --owner=B); rc=$?
assert "T5.1 — released false not-owner" "$out" '"reason": "not-owner"'
assert_exit "T5.2 — exit 1" "$rc" 1

echo "=== T6 — release owner correct ==="
out=$("$SCRIPT" release --owner=A)
assert "T6.1 — released true" "$out" '"released": true'
assert "T6.2 — lock absent après release" "$("$SCRIPT" status)" '"present": false'

echo "=== T7 — récupération de claim périmé (heartbeat antidaté) ==="
"$SCRIPT" acquire --owner=DEAD --step=x >/dev/null
# antidate le heartbeat bien au-delà du TTL par défaut (1800 s)
age_stale "$VF_DRIVER_LOCK"
out=$("$SCRIPT" acquire --owner=B --step=y); rc=$?
assert "T7.1 — recovered true" "$out" '"recovered": true'
assert "T7.2 — previous_owner DEAD" "$out" '"previous_owner": "DEAD"'
assert "T7.3 — nouvel owner B" "$("$SCRIPT" status)" '"owner": "B"'
assert_exit "T7.4 — exit 0" "$rc" 0

echo "=== T8 — recover sur lock frais refusé ==="
out=$("$SCRIPT" recover); rc=$?
assert "T8.1 — still-fresh" "$out" '"reason": "still-fresh"'
assert_exit "T8.2 — exit 1" "$rc" 1
"$SCRIPT" release --owner=B >/dev/null

echo "=== T9 — status absent ==="
assert "T9.1 — present false" "$("$SCRIPT" status)" '"present": false'

echo "=== T10 — heartbeat sans lock ==="
out=$("$SCRIPT" heartbeat --owner=A); rc=$?
assert "T10.1 — no-lock" "$out" '"reason": "no-lock"'
assert_exit "T10.2 — exit 1" "$rc" 1

num_eq() { if [ "$2" -eq "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1 (=$2, attendu $3)"; FAIL=$((FAIL+1)); fi; }

echo "=== T11 — concurrence : un SEUL acquéreur (mkdir atomique, H1) ==="
rm -rf "$VF_DRIVER_LOCK"
for i in 1 2 3 4 5 6 7 8; do ( "$SCRIPT" acquire --owner="C$i" --step=race >"$WORK_DIR/out.$i" 2>/dev/null ) & done
wait
won=$(grep -l '"acquired": true' "$WORK_DIR"/out.* 2>/dev/null | wc -l | tr -d ' ')
num_eq "T11.1 — exactement 1 gagnant sur 8 acquire simultanés" "$won" 1

echo "=== T12 — meta absent/partiel récupérable via mtime (H2, anti-deadlock) ==="
rm -rf "$VF_DRIVER_LOCK"; mkdir -p "$(dirname "$VF_DRIVER_LOCK")"; mkdir "$VF_DRIVER_LOCK"  # dossier SANS meta
touch -t 202001010000 "$VF_DRIVER_LOCK"  # mtime très ancien → au-delà du TTL
assert "T12.1 — lock sans meta → stale (mtime, pas 'frais éternel')" "$("$SCRIPT" status)" '"stale": true'
assert "T12.2 — récupérable par un nouvel owner" "$("$SCRIPT" acquire --owner=NEW --step=z)" '"acquired": true'

echo "=== T13 — récupération concurrente : un SEUL récupère (H1) ==="
# CONCURRENCE ÉLEVÉE ET RÉPÉTÉE, à dessein. La forme précédente (6 concurrents, 1 round) ne
# révélait le défaut qu'en loterie : verte sur macOS, rouge sur runner Linux — 24 concurrents la
# rendaient rouge des deux côtés, avec jusqu'à 5 acquéreurs simultanés observés. Un contrat
# d'exclusion mutuelle ne se mesure pas sur un tirage : on répète, et on exige l'égalité stricte
# à CHAQUE round. Les deux bornes comptent — 0 gagnant est un échec au même titre que 2, sinon
# un lock qui refuse tout le monde passerait pour correct.
T13_N=24; T13_ROUNDS=5
t13_bad=0; t13_worst=0; t13_zero=0
for round in $(seq 1 "$T13_ROUNDS"); do
  rm -rf "$VF_DRIVER_LOCK" "$WORK_DIR"/rec.*
  "$SCRIPT" acquire --owner=DEAD --step=x >/dev/null 2>&1
  age_stale "$VF_DRIVER_LOCK"
  for i in $(seq 1 "$T13_N"); do ( "$SCRIPT" acquire --owner="R$i" --step=y >"$WORK_DIR/rec.$i" 2>/dev/null ) & done
  wait
  won=$(grep -l '"acquired": true' "$WORK_DIR"/rec.* 2>/dev/null | wc -l | tr -d ' ')
  [ "$won" -gt "$t13_worst" ] && t13_worst="$won"
  [ "$won" -eq 0 ] && t13_zero=$((t13_zero+1))
  [ "$won" -ne 1 ] && t13_bad=$((t13_bad+1))
done
num_eq "T13.1 — $T13_ROUNDS rounds × $T13_N concurrents : aucun round hors contrat (pire=$t13_worst)" "$t13_bad" 0
num_eq "T13.2 — jamais 0 gagnant (un lock périmé reste récupérable)" "$t13_zero" 0
rm -rf "$VF_DRIVER_LOCK" "$WORK_DIR"/rec.*

echo "=== T14 — TTL non numérique → défaut 1800 (L3, anti-injection) ==="
rm -rf "$VF_DRIVER_LOCK"
VF_DRIVER_TTL=abc "$SCRIPT" acquire --owner=A >/dev/null 2>&1
assert "T14.1 — TTL 'abc' rejeté → 1800" "$(VF_DRIVER_TTL=abc "$SCRIPT" status)" '"ttl": 1800'
"$SCRIPT" release --owner=A >/dev/null 2>&1

echo ""
echo "=================================="
echo "  Résultats : $PASS PASS / $FAIL FAIL"
echo "=================================="
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
