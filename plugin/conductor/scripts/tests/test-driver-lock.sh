#!/usr/bin/env bash
# test-driver-lock.sh — Suite de tests pour driver-lock.sh (ADR-053, Pattern A)
#
# T0 GEL-2 : voie libre refuse un lock legacy frais deja tenu (double-detenteur ferme)
# T1 acquisition franche · T2 double-acquisition refusée · T3 ré-acquisition idempotente (reentrant)
# T4 heartbeat préserve le step · T5 release owner mismatch refusé · T6 release owner correct
# T7 acquire ordinaire sur lock périmé REFUSE (D-32-02, LOCK-04, auto-steal fermé)
# T8 recover sur fixture propre (BL-4, découplé de T7) · T9 status présent/absent
# T10 heartbeat sans lock → erreur
# T15 acquire pose session_ids + expose generation · T16 heartbeat préserve l'identité (ADR-064)
# T17 acquire sans CLAUDE_CODE_SESSION_ID → session_ids vide · T18 rétrocompat meta sans session_ids
# T19 assainissement (virgule/espace/saut de ligne injectés) · T20 acquire (voie libre) expose lui aussi generation+session_ids
# T21 lease_seconds observable, distincte du battement · T22 heartbeat ne remet pas la lease à zéro
# T23 lease longue jamais périmée (refus à un AUTRE owner) · T24 TTL par défaut inchangé (1800)
# T25 rétrocompat meta sans acquired_epoch → lease_seconds null
# T26 refus stale-requires-takeover nomme la marche à suivre · T27-T31 verbe takeover
# T32 takeover concurrent 24x5 (patron T13) · T13 acquire concurrent sur lock périmé = ZERO gagnant
# T33-legacy takeover sur dossier legacy périmé avec meta complet (SE-6)
# T33-T41b verbe reclaim (D-32-03(f)) — mutex partagé avec takeover, plafond LRU, trap BL-3
# T42-T45 journal append-only des évènements de reprise (D-32-02)
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

# Validité JSON par un parse RÉEL, jamais par grep seul (T15/T17/T19) : rend non nul si le parse
# python échoue. Utilisation : json_ok "$out"; assert_exit "…" $? 0
json_ok() { printf '%s' "$1" | python3 -c 'import json,sys; json.load(sys.stdin)' 2>/dev/null; }

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

# Retire une ligne "<clé>=" du meta d'un lock (forme lien ou dossier), pour simuler un lock posé
# par une version ANTÉRIEURE du script qui ne connaissait pas ce champ. Même motif qu'age_stale :
# les cas ne connaissent jamais le protocole interne du meta, seuls les helpers l'éditent — un cas
# qui éditerait le meta à la main casserait au premier changement de protocole.
meta_drop_key() {
  local lock="$1" key="$2" meta
  if [ -L "$lock" ]; then
    meta="$(dirname "$lock")/$(readlink "$lock")/meta"
  else
    meta="$lock/meta"
  fi
  [ -f "$meta" ] && sed -i.bak "/^${key}=/d" "$meta" 2>/dev/null && rm -f "${meta}.bak"
}

# Recule acquired_epoch d'un lock existant d'un nombre de secondes donné, SANS toucher
# heartbeat_epoch — c'est précisément la dissociation lease/battement que LOCK-01 doit rendre
# observable (D-32-01). Aucune attente temporelle : l'epoch est FORGÉ, jamais attendu (un cas
# sleep-dépendant est flaky en CI, et il l'est silencieusement). Même motif qu'age_stale : les cas
# ne connaissent jamais le protocole interne, seul ce helper l'édite.
lease_backdate() {
  local lock="$1" secs="$2" meta old
  if [ -L "$lock" ]; then
    meta="$(dirname "$lock")/$(readlink "$lock")/meta"
  else
    meta="$lock/meta"
  fi
  [ -f "$meta" ] || return 1
  old=$(( $(date +%s) - secs ))
  sed -i.bak "s/^acquired_epoch=.*/acquired_epoch=$old/" "$meta" && rm -f "${meta}.bak"
}

echo "=== T0 — GEL-2 : voie libre refuse un lock LEGACY frais déjà tenu (double-détenteur fermé) ==="
rm -rf "$VF_DRIVER_LOCK"
mkdir -p "$VF_DRIVER_LOCK"
printf 'owner=alice\nstep=x\nheartbeat_epoch=%s\n' "$(date +%s)" > "$VF_DRIVER_LOCK/meta"
out=$("$SCRIPT" acquire --owner=bob --step=y); rc=$?
assert "T0.1 — acquired false" "$out" '"acquired": false'
assert "T0.2 — refus held, comme un lock nominal occupé" "$out" '"reason": "held"'
assert_exit "T0.3 — exit 1" "$rc" 1
_t0_owner=$(grep '^owner=' "$VF_DRIVER_LOCK/meta" | cut -d= -f2-)
assert "T0.4 — owner EFFECTIF (meta sur disque) inchangé (alice)" "$_t0_owner" "alice"
rm -rf "$VF_DRIVER_LOCK"

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

echo "=== T7 — acquire ORDINAIRE sur lock périmé REFUSE (D-32-02, LOCK-04 — auto-steal fermé) ==="
rm -rf "$VF_DRIVER_LOCK"
"$SCRIPT" acquire --owner=DEAD --step=x >/dev/null
# antidate le heartbeat bien au-delà du TTL par défaut (1800 s)
age_stale "$VF_DRIVER_LOCK"
out=$("$SCRIPT" acquire --owner=B --step=y); rc=$?
assert "T7.1 — acquired false" "$out" '"acquired": false'
assert "T7.2 — reason stale-requires-takeover" "$out" '"reason": "stale-requires-takeover"'
assert "T7.3 — owner reste DEAD (jamais volé)" "$("$SCRIPT" status)" '"owner": "DEAD"'
assert_exit "T7.4 — exit 1 (refus)" "$rc" 1

echo "=== T8 — recover sur fixture PROPRE (BL-4 : découplé de T7, jamais son état résiduel) ==="
rm -rf "$VF_DRIVER_LOCK"
"$SCRIPT" acquire --owner=DEAD8 --step=x >/dev/null
age_stale "$VF_DRIVER_LOCK"
out=$("$SCRIPT" recover); rc=$?
assert "T8.1 — recovered true (élagage anonyme)" "$out" '"recovered": true'
assert_exit "T8.2 — exit 0" "$rc" 0
out2=$("$SCRIPT" release --owner=B); rc2=$?
assert "T8.3 — release ultérieur sur lock élagué : no-lock" "$out2" '"reason": "no-lock"'
assert_exit "T8.4 — exit 0" "$rc2" 0

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

echo "=== T12 — meta absent/partiel : stale via mtime, récupérable SEULEMENT par takeover (GEL-2) ==="
rm -rf "$VF_DRIVER_LOCK"; mkdir -p "$(dirname "$VF_DRIVER_LOCK")"; mkdir "$VF_DRIVER_LOCK"  # dossier SANS meta
touch -t 202001010000 "$VF_DRIVER_LOCK"  # mtime très ancien → au-delà du TTL
assert "T12.1 — lock sans meta → stale (mtime, pas 'frais éternel')" "$("$SCRIPT" status)" '"stale": true'
out=$("$SCRIPT" acquire --owner=NEW --step=z); rc=$?
assert "T12.2a — acquire ordinaire REFUSE (GEL-2 : voie libre fermée sur dossier legacy stale)" "$out" '"reason": "stale-requires-takeover"'
assert_exit "T12.2b — exit 1" "$rc" 1
out2=$("$SCRIPT" takeover --owner=NEW --step=z); rc2=$?
assert "T12.2c — takeover RÉUSSIT (récupérabilité réelle préservée)" "$out2" '"acquired": true'
assert_exit "T12.2d — exit 0" "$rc2" 0
_t12_gen="$(readlink "$VF_DRIVER_LOCK")"
_t12_owner=$(grep '^owner=' "$(dirname "$VF_DRIVER_LOCK")/$_t12_gen/meta" 2>/dev/null | cut -d= -f2-)
assert "T12.2e — owner EFFECTIF (meta sur disque, jamais le seul JSON rendu) = NEW" "$_t12_owner" "NEW"
"$SCRIPT" release --owner=NEW >/dev/null 2>&1

echo "=== T13 — acquire concurrent sur lock périmé : ZÉRO gagnant (auto-steal fermé côté concurrent) ==="
# CONCURRENCE ÉLEVÉE ET RÉPÉTÉE, à dessein — même patron que T32 (takeover), mais l'attendu est
# inversé : depuis D-32-02, un `acquire` ordinaire ne recupère plus jamais un lock périmé, donc
# aucun round ne doit produire le moindre gagnant, et chaque refus doit nommer takeover.
T13_N=24; T13_ROUNDS=5
t13_bad=0
for round in $(seq 1 "$T13_ROUNDS"); do
  rm -rf "$VF_DRIVER_LOCK" "$WORK_DIR"/rec.*
  "$SCRIPT" acquire --owner=DEAD --step=x >/dev/null 2>&1
  age_stale "$VF_DRIVER_LOCK"
  for i in $(seq 1 "$T13_N"); do ( "$SCRIPT" acquire --owner="R$i" --step=y >"$WORK_DIR/rec.$i" 2>/dev/null ) & done
  wait
  won=$(grep -l '"acquired": true' "$WORK_DIR"/rec.* 2>/dev/null | wc -l | tr -d ' ')
  refused=$(grep -l 'stale-requires-takeover' "$WORK_DIR"/rec.* 2>/dev/null | wc -l | tr -d ' ')
  [ "$won" -ne 0 ] && t13_bad=$((t13_bad+1))
  [ "$refused" -ne "$T13_N" ] && t13_bad=$((t13_bad+1))
done
num_eq "T13.1 — $T13_ROUNDS rounds × $T13_N concurrents : jamais un seul gagnant, tous refusés stale-requires-takeover" "$t13_bad" 0
rm -rf "$VF_DRIVER_LOCK" "$WORK_DIR"/rec.*

echo "=== T14 — TTL non numérique → défaut 1800 (L3, anti-injection) ==="
rm -rf "$VF_DRIVER_LOCK"
VF_DRIVER_TTL=abc "$SCRIPT" acquire --owner=A >/dev/null 2>&1
assert "T14.1 — TTL 'abc' rejeté → 1800" "$(VF_DRIVER_TTL=abc "$SCRIPT" status)" '"ttl": 1800'
"$SCRIPT" release --owner=A >/dev/null 2>&1

echo "=== T15 — acquire pose session_ids et expose generation (D-32-03(a)) ==="
rm -rf "$VF_DRIVER_LOCK"
out=$(CLAUDE_CODE_SESSION_ID=sess-alpha "$SCRIPT" acquire --owner=A --step=t15); rc=$?
st=$("$SCRIPT" status)
assert_exit "T15.1 — acquire exit 0" "$rc" 0
assert "T15.2 — session_ids contient sess-alpha" "$st" '"session_ids": ["sess-alpha"]'
assert "T15.3 — generation non vide, préfixe DRIVER.lock.gen." "$st" '"generation": "DRIVER.lock.gen.'
json_ok "$st"; assert_exit "T15.4 — status JSON valide" $? 0

echo "=== T16 — heartbeat d'un AUTRE contexte ne réécrit jamais l'identité (ADR-064) ==="
CLAUDE_CODE_SESSION_ID=sess-beta "$SCRIPT" heartbeat --owner=A >/dev/null
st=$("$SCRIPT" status)
assert "T16.1 — session_ids reste sess-alpha après heartbeat de sess-beta" "$st" '"session_ids": ["sess-alpha"]'

echo "=== T17 — acquire sans CLAUDE_CODE_SESSION_ID → session_ids vide ==="
"$SCRIPT" release --owner=A >/dev/null
rm -rf "$VF_DRIVER_LOCK"
out=$(env -u CLAUDE_CODE_SESSION_ID "$SCRIPT" acquire --owner=A --step=t17); rc=$?
assert_exit "T17.1 — exit 0 (acquire CLI pure)" "$rc" 0
assert "T17.2 — session_ids vide" "$out" '"session_ids": []'
json_ok "$out"; assert_exit "T17.3 — JSON acquire valide" $? 0

echo "=== T18 — rétrocompatibilité : lock de l'ancien script (meta sans session_ids) ==="
"$SCRIPT" release --owner=A >/dev/null 2>&1
rm -rf "$VF_DRIVER_LOCK"
CLAUDE_CODE_SESSION_ID=sess-old "$SCRIPT" acquire --owner=OLD --step=t18 >/dev/null
meta_drop_key "$VF_DRIVER_LOCK" session_ids
_t18_gen="$(readlink "$VF_DRIVER_LOCK")"
_t18_n=$(grep -c '^session_ids=' "$(dirname "$VF_DRIVER_LOCK")/$_t18_gen/meta")
num_eq "T18.0 — (SE-7) fixture: la ligne session_ids= est réellement absente" "$_t18_n" 0
st=$("$SCRIPT" status); rc_status=$?
assert_exit "T18.1 — status exit 0 sur lock rétrocompat" "$rc_status" 0
assert "T18.2 — session_ids vide (repli, jamais lecture par position)" "$st" '"session_ids": []'
out_hb=$(CLAUDE_CODE_SESSION_ID=sess-old2 "$SCRIPT" heartbeat --owner=OLD); rc_hb=$?
assert_exit "T18.3 — heartbeat exit 0 sur lock rétrocompat" "$rc_hb" 0
st2=$("$SCRIPT" status)
assert "T18.4 — heartbeat n'injecte aucune identité" "$st2" '"session_ids": []'

echo "=== T19 — assainissement : virgule, espace et saut de ligne injectés ==="
"$SCRIPT" release --owner=OLD >/dev/null 2>&1
rm -rf "$VF_DRIVER_LOCK"
INJECT=$'sess,evil injected\nid'
out=$(CLAUDE_CODE_SESSION_ID="$INJECT" "$SCRIPT" acquire --owner=A --step=t19)
_t19_gen="$(readlink "$VF_DRIVER_LOCK")"
_t19_meta="$(dirname "$VF_DRIVER_LOCK")/$_t19_gen/meta"
_t19_total=$(wc -l < "$_t19_meta" | tr -d ' ')
num_eq "T19.1 — le meta garde exactement 8 lignes (une par clé, aucune injectée)" "$_t19_total" 8
_t19_nsid=$(grep -c '^session_ids=' "$_t19_meta")
num_eq "T19.2 — exactement une ligne session_ids=" "$_t19_nsid" 1
_t19_val=$(grep '^session_ids=' "$_t19_meta" | cut -d= -f2-)
case "$_t19_val" in
  *,*|*' '*) echo "  ❌ FAIL — T19.3 — aucun séparateur injecté dans session_ids"; FAIL=$((FAIL+1)) ;;
  *)         echo "  ✅ PASS — T19.3 — aucun séparateur injecté dans session_ids"; PASS=$((PASS+1)) ;;
esac
json_ok "$out"; assert_exit "T19.4 — JSON acquire valide malgré l'injection" $? 0

echo "=== T20 — acquire (voie libre) expose lui aussi generation + session_ids ==="
"$SCRIPT" release --owner=A >/dev/null 2>&1
rm -rf "$VF_DRIVER_LOCK"
out=$(CLAUDE_CODE_SESSION_ID=sess-t20 "$SCRIPT" acquire --owner=A --step=t20); rc=$?
assert_exit "T20.1 — exit 0" "$rc" 0
assert "T20.2 — generation présente dans la sortie d'acquire" "$out" '"generation": "DRIVER.lock.gen.'
assert "T20.3 — session_ids présent dans la sortie d'acquire" "$out" '"session_ids": ["sess-t20"]'
json_ok "$out"; assert_exit "T20.4 — JSON acquire valide" $? 0
"$SCRIPT" release --owner=A >/dev/null 2>&1

echo "=== T21 — lease_seconds observable, dissociée du battement (D-32-01) ==="
"$SCRIPT" release --owner=A >/dev/null 2>&1
rm -rf "$VF_DRIVER_LOCK"
"$SCRIPT" acquire --owner=A --step=t21 >/dev/null
lease_backdate "$VF_DRIVER_LOCK" 5000
st=$("$SCRIPT" status)
_t21_lease=$(printf '%s' "$st" | python3 -c 'import json,sys; print(json.load(sys.stdin)["lease_seconds"])')
_t21_age=$(printf '%s' "$st" | python3 -c 'import json,sys; print(json.load(sys.stdin)["age_seconds"])')
if [ "$_t21_lease" -ge 5000 ]; then echo "  ✅ PASS — T21.1 — lease_seconds >= 5000"; PASS=$((PASS+1)); else echo "  ❌ FAIL — T21.1 — lease_seconds >= 5000"; echo "     obtenu: $_t21_lease"; FAIL=$((FAIL+1)); fi
if [ "$_t21_age" -lt 60 ]; then echo "  ✅ PASS — T21.2 — age_seconds < 60 (heartbeat resté frais)"; PASS=$((PASS+1)); else echo "  ❌ FAIL — T21.2 — age_seconds < 60"; echo "     obtenu: $_t21_age"; FAIL=$((FAIL+1)); fi
assert "T21.3 — stale false malgré la lease reculée" "$st" '"stale": false'

echo "=== T22 — heartbeat ne remet PAS la lease à zéro ==="
"$SCRIPT" heartbeat --owner=A >/dev/null
st=$("$SCRIPT" status)
_t22_lease=$(printf '%s' "$st" | python3 -c 'import json,sys; print(json.load(sys.stdin)["lease_seconds"])')
if [ "$_t22_lease" -ge 5000 ]; then echo "  ✅ PASS — T22.1 — lease_seconds toujours >= 5000 après heartbeat"; PASS=$((PASS+1)); else echo "  ❌ FAIL — T22.1 — lease_seconds toujours >= 5000 après heartbeat"; echo "     obtenu: $_t22_lease"; FAIL=$((FAIL+1)); fi
assert "T22.2 — stale false" "$st" '"stale": false'

echo "=== T23 — contrainte dure : une lease de 999999s avec heartbeat frais n'est JAMAIS périmée ==="
"$SCRIPT" release --owner=A >/dev/null 2>&1
rm -rf "$VF_DRIVER_LOCK"
"$SCRIPT" acquire --owner=A --step=t23 >/dev/null
lease_backdate "$VF_DRIVER_LOCK" 999999
"$SCRIPT" heartbeat --owner=A >/dev/null
st=$("$SCRIPT" status)
assert "T23.1 — stale false malgré une lease de 999999s" "$st" '"stale": false'
out=$("$SCRIPT" acquire --owner=OTHER --step=steal); rc=$?
assert "T23.2 — acquire d'un AUTRE owner refusé (held), pas volé pour ancienneté" "$out" '"reason": "held"'
assert_exit "T23.3 — exit 1" "$rc" 1

echo "=== T24 — TTL par défaut inchangé (1800) ==="
st=$("$SCRIPT" status)
assert "T24.1 — ttl 1800 sur lock frais, sans surcharge d'environnement" "$st" '"ttl": 1800'
"$SCRIPT" release --owner=A >/dev/null 2>&1

echo "=== T25 — rétrocompatibilité : meta sans acquired_epoch → lease_seconds null ==="
rm -rf "$VF_DRIVER_LOCK"
"$SCRIPT" acquire --owner=A --step=t25 >/dev/null
meta_drop_key "$VF_DRIVER_LOCK" acquired_epoch
_t25_gen="$(readlink "$VF_DRIVER_LOCK")"
_t25_n=$(grep -c '^acquired_epoch=' "$(dirname "$VF_DRIVER_LOCK")/$_t25_gen/meta")
num_eq "T25.0 — (SE-7) fixture: la ligne acquired_epoch= est réellement absente" "$_t25_n" 0
st=$("$SCRIPT" status); rc=$?
assert_exit "T25.1 — status exit 0 sur lock sans acquired_epoch" "$rc" 0
assert "T25.2 — lease_seconds null (jamais un 0 trompeur)" "$st" '"lease_seconds": null'
assert "T25.3 — stale reste calculé normalement (heartbeat frais)" "$st" '"stale": false'
"$SCRIPT" release --owner=A >/dev/null 2>&1

echo "=== T26 — le refus stale-requires-takeover nomme la marche à suivre ==="
rm -rf "$VF_DRIVER_LOCK"
"$SCRIPT" acquire --owner=DEAD26 --step=x >/dev/null
age_stale "$VF_DRIVER_LOCK"
out=$("$SCRIPT" acquire --owner=B26 --step=y)
assert "T26.1 — le refus nomme 'takeover'" "$out" 'takeover'
rm -rf "$VF_DRIVER_LOCK"

echo "=== T27 — takeover reprend explicitement un lock périmé ==="
rm -rf "$VF_DRIVER_LOCK"
"$SCRIPT" acquire --owner=DEAD27 --step=x >/dev/null
age_stale "$VF_DRIVER_LOCK"
out=$("$SCRIPT" takeover --owner=B27 --step=y); rc=$?
assert "T27.1 — acquired true" "$out" '"acquired": true'
assert "T27.2 — previous_owner DEAD27" "$out" '"previous_owner": "DEAD27"'
assert_exit "T27.3 — exit 0" "$rc" 0
assert "T27.4 — status owner B27" "$("$SCRIPT" status)" '"owner": "B27"'
"$SCRIPT" release --owner=B27 >/dev/null 2>&1

echo "=== T28 — takeover sur lock FRAIS refusé (still-fresh) ==="
rm -rf "$VF_DRIVER_LOCK"
"$SCRIPT" acquire --owner=A28 --step=x >/dev/null
out=$("$SCRIPT" takeover --owner=B28); rc=$?
assert "T28.1 — reason still-fresh" "$out" '"reason": "still-fresh"'
assert_exit "T28.2 — exit 1" "$rc" 1
assert "T28.3 — owner inchangé A28" "$("$SCRIPT" status)" '"owner": "A28"'
"$SCRIPT" release --owner=A28 >/dev/null 2>&1

echo "=== T29 — takeover sans --owner ==="
out=$("$SCRIPT" takeover); rc=$?
assert "T29.1 — error owner-required" "$out" '"error": "owner-required"'
assert_exit "T29.2 — exit 1" "$rc" 1

echo "=== T30 — takeover sans lock du tout ==="
rm -rf "$VF_DRIVER_LOCK"
out=$("$SCRIPT" takeover --owner=X30); rc=$?
assert "T30.1 — reason no-lock" "$out" '"reason": "no-lock"'
assert_exit "T30.2 — exit 1" "$rc" 1

echo "=== T31 — takeover réinitialise session_ids au seul repreneur ==="
rm -rf "$VF_DRIVER_LOCK"
CLAUDE_CODE_SESSION_ID=sess-old31 "$SCRIPT" acquire --owner=DEAD31 --step=x >/dev/null
age_stale "$VF_DRIVER_LOCK"
CLAUDE_CODE_SESSION_ID=sess-new31 "$SCRIPT" takeover --owner=B31 >/dev/null
st=$("$SCRIPT" status)
assert "T31.1 — session_ids == [sess-new31] seul (identifiant évincé disparu)" "$st" '"session_ids": ["sess-new31"]'
"$SCRIPT" release --owner=B31 >/dev/null 2>&1

echo "=== T32 — takeover concurrent : un SEUL récupère (24 × 5, patron T13) ==="
T32_N=24; T32_ROUNDS=5
t32_bad=0; t32_worst=0; t32_zero=0
for round in $(seq 1 "$T32_ROUNDS"); do
  rm -rf "$VF_DRIVER_LOCK" "$WORK_DIR"/t32.*
  "$SCRIPT" acquire --owner=DEAD32 --step=x >/dev/null 2>&1
  age_stale "$VF_DRIVER_LOCK"
  for i in $(seq 1 "$T32_N"); do ( "$SCRIPT" takeover --owner="T32R$i" --step=y >"$WORK_DIR/t32.$i" 2>/dev/null ) & done
  wait
  won=$(grep -l '"acquired": true' "$WORK_DIR"/t32.* 2>/dev/null | wc -l | tr -d ' ')
  [ "$won" -gt "$t32_worst" ] && t32_worst="$won"
  [ "$won" -eq 0 ] && t32_zero=$((t32_zero+1))
  [ "$won" -ne 1 ] && t32_bad=$((t32_bad+1))
done
num_eq "T32.1 — $T32_ROUNDS rounds × $T32_N concurrents : aucun round hors contrat (pire=$t32_worst)" "$t32_bad" 0
num_eq "T32.2 — jamais 0 gagnant (un lock périmé reste récupérable via takeover)" "$t32_zero" 0
rm -rf "$VF_DRIVER_LOCK" "$WORK_DIR"/t32.*

echo "=== T33-legacy — takeover sur lock LEGACY (dossier réel) périmé AVEC meta complet (SE-6) ==="
rm -rf "$VF_DRIVER_LOCK"
mkdir -p "$(dirname "$VF_DRIVER_LOCK")"; mkdir "$VF_DRIVER_LOCK"
{
  echo 'owner=ALICE33'
  echo 'step=x'
  echo 'branch='
  echo 'worktree='
  echo 'session_ids='
  echo 'acquired_epoch=1'
  echo 'acquired_iso=2020-01-01T00:00:00'
  echo 'heartbeat_epoch=1'
} > "$VF_DRIVER_LOCK/meta"
out=$("$SCRIPT" takeover --owner=B33 --step=y); rc=$?
assert "T33L.1 — acquired true (reprise réussie, comme sur un lock nominal)" "$out" '"acquired": true'
assert_exit "T33L.2 — exit 0" "$rc" 0
assert "T33L.3 — status owner B33 après coup" "$("$SCRIPT" status)" '"owner": "B33"'
"$SCRIPT" release --owner=B33 >/dev/null 2>&1

echo ""
echo "=================================="
echo "  Résultats : $PASS PASS / $FAIL FAIL"
echo "=================================="
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
