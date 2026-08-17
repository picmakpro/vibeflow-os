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
# T46 takeover : revalidation post-mutex sur l'ÂGE (pas seulement la génération) — fenêtre où le
#     détenteur périmé redevient vivant (heartbeat réel) pendant la reprise
# T47-T50 correction ciblée post-revue (juges code-review/audit/goal-backward, Phase 32) :
#     T47 BL-3 sur `recover` (mutex libéré même si le process meurt juste après l'avoir pris,
#         même patron que T41b) · T48 owner/step assainis à l'écriture, JSON reste parsable ·
#     T49 guard_effective observable (session_ids vide vs peuplé) · T50 recover journalise
#         new_owner/session_id quand connus, sans exiger --owner
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

echo "=== T33 — reclaim ré-attache une session neuve à un lock VIVANT (D-32-03(f)) ==="
rm -rf "$VF_DRIVER_LOCK"
CLAUDE_CODE_SESSION_ID=sess-alpha "$SCRIPT" acquire --owner=A33 --step=x >/dev/null
out=$(CLAUDE_CODE_SESSION_ID=sess-beta "$SCRIPT" reclaim --owner=A33); rc=$?
assert "T33.1 — reclaimed true" "$out" '"reclaimed": true'
assert_exit "T33.2 — exit 0" "$rc" 0
st=$("$SCRIPT" status)
assert "T33.3 — session_ids = [sess-alpha, sess-beta] (append, jamais remplacement)" "$st" '"session_ids": ["sess-alpha", "sess-beta"]'

echo "=== T34 — reclaim owner mismatch refusé (not-owner) ==="
out=$(CLAUDE_CODE_SESSION_ID=sess-gamma "$SCRIPT" reclaim --owner=B34); rc=$?
assert "T34.1 — reason not-owner" "$out" '"reason": "not-owner"'
assert_exit "T34.2 — exit 1" "$rc" 1
assert "T34.3 — session_ids inchangé" "$("$SCRIPT" status)" '"session_ids": ["sess-alpha", "sess-beta"]'
"$SCRIPT" release --owner=A33 >/dev/null 2>&1

echo "=== T35 — reclaim sur lock périmé refusé (frontière avec takeover) ==="
rm -rf "$VF_DRIVER_LOCK"
"$SCRIPT" acquire --owner=A35 --step=x >/dev/null
age_stale "$VF_DRIVER_LOCK"
out=$(CLAUDE_CODE_SESSION_ID=sess35 "$SCRIPT" reclaim --owner=A35); rc=$?
assert "T35.1 — reason stale-requires-takeover" "$out" '"reason": "stale-requires-takeover"'
assert_exit "T35.2 — exit 1" "$rc" 1
rm -rf "$VF_DRIVER_LOCK"

echo "=== T36 — reclaim sans identifiant de session : refus honnête ==="
rm -rf "$VF_DRIVER_LOCK"
CLAUDE_CODE_SESSION_ID=sess-orig36 "$SCRIPT" acquire --owner=A36 --step=x >/dev/null
out=$(env -u CLAUDE_CODE_SESSION_ID "$SCRIPT" reclaim --owner=A36); rc=$?
assert "T36.1 — reason no-session-id" "$out" '"reason": "no-session-id"'
assert_exit "T36.2 — exit 1" "$rc" 1
assert "T36.3 — session_ids inchangé" "$("$SCRIPT" status)" '"session_ids": ["sess-orig36"]'
"$SCRIPT" release --owner=A36 >/dev/null 2>&1

echo "=== T37 — reclaim sans --owner / sans lock ==="
out=$("$SCRIPT" reclaim); rc=$?
assert "T37.1 — error owner-required" "$out" '"error": "owner-required"'
assert_exit "T37.2 — exit 1" "$rc" 1
rm -rf "$VF_DRIVER_LOCK"
out2=$(CLAUDE_CODE_SESSION_ID=sess37 "$SCRIPT" reclaim --owner=X37); rc2=$?
assert "T37.3 — reason no-lock" "$out2" '"reason": "no-lock"'
assert_exit "T37.4 — exit 1" "$rc2" 1

echo "=== T38 — idempotence : deux reclaim du MÊME identifiant, une seule occurrence ==="
rm -rf "$VF_DRIVER_LOCK"
CLAUDE_CODE_SESSION_ID=sess-init38 "$SCRIPT" acquire --owner=A38 --step=x >/dev/null
CLAUDE_CODE_SESSION_ID=sess-dup38 "$SCRIPT" reclaim --owner=A38 >/dev/null
CLAUDE_CODE_SESSION_ID=sess-dup38 "$SCRIPT" reclaim --owner=A38 >/dev/null
st=$("$SCRIPT" status)
assert "T38.1 — session_ids ne contient sess-dup38 qu'UNE fois" "$st" '"session_ids": ["sess-init38", "sess-dup38"]'
"$SCRIPT" release --owner=A38 >/dev/null 2>&1

echo "=== T39 — plafond LRU : 10 identifiants distincts → exactement 8 entrées ==="
rm -rf "$VF_DRIVER_LOCK"
CLAUDE_CODE_SESSION_ID=sess-t39-00 "$SCRIPT" acquire --owner=A39 --step=x >/dev/null
for i in $(seq 1 10); do
  n=$(printf '%02d' "$i")
  CLAUDE_CODE_SESSION_ID="sess-t39-$n" "$SCRIPT" reclaim --owner=A39 >/dev/null
done
_t39_gen="$(readlink "$VF_DRIVER_LOCK")"
_t39_meta="$(dirname "$VF_DRIVER_LOCK")/$_t39_gen/meta"
_t39_val=$(grep '^session_ids=' "$_t39_meta" | cut -d= -f2-)
_t39_n=$(printf '%s' "$_t39_val" | tr ',' '\n' | grep -c .)
num_eq "T39.1 — exactement 8 entrées après le plafond" "$_t39_n" 8
case "$_t39_val" in
  *sess-t39-10*) echo "  ✅ PASS — T39.2 — le plus récent (sess-t39-10) est présent"; PASS=$((PASS+1)) ;;
  *) echo "  ❌ FAIL — T39.2 — le plus récent (sess-t39-10) est présent"; FAIL=$((FAIL+1)) ;;
esac
case "$_t39_val" in
  *sess-t39-00*) echo "  ❌ FAIL — T39.3 — le plus ancien (sess-t39-00) a été évincé"; FAIL=$((FAIL+1)) ;;
  *) echo "  ✅ PASS — T39.3 — le plus ancien (sess-t39-00) a été évincé"; PASS=$((PASS+1)) ;;
esac
"$SCRIPT" release --owner=A39 >/dev/null 2>&1

echo "=== T40 — reclaim concurrent : 12 identifiants distincts, aucune écriture perdue ==="
rm -rf "$VF_DRIVER_LOCK" "$WORK_DIR"/t40.*
CLAUDE_CODE_SESSION_ID=sess-t40-init "$SCRIPT" acquire --owner=A40 --step=x >/dev/null
for i in $(seq 1 12); do
  n=$(printf '%02d' "$i")
  ( CLAUDE_CODE_SESSION_ID="sess-t40-$n" "$SCRIPT" reclaim --owner=A40 >"$WORK_DIR/t40.$i" 2>/dev/null ) &
done
wait
_t40_gen="$(readlink "$VF_DRIVER_LOCK")"
_t40_meta="$(dirname "$VF_DRIVER_LOCK")/$_t40_gen/meta"
_t40_nlines=$(grep -c '^session_ids=' "$_t40_meta")
if [ "$_t40_nlines" -ne 1 ]; then
  echo "  ❌ FAIL — T40.0 — fixture cassé : meta mal formé ($_t40_nlines lignes session_ids=)"
  FAIL=$((FAIL+1))
else
  echo "  ✅ PASS — T40.0 — meta bien formé (une seule ligne session_ids=)"
  PASS=$((PASS+1))
  st=$("$SCRIPT" status)
  json_ok "$st"; assert_exit "T40.1 — status JSON parsable après la course" $? 0
  _t40_succ=$(grep -l '"reclaimed": true' "$WORK_DIR"/t40.* 2>/dev/null | wc -l | tr -d ' ')
  if [ "$_t40_succ" -ge 1 ]; then echo "  ✅ PASS — T40.2 — au moins 1 succès sur 12 (=$_t40_succ)"; PASS=$((PASS+1)); else echo "  ❌ FAIL — T40.2 — au moins 1 succès sur 12"; FAIL=$((FAIL+1)); fi
  _t40_val=$(grep '^session_ids=' "$_t40_meta" | cut -d= -f2-)
  _t40_lost=0
  for f in "$WORK_DIR"/t40.*; do
    if grep -q '"reclaimed": true' "$f" 2>/dev/null; then
      _t40_id=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["session_id"])' "$f" 2>/dev/null)
      case ",$_t40_val," in *",$_t40_id,"*) ;; *) _t40_lost=$((_t40_lost+1)) ;; esac
    fi
  done
  num_eq "T40.3 — aucun identifiant rapporté en succès n'est absent de la liste finale" "$_t40_lost" 0
fi
rm -rf "$WORK_DIR"/t40.*
"$SCRIPT" release --owner=A40 >/dev/null 2>&1

echo "=== T41 — reclaim ne prolonge PAS la fraîcheur du lock ==="
rm -rf "$VF_DRIVER_LOCK"
CLAUDE_CODE_SESSION_ID=sess-t41-a "$SCRIPT" acquire --owner=A41 --step=x >/dev/null
_t41_gen="$(readlink "$VF_DRIVER_LOCK")"
_t41_meta="$(dirname "$VF_DRIVER_LOCK")/$_t41_gen/meta"
_t41_old=$(( $(date +%s) - 900 ))  # à l'intérieur du TTL (900 < 1800) — le lock reste frais
sed -i.bak "s/^heartbeat_epoch=.*/heartbeat_epoch=$_t41_old/" "$_t41_meta" && rm -f "${_t41_meta}.bak"
CLAUDE_CODE_SESSION_ID=sess-t41-b "$SCRIPT" reclaim --owner=A41 >/dev/null
_t41_age_after=$(printf '%s' "$("$SCRIPT" status)" | python3 -c 'import json,sys; print(json.load(sys.stdin)["age_seconds"])')
if [ "$_t41_age_after" -ge 890 ]; then echo "  ✅ PASS — T41.1 — age_seconds reste ~900s après reclaim (battement non remis à zéro)"; PASS=$((PASS+1)); else echo "  ❌ FAIL — T41.1 — age_seconds reste ~900s après reclaim"; echo "     obtenu: $_t41_age_after"; FAIL=$((FAIL+1)); fi
"$SCRIPT" release --owner=A41 >/dev/null 2>&1

echo "=== T41b — BL-3 : mutex de reclaim libéré même si le process meurt juste après l'avoir pris ==="
rm -rf "$VF_DRIVER_LOCK"
CLAUDE_CODE_SESSION_ID=sess-t41b-init "$SCRIPT" acquire --owner=A41B --step=x >/dev/null
# Point d'injection déterministe (VF_DRIVER_TEST_DIE_AFTER_MUTEX, seam de test inerte par défaut) :
# un SIGTERM/SIGINT réel n'est PAS fiable ici — bash, une fois qu'il trappe un signal, REPREND son
# exécution après le handler au lieu de terminer (vérifié empiriquement), donc seul un `exit` réel
# simule fidèlement "le process meurt entre la prise du mutex et sa libération normale".
out=$(CLAUDE_CODE_SESSION_ID=sess-t41b-victim VF_DRIVER_TEST_DIE_AFTER_MUTEX=1 "$SCRIPT" reclaim --owner=A41B); rc=$?
assert_exit "T41b.1 — le process 'meurt' juste après avoir pris le mutex (exit 137)" "$rc" 137
_t41b_gen="$(readlink "$VF_DRIVER_LOCK")"
_t41b_mutex="${VF_DRIVER_LOCK}.rec.$(printf '%s' "$_t41b_gen" | tr -c 'A-Za-z0-9._-' '_')"
# -L (pas -e) : ln_atomic pointe le mutex vers "$$" (un PID nu, jamais un chemin existant) — -e
# SUIT le lien et le trouverait toujours "cassé" (faux négatif garanti), -L teste la présence du
# lien LUI-MÊME, ce qui est la propriété qui compte ici (le mutex existe-t-il encore, oui/non).
if [ -L "$_t41b_mutex" ]; then echo "  ❌ FAIL — T41b.2 — le mutex a été libéré (trap)"; FAIL=$((FAIL+1)); else echo "  ✅ PASS — T41b.2 — le mutex a été libéré (trap)"; PASS=$((PASS+1)); fi
out2=$(CLAUDE_CODE_SESSION_ID=sess-t41b-next "$SCRIPT" reclaim --owner=A41B); rc2=$?
assert "T41b.3 — un reclaim ULTÉRIEUR normal réussit (lock toujours reprenable)" "$out2" '"reclaimed": true'
assert_exit "T41b.4 — exit 0" "$rc2" 0
"$SCRIPT" release --owner=A41B >/dev/null 2>&1

echo "=== T42 — journal_event : une ligne JSON par takeover réussi ==="
rm -rf "$VF_DRIVER_LOCK" "$WORK_DIR"/DRIVER.lock.events.log
"$SCRIPT" acquire --owner=DEAD42 --step=x >/dev/null
age_stale "$VF_DRIVER_LOCK"
"$SCRIPT" takeover --owner=B42 --step=y >/dev/null
_t42_log="$WORK_DIR/DRIVER.lock.events.log"
if [ -f "$_t42_log" ]; then echo "  ✅ PASS — T42.1 — le journal existe"; PASS=$((PASS+1)); else echo "  ❌ FAIL — T42.1 — le journal existe"; FAIL=$((FAIL+1)); fi
_t42_n=$(wc -l < "$_t42_log" | tr -d ' ')
num_eq "T42.2 — exactement 1 ligne" "$_t42_n" 1
_t42_line=$(cat "$_t42_log")
json_ok "$_t42_line"; assert_exit "T42.3 — la ligne parse comme JSON" $? 0
assert "T42.4 — event takeover" "$_t42_line" '"event": "takeover"'
assert "T42.5 — previous_owner DEAD42" "$_t42_line" '"previous_owner": "DEAD42"'
assert "T42.6 — new_owner B42" "$_t42_line" '"new_owner": "B42"'
_t42_age=$(printf '%s' "$_t42_line" | python3 -c 'import json,sys; print(json.load(sys.stdin)["age_seconds"])')
case "$_t42_age" in ''|*[!0-9]*) echo "  ❌ FAIL — T42.7 — age_seconds numérique"; FAIL=$((FAIL+1)) ;; *) echo "  ✅ PASS — T42.7 — age_seconds numérique"; PASS=$((PASS+1)) ;; esac
"$SCRIPT" release --owner=B42 >/dev/null 2>&1

echo "=== T43 — le journal survit à la destruction de la génération (rm -rf) ET à un release ==="
rm -rf "$VF_DRIVER_LOCK" "$WORK_DIR"/DRIVER.lock.events.log
"$SCRIPT" acquire --owner=DEAD43 --step=x >/dev/null
age_stale "$VF_DRIVER_LOCK"
"$SCRIPT" takeover --owner=B43 --step=y >/dev/null   # rm -rf l'ancienne génération DEAD43
"$SCRIPT" release --owner=B43 >/dev/null 2>&1          # détruit aussi la génération courante
_t43_log="$WORK_DIR/DRIVER.lock.events.log"
if [ -f "$_t43_log" ]; then echo "  ✅ PASS — T43.1 — le journal existe encore (survit à rm -rf + release)"; PASS=$((PASS+1)); else echo "  ❌ FAIL — T43.1 — le journal existe encore"; FAIL=$((FAIL+1)); fi
_t43_n=$(wc -l < "$_t43_log" | tr -d ' ')
if [ "$_t43_n" -ge 1 ]; then echo "  ✅ PASS — T43.2 — le journal garde sa ligne (=$_t43_n)"; PASS=$((PASS+1)); else echo "  ❌ FAIL — T43.2 — le journal garde sa ligne"; FAIL=$((FAIL+1)); fi

echo "=== T44 — trois natures d'événement, trois lignes, jamais tronqué (append-only) ==="
rm -rf "$VF_DRIVER_LOCK" "$WORK_DIR"/DRIVER.lock.events.log
"$SCRIPT" acquire --owner=DEAD44 --step=x >/dev/null
age_stale "$VF_DRIVER_LOCK"
"$SCRIPT" takeover --owner=B44 --step=y >/dev/null
CLAUDE_CODE_SESSION_ID=sess44 "$SCRIPT" reclaim --owner=B44 >/dev/null
age_stale "$VF_DRIVER_LOCK"
"$SCRIPT" recover >/dev/null
_t44_log="$WORK_DIR/DRIVER.lock.events.log"
_t44_n=$(wc -l < "$_t44_log" | tr -d ' ')
num_eq "T44.1 — exactement 3 lignes" "$_t44_n" 3
_t44_l1=$(sed -n '1p' "$_t44_log"); _t44_l2=$(sed -n '2p' "$_t44_log"); _t44_l3=$(sed -n '3p' "$_t44_log")
assert "T44.2 — ligne 1 : takeover" "$_t44_l1" '"event": "takeover"'
assert "T44.3 — ligne 2 : reclaim" "$_t44_l2" '"event": "reclaim"'
assert "T44.4 — ligne 3 : recover" "$_t44_l3" '"event": "recover"'

echo "=== T45 — dégradation injectée : journal indisponible ne bloque JAMAIS le verrou ==="
rm -rf "$VF_DRIVER_LOCK"
_t45_log="$WORK_DIR/DRIVER.lock.events.log"
rm -f "$_t45_log"
"$SCRIPT" acquire --owner=DEAD45 --step=x >/dev/null
age_stale "$VF_DRIVER_LOCK"
# Panne injectée SUR LE FICHIER JOURNAL, pas sur le répertoire parent — vérifié empiriquement :
# rendre $LOCK_PARENT non inscriptible bloquerait AUSSI l'unlink du lock par drop_lock lui-même
# (supprimer une entrée de répertoire exige le droit d'écriture sur CE répertoire, quels que
# soient les droits de l'entrée elle-même), rendant "recover réussit quand même" structurellement
# impossible sous POSIX. Pré-créer le journal en lecture seule isole la panne au SEUL canal de
# journalisation, sans toucher à la capacité de drop_lock à élaguer le lock.
: > "$_t45_log"
chmod 444 "$_t45_log"
out=$("$SCRIPT" recover 2>"$WORK_DIR/t45.stderr"); rc=$?
assert "T45.1 — recovered true malgré le journal indisponible" "$out" '"recovered": true'
assert_exit "T45.2 — exit 0" "$rc" 0
if grep -q 'journal indisponible' "$WORK_DIR/t45.stderr"; then echo "  ✅ PASS — T45.3 — diagnostic émis sur stderr"; PASS=$((PASS+1)); else echo "  ❌ FAIL — T45.3 — diagnostic émis sur stderr"; FAIL=$((FAIL+1)); fi
chmod 644 "$_t45_log" 2>/dev/null
rm -f "$_t45_log" "$WORK_DIR/t45.stderr"

echo "=== T46 — takeover : la revalidation post-mutex sur l'ÂGE (pas seulement la génération) referme la fenêtre où le détenteur périmé redevient vivant pendant la reprise ==="
# Mécanisme provoqué (dérivé du code, pas deviné) : `takeover` lit âge + génération AVANT de poser
# son mutex de reprise, puis prépare `new_generation()` (2× git rev-parse, mkdir, écritures disque)
# — une fenêtre de plusieurs millisecondes s'ouvre entre cette première lecture et la
# re-vérification post-mutex. Si le détenteur PÉRIMÉ émet un heartbeat RÉEL pendant cette fenêtre,
# `heartbeat` réécrit `heartbeat_epoch` EN PLACE (rewrite_meta) SANS changer le nom de génération :
# la génération reste identique (le contrôle de génération seul NE VOIT RIEN passer), mais l'âge
# redevient frais. Seule la revalidation sur l'ÂGE ferme cette fenêtre — c'est elle, et seulement
# elle, qui doit refuser ici.
#
# Ce n'est PAS le patron T32 (24 concurrents sur le MÊME mutex, indépendant de l'âge) : il faut ici
# DEUX étages séquencés — un takeover en vol, puis un heartbeat réel du détenteur pendant sa
# fenêtre — pour provoquer la course précise que ce contrôle ferme.
#
# Déterminisme SANS sleep : le takeover est lancé en arrière-plan (&) ; l'appel heartbeat qui suit
# immédiatement, lui, est SYNCHRONE dans le process parent. Le coût de fork+exec d'un job
# d'arrière-plan (et le travail de new_generation avant le mutex) est structurellement plus lent
# qu'un appel synchrone unique — mesuré 55/55 sans un seul échec sur ce poste (deux harnais
# indépendants, 40 puis 15 essais, avant d'écrire ce cas). Aucune synchronisation temporelle n'est
# requise : c'est un ordonnancement de coût de travail, pas une chance de timing.
rm -rf "$VF_DRIVER_LOCK"
"$SCRIPT" acquire --owner=DEAD46 --step=x >/dev/null
age_stale "$VF_DRIVER_LOCK"
( "$SCRIPT" takeover --owner=C46 --step=y >"$WORK_DIR/t46.out" 2>/dev/null ) &
_t46_pid=$!
"$SCRIPT" heartbeat --owner=DEAD46 --step=x >/dev/null 2>&1
wait "$_t46_pid"
_t46_out="$(cat "$WORK_DIR/t46.out" 2>/dev/null)"
assert "T46.1 — takeover refusé (le détenteur a prouvé sa vie pendant la fenêtre)" "$_t46_out" '"acquired": false'
assert "T46.2 — refus nommé race-during-recovery, pas un autre motif" "$_t46_out" '"reason": "race-during-recovery"'
assert "T46.3 — le détenteur périmé reste EFFECTIVEMENT owner (aucun vol)" "$("$SCRIPT" status)" '"owner": "DEAD46"'
rm -f "$WORK_DIR/t46.out"
"$SCRIPT" release --owner=DEAD46 >/dev/null 2>&1

echo "=== T47 — BL-3 (correction juge #2) : mutex de recover libéré même si le process meurt juste après l'avoir pris (même patron que T41b) ==="
rm -rf "$VF_DRIVER_LOCK"
"$SCRIPT" acquire --owner=DEAD47 --step=x >/dev/null
age_stale "$VF_DRIVER_LOCK"
_t47_gen="$(readlink "$VF_DRIVER_LOCK")"
out=$(VF_DRIVER_TEST_DIE_AFTER_MUTEX=1 "$SCRIPT" recover); rc=$?
assert_exit "T47.1 — le process 'meurt' juste après avoir pris le mutex (exit 137)" "$rc" 137
_t47_mutex="${VF_DRIVER_LOCK}.rec.$(printf '%s' "$_t47_gen" | tr -c 'A-Za-z0-9._-' '_')"
if [ -L "$_t47_mutex" ]; then echo "  ❌ FAIL — T47.2 — le mutex a été libéré (trap)"; FAIL=$((FAIL+1)); else echo "  ✅ PASS — T47.2 — le mutex a été libéré (trap)"; PASS=$((PASS+1)); fi
# La mort injectée coupe AVANT drop_lock : le lock stale existe toujours, donc un takeover
# ULTÉRIEUR normal doit réussir (lock toujours reprenable, jamais bloqué en race-during-recovery
# pour toujours — c'est exactement le mode de défaillance que ce cas ferme).
out2=$("$SCRIPT" takeover --owner=B47 --step=y); rc2=$?
assert "T47.3 — un takeover ULTÉRIEUR normal réussit (lock toujours reprenable)" "$out2" '"acquired": true'
assert_exit "T47.4 — exit 0" "$rc2" 0
"$SCRIPT" release --owner=B47 >/dev/null 2>&1

echo "=== T48 — correction juge #3 : owner/step assainis À L'ÉCRITURE, le JSON reste PARSABLE avec guillemet/antislash/'=' injectés ==="
rm -rf "$VF_DRIVER_LOCK"
out=$("$SCRIPT" acquire --owner='mission"X\path=v' --step='etape"Y\z'); rc=$?
json_ok "$out"; assert_exit "T48.1 — la réponse JSON IMMÉDIATE de acquire reste parsable" $? 0
assert "T48.2 — owner assaini dans la réponse immédiate (guillemet/antislash retirés, '=' préservé)" "$out" '"owner": "missionXpath=v"'
_t48_status="$("$SCRIPT" status)"
json_ok "$_t48_status"; assert_exit "T48.3 — status reste parsable après relecture du meta sur disque" $? 0
assert "T48.4 — owner assaini AUSSI côté meta (relu par status, pas juste la réponse immédiate)" "$_t48_status" '"owner": "missionXpath=v"'
"$SCRIPT" release --owner='missionXpath=v' >/dev/null 2>&1

echo "=== T49 — correction juge #6 : guard_effective OBSERVABLE (session_ids vide vs peuplé, sans changer la règle 2) ==="
rm -rf "$VF_DRIVER_LOCK"
env -u CLAUDE_CODE_SESSION_ID "$SCRIPT" acquire --owner=A49 --step=x >/dev/null   # session_ids vide (T17)
_t49_status="$("$SCRIPT" status)"
assert "T49.1 — guard_effective:false quand session_ids est vide (lock INERTE pour le guard, jamais signalé ailleurs avant ce champ)" "$_t49_status" '"guard_effective": false'
"$SCRIPT" release --owner=A49 >/dev/null 2>&1
rm -rf "$VF_DRIVER_LOCK"
CLAUDE_CODE_SESSION_ID=sess49 "$SCRIPT" acquire --owner=A49b --step=x >/dev/null
_t49b_status="$("$SCRIPT" status)"
assert "T49.2 — guard_effective:true quand session_ids est peuplé (comportement nominal)" "$_t49b_status" '"guard_effective": true'
"$SCRIPT" release --owner=A49b >/dev/null 2>&1

echo "=== T50 — correction juge #7 : recover journalise new_owner/session_id QUAND ils sont connus, sans les EXIGER ==="
rm -rf "$VF_DRIVER_LOCK" "$WORK_DIR"/DRIVER.lock.events.log
"$SCRIPT" acquire --owner=DEAD50 --step=x >/dev/null
age_stale "$VF_DRIVER_LOCK"
CLAUDE_CODE_SESSION_ID=sess50 "$SCRIPT" recover --owner=B50 >/dev/null
_t50_line=$(tail -1 "$WORK_DIR/DRIVER.lock.events.log")
assert "T50.1 — event recover" "$_t50_line" '"event": "recover"'
assert "T50.2 — previous_owner DEAD50 (élagué)" "$_t50_line" '"previous_owner": "DEAD50"'
assert "T50.3 — new_owner B50 journalisé (connu, plus jamais perdu)" "$_t50_line" '"new_owner": "B50"'
assert "T50.4 — session_id sess50 journalisé (connu, plus jamais perdu)" "$_t50_line" '"session_id": "sess50"'
# Contre-épreuve : recover SANS --owner reste possible (élagage anonyme, comportement INCHANGÉ,
# T8/T44 ne doivent jamais rougir — l'exigence n'est PAS forcée, seulement journalisée si connue).
rm -rf "$VF_DRIVER_LOCK" "$WORK_DIR"/DRIVER.lock.events.log
"$SCRIPT" acquire --owner=DEAD50b --step=x >/dev/null
age_stale "$VF_DRIVER_LOCK"
out=$("$SCRIPT" recover); rc=$?
assert "T50.5 — recover SANS --owner réussit toujours (jamais forcé)" "$out" '"recovered": true'
assert_exit "T50.6 — exit 0" "$rc" 0

echo ""
echo "=================================="
echo "  Résultats : $PASS PASS / $FAIL FAIL"
echo "=================================="
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
