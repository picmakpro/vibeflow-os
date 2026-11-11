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
# T59-T66 registre des agents dispatchés (issue #82) : T59 register + orphans feuille -> racine ·
#     T60 close (done/failed/stopped, unknown-agent, invalid-status, enfants restants) · T61 reclaim
#     inventorie les orphelins · T62 takeover inventorie les orphelins du tenant mort · T63 release
#     garde le registre si enfants running, le supprime sinon, acquire suivant les signale ·
#     T64 sans registre : aucun verbe ne plante, compte 0 · T65 assainissement des champs (JSON
#     toujours parsable) · T66 append-only (une ligne par évènement, jamais de réécriture)
# T68 registre archivé au relâchement et verbe registry (P79-D-17) : archive, fenêtre de 24 h, plafond de 2 000 lignes, propriété
#     générative et mutants M-ARC-* · T69 plan de mission publié à côté du verrou (A16) : publish-plan, champ dag de status,
#     propriété générative et mutants M-PLAN-*
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

# Recule progress_epoch d'un lock existant d'un nombre de secondes donné, SANS toucher
# heartbeat_epoch ni acquired_epoch — c'est la seconde horloge additive (D-33-A) que le cas
# « vivant mais bouclant » (T57) doit pouvoir désynchroniser du battement. Même motif que
# age_stale/lease_backdate : les cas ne connaissent jamais le protocole interne du meta, seul ce
# helper l'édite.
progress_backdate() {
  local lock="$1" secs="$2" meta old
  if [ -L "$lock" ]; then
    meta="$(dirname "$lock")/$(readlink "$lock")/meta"
  else
    meta="$lock/meta"
  fi
  [ -f "$meta" ] || return 1
  old=$(( $(date +%s) - secs ))
  sed -i.bak "s/^progress_epoch=.*/progress_epoch=$old/" "$meta" && rm -f "${meta}.bak"
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
# 9 lignes depuis 33-01 (D-33-A) : le champ additif progress_epoch porte le total de 8 à 9 — même
# évolution que 32-01 avait fait passer de 7 à 8 avec session_ids. Aucune ligne injectée, le
# compte suit seulement la croissance légitime du schéma du meta.
num_eq "T19.1 — le meta garde exactement 9 lignes (une par clé, aucune injectée)" "$_t19_total" 9
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

echo "=== T51 — acquire pose progress_epoch (symétrie de départ avec heartbeat_epoch, D-33-A) ==="
rm -rf "$VF_DRIVER_LOCK"
"$SCRIPT" acquire --owner=A51 --step=t51 >/dev/null
st=$("$SCRIPT" status)
_t51_pe=$(printf '%s' "$st" | python3 -c 'import json,sys; print(json.load(sys.stdin)["progress_epoch"])')
case "$_t51_pe" in
  ''|*[!0-9]*) echo "  ❌ FAIL — T51.1 — progress_epoch numérique non nul"; echo "     obtenu: $_t51_pe"; FAIL=$((FAIL+1)) ;;
  *) echo "  ✅ PASS — T51.1 — progress_epoch numérique non nul (=$_t51_pe)"; PASS=$((PASS+1)) ;;
esac
_t51_page=$(printf '%s' "$st" | python3 -c 'import json,sys; print(json.load(sys.stdin)["progress_age_seconds"])')
if [ "$_t51_page" -lt 60 ] 2>/dev/null; then echo "  ✅ PASS — T51.2 — progress_age_seconds proche de 0 (<60)"; PASS=$((PASS+1)); else echo "  ❌ FAIL — T51.2 — progress_age_seconds proche de 0"; echo "     obtenu: $_t51_page"; FAIL=$((FAIL+1)); fi

echo "=== T52 — mark-progress avance progress_epoch, JSON ok/owner/progress_epoch ==="
out=$("$SCRIPT" mark-progress --owner=A51); rc=$?
assert "T52.1 — ok true" "$out" '"ok": true'
assert "T52.2 — owner A51" "$out" '"owner": "A51"'
assert_exit "T52.3 — exit 0" "$rc" 0
json_ok "$out"; assert_exit "T52.4 — JSON parsable" $? 0
st=$("$SCRIPT" status)
_t52_page=$(printf '%s' "$st" | python3 -c 'import json,sys; print(json.load(sys.stdin)["progress_age_seconds"])')
if [ "$_t52_page" -lt 60 ] 2>/dev/null; then echo "  ✅ PASS — T52.5 — progress_age_seconds proche de 0 après mark-progress"; PASS=$((PASS+1)); else echo "  ❌ FAIL — T52.5 — progress_age_seconds proche de 0"; echo "     obtenu: $_t52_page"; FAIL=$((FAIL+1)); fi
"$SCRIPT" release --owner=A51 >/dev/null 2>&1

echo "=== T53 — mark-progress préserve heartbeat_epoch/step/branch/worktree/acquired_epoch AU CARACTÈRE PRÈS (garde step obligatoire) ==="
rm -rf "$VF_DRIVER_LOCK"
"$SCRIPT" acquire --owner=A53 --step=etape-42 >/dev/null
_t53_gen="$(readlink "$VF_DRIVER_LOCK")"
_t53_meta="$(dirname "$VF_DRIVER_LOCK")/$_t53_gen/meta"
_t53_hb_before=$(grep '^heartbeat_epoch=' "$_t53_meta" | cut -d= -f2-)
_t53_step_before=$(grep '^step=' "$_t53_meta" | cut -d= -f2-)
_t53_branch_before=$(grep '^branch=' "$_t53_meta" | cut -d= -f2-)
_t53_worktree_before=$(grep '^worktree=' "$_t53_meta" | cut -d= -f2-)
_t53_acq_before=$(grep '^acquired_epoch=' "$_t53_meta" | cut -d= -f2-)
"$SCRIPT" mark-progress --owner=A53 >/dev/null
_t53_hb_after=$(grep '^heartbeat_epoch=' "$_t53_meta" | cut -d= -f2-)
_t53_step_after=$(grep '^step=' "$_t53_meta" | cut -d= -f2-)
_t53_branch_after=$(grep '^branch=' "$_t53_meta" | cut -d= -f2-)
_t53_worktree_after=$(grep '^worktree=' "$_t53_meta" | cut -d= -f2-)
_t53_acq_after=$(grep '^acquired_epoch=' "$_t53_meta" | cut -d= -f2-)
assert "T53.1 — heartbeat_epoch inchangé au caractère près" "$_t53_hb_after" "$_t53_hb_before"
assert "T53.2 — step préservé (=etape-42, garde meta_get step)" "$_t53_step_after" "etape-42"
assert "T53.3 — step inchangé au caractère près" "$_t53_step_after" "$_t53_step_before"
assert "T53.4 — branch inchangé au caractère près" "$_t53_branch_after" "$_t53_branch_before"
assert "T53.5 — worktree inchangé au caractère près" "$_t53_worktree_after" "$_t53_worktree_before"
assert "T53.6 — acquired_epoch inchangé au caractère près" "$_t53_acq_after" "$_t53_acq_before"
"$SCRIPT" release --owner=A53 >/dev/null 2>&1

echo "=== T54 — mark-progress owner mismatch refusé (not-owner), rien ne bouge ==="
rm -rf "$VF_DRIVER_LOCK"
"$SCRIPT" acquire --owner=A54 --step=t54 >/dev/null
_t54_gen="$(readlink "$VF_DRIVER_LOCK")"
_t54_meta="$(dirname "$VF_DRIVER_LOCK")/$_t54_gen/meta"
_t54_hb_before=$(grep '^heartbeat_epoch=' "$_t54_meta" | cut -d= -f2-)
_t54_pe_before=$(grep '^progress_epoch=' "$_t54_meta" | cut -d= -f2-)
_t54_step_before=$(grep '^step=' "$_t54_meta" | cut -d= -f2-)
out=$("$SCRIPT" mark-progress --owner=B54); rc=$?
assert "T54.1 — ok false" "$out" '"ok": false'
assert "T54.2 — reason not-owner" "$out" '"reason": "not-owner"'
assert "T54.3 — held_by A54" "$out" '"held_by": "A54"'
assert_exit "T54.4 — exit 1" "$rc" 1
_t54_hb_after=$(grep '^heartbeat_epoch=' "$_t54_meta" | cut -d= -f2-)
_t54_pe_after=$(grep '^progress_epoch=' "$_t54_meta" | cut -d= -f2-)
_t54_step_after=$(grep '^step=' "$_t54_meta" | cut -d= -f2-)
assert "T54.5 — heartbeat_epoch inchangé" "$_t54_hb_after" "$_t54_hb_before"
assert "T54.6 — progress_epoch inchangé" "$_t54_pe_after" "$_t54_pe_before"
assert "T54.7 — step inchangé" "$_t54_step_after" "$_t54_step_before"
"$SCRIPT" release --owner=A54 >/dev/null 2>&1

echo "=== T55 — mark-progress sans lock présent ==="
rm -rf "$VF_DRIVER_LOCK"
out=$("$SCRIPT" mark-progress --owner=X55); rc=$?
assert "T55.1 — ok false" "$out" '"ok": false'
assert "T55.2 — reason no-lock" "$out" '"reason": "no-lock"'
assert_exit "T55.3 — exit 1" "$rc" 1

echo "=== T56 — rétrocompatibilité : lock sans progress_epoch (lock d'un ancien script), aucun verbe ne plante ==="
rm -rf "$VF_DRIVER_LOCK"
"$SCRIPT" acquire --owner=A56 --step=t56 >/dev/null
meta_drop_key "$VF_DRIVER_LOCK" progress_epoch
_t56_gen="$(readlink "$VF_DRIVER_LOCK")"
_t56_meta="$(dirname "$VF_DRIVER_LOCK")/$_t56_gen/meta"
_t56_n=$(grep -c '^progress_epoch=' "$_t56_meta")
num_eq "T56.0 — contrôle positif : la ligne progress_epoch= est réellement absente" "$_t56_n" 0
st=$("$SCRIPT" status); rc_status=$?
assert_exit "T56.1 — status exit 0 sur lock rétrocompat" "$rc_status" 0
assert "T56.2 — progress_epoch null" "$st" '"progress_epoch": null'
assert "T56.3 — progress_age_seconds null" "$st" '"progress_age_seconds": null'
out_hb=$("$SCRIPT" heartbeat --owner=A56); rc_hb=$?
assert_exit "T56.4 — heartbeat exit 0 sur lock rétrocompat" "$rc_hb" 0
out_mp=$("$SCRIPT" mark-progress --owner=A56); rc_mp=$?
assert_exit "T56.5 — mark-progress exit 0 sur lock rétrocompat" "$rc_mp" 0
"$SCRIPT" release --owner=A56 >/dev/null 2>&1

echo "=== T57 — cas « vivant mais bouclant » : heartbeat frais, progrès figé, observable en un seul appel status (critère de succès n°2) ==="
rm -rf "$VF_DRIVER_LOCK"
"$SCRIPT" acquire --owner=A57 --step=t57 >/dev/null
progress_backdate "$VF_DRIVER_LOCK" 9000
"$SCRIPT" heartbeat --owner=A57 >/dev/null
st=$("$SCRIPT" status)
_t57_age=$(printf '%s' "$st" | python3 -c 'import json,sys; print(json.load(sys.stdin)["age_seconds"])')
_t57_page=$(printf '%s' "$st" | python3 -c 'import json,sys; print(json.load(sys.stdin)["progress_age_seconds"])')
if [ "$_t57_age" -lt 60 ]; then echo "  ✅ PASS — T57.1 — age_seconds < 60 (heartbeat frais)"; PASS=$((PASS+1)); else echo "  ❌ FAIL — T57.1 — age_seconds < 60"; echo "     obtenu: $_t57_age"; FAIL=$((FAIL+1)); fi
if [ "$_t57_page" -ge 9000 ] 2>/dev/null; then echo "  ✅ PASS — T57.2 — progress_age_seconds >= 9000 (progrès figé)"; PASS=$((PASS+1)); else echo "  ❌ FAIL — T57.2 — progress_age_seconds >= 9000"; echo "     obtenu: $_t57_page"; FAIL=$((FAIL+1)); fi
"$SCRIPT" release --owner=A57 >/dev/null 2>&1

echo "=== T58 — heartbeat préserve progress_epoch inchangé (même propriété que T16 pour session_ids) ==="
rm -rf "$VF_DRIVER_LOCK"
"$SCRIPT" acquire --owner=A58 --step=t58 >/dev/null
_t58_gen="$(readlink "$VF_DRIVER_LOCK")"
_t58_meta="$(dirname "$VF_DRIVER_LOCK")/$_t58_gen/meta"
_t58_pe_before=$(grep '^progress_epoch=' "$_t58_meta" | cut -d= -f2-)
"$SCRIPT" heartbeat --owner=A58 >/dev/null
_t58_pe_after=$(grep '^progress_epoch=' "$_t58_meta" | cut -d= -f2-)
assert "T58.1 — progress_epoch inchangé après heartbeat" "$_t58_pe_after" "$_t58_pe_before"
"$SCRIPT" release --owner=A58 >/dev/null 2>&1

# ---------------------------------------------------------------------------------------------------
# T59-T66 : registre des agents dispatchés (issue #82). Le registre vit à côté du lock
# (<lock>.children.jsonl) ; les cas ne connaissent jamais sa forme interne, sauf T66 qui teste
# précisément la propriété append-only (une ligne par évènement).
# ---------------------------------------------------------------------------------------------------
REG_FILE="$VF_DRIVER_LOCK.children.jsonl"
json_field() { printf '%s' "$1" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d'"$2"')' 2>/dev/null; }

echo "=== T59, register + orphans : inventaire feuille -> racine, statut consigné ==="
rm -rf "$VF_DRIVER_LOCK" "$REG_FILE"
out=$("$SCRIPT" orphans); rc=$?
assert "T59.1, orphans sans registre : present false, count 0" "$out" '"present": false, "registry": "'"$REG_FILE"'", "count": 0, "orphans": []'
assert_exit "T59.2, orphans sans registre : exit 0 (inventaire, pas un verdict)" "$rc" 0
"$SCRIPT" acquire --owner=M59 --step=exec-A >/dev/null
out=$("$SCRIPT" register --agent=ag-coder --role=vf-coder --node=exec-A); rc=$?
assert "T59.3, register rend registered true + agent_id + owner relevé sur le lock" "$out" '"registered": true, "agent_id": "ag-coder", "role": "vf-coder", "node": "exec-A", "parent": "", "owner": "M59"'
assert_exit "T59.4, register exit 0" "$rc" 0
"$SCRIPT" register --agent=ag-planner --role=gsd-planner --node=exec-A --parent=ag-coder >/dev/null
"$SCRIPT" register --agent=ag-reviewer --role=vf-reviewer --node=revue-A >/dev/null
out=$("$SCRIPT" register --agent= --role=x); rc=$?
assert "T59.5, register sans --agent refusé" "$out" '"reason": "agent-required"'
assert_exit "T59.6, register sans --agent : exit 1" "$rc" 1
out=$("$SCRIPT" register --agent=ag-x); rc=$?
assert "T59.7, register sans --role refusé" "$out" '"reason": "role-required"'
out=$("$SCRIPT" orphans); rc=$?
json_ok "$out"; assert_exit "T59.8, orphans : JSON parsable" $? 0
assert "T59.9, orphans : count 3" "$out" '"count": 3'
_t59_first=$(json_field "$out" '["orphans"][0]["agent_id"]')
_t59_depth=$(json_field "$out" '["orphans"][0]["depth"]')
_t59_last=$(json_field "$out" '["orphans"][2]["depth"]')
assert "T59.10, la FEUILLE (enfant du worker) vient en premier" "$_t59_first" 'ag-planner'
assert "T59.11, profondeur dérivée de la chaîne parent = 2" "$_t59_depth" '2'
assert "T59.12, les racines (profondeur 1) viennent en dernier" "$_t59_last" '1'
assert "T59.13, chaque entrée porte owner, generation, dispatched_at, status running" "$out" '"owner": "M59", "generation": "DRIVER.lock.gen.'
st=$("$SCRIPT" status)
assert "T59.14, status expose children_running = 3" "$st" '"children_running": 3'
out=$("$SCRIPT" register --agent=ag-deep --role=gsd-plan-checker --node=exec-A --depth=3); rc=$?
_t59_deep=$(json_field "$("$SCRIPT" orphans)" '["orphans"][0]["depth"]')
assert "T59.15, --depth explicite prime sur la dérivation et remonte en tête" "$_t59_deep" '3'

echo "=== T60, close : done/failed/stopped par append, refus sur inconnu et statut invalide ==="
out=$("$SCRIPT" close --agent=ag-coder --status=done); rc=$?
assert "T60.1, close done : closed true, previous_status running" "$out" '"closed": true, "agent_id": "ag-coder", "status": "done", "previous_status": "running"'
assert "T60.2, close d'un parent nomme ses enfants encore running" "$out" '"children_running": ["ag-planner"]'
assert_exit "T60.3, close exit 0" "$rc" 0
out=$("$SCRIPT" orphans)
assert "T60.4, l'agent fermé sort de l'inventaire (count 3)" "$out" '"count": 3'
case "$out" in *'"agent_id": "ag-coder"'*) echo "  ❌ FAIL : T60.5 : ag-coder encore listé après close"; FAIL=$((FAIL+1));; *) echo "  ✅ PASS : T60.5 : ag-coder absent de l'inventaire après close"; PASS=$((PASS+1));; esac
out=$("$SCRIPT" close --agent=ag-inconnu --status=done); rc=$?
assert "T60.6, close d'un agent jamais consigné refusé (unknown-agent)" "$out" '"reason": "unknown-agent"'
assert_exit "T60.7, unknown-agent : exit 1" "$rc" 1
out=$("$SCRIPT" close --agent=ag-planner --status=killed); rc=$?
assert "T60.8, statut hors done|failed|stopped refusé" "$out" '"reason": "invalid-status"'
assert_exit "T60.9, invalid-status : exit 1" "$rc" 1
out=$("$SCRIPT" close --agent=ag-planner --status=stopped)
assert "T60.10, close stopped accepté" "$out" '"closed": true, "agent_id": "ag-planner", "status": "stopped"'
out=$("$SCRIPT" close --agent=ag-planner --status=failed)
assert "T60.11, re-close idempotent : previous_status = stopped, jamais une erreur" "$out" '"previous_status": "stopped"'
st=$("$SCRIPT" status)
assert "T60.12, status children_running retombe à 2 (reviewer + deep)" "$st" '"children_running": 2'

echo "=== T61, reclaim inventorie les orphelins consignés sous le lock (feuille -> racine) ==="
out=$(CLAUDE_CODE_SESSION_ID=sess-t61 "$SCRIPT" reclaim --owner=M59); rc=$?
assert "T61.1, reclaim rend orphans_count 2" "$out" '"orphans_count": 2'
assert "T61.2, reclaim rend la liste des ids, profondeur décroissante" "$out" '"orphans": ["ag-deep", "ag-reviewer"]'
assert_exit "T61.3, reclaim exit 0" "$rc" 0
json_ok "$out"; assert_exit "T61.4, JSON de reclaim parsable avec le registre" $? 0

echo "=== T62, takeover d'un lock périmé inventorie les orphelins du tenant mort ==="
age_stale "$VF_DRIVER_LOCK"
out=$("$SCRIPT" takeover --owner=M62 --step=exec-A); rc=$?
assert "T62.1, takeover acquired true" "$out" '"acquired": true'
assert "T62.2, takeover rend orphans_count 2 (registre survit au remplacement de génération)" "$out" '"orphans_count": 2, "orphans": ["ag-deep", "ag-reviewer"]'
out=$("$SCRIPT" orphans)
assert "T62.3, les entrées portent encore l'owner du tenant mort (M59)" "$out" '"owner": "M59"'
_t62_present=$([ -f "$REG_FILE" ] && echo yes || echo no)
assert "T62.4, le registre n'est PAS dans la génération : il survit au takeover" "$_t62_present" 'yes'

echo "=== T63, release : registre conservé si enfants running, supprimé sinon ; acquire suivant les signale ==="
out=$("$SCRIPT" release --owner=M62); rc=$?
assert "T63.1, release relâche QUAND MÊME (RAII) et compte les enfants" "$out" '"released": true, "owner": "M62", "children_running": 2, "orphans": ["ag-deep", "ag-reviewer"]'
assert_exit "T63.2, release exit 0 malgré les orphelins" "$rc" 0
_t63_present=$([ -f "$REG_FILE" ] && echo yes || echo no)
assert "T63.3, registre conservé après un release avec enfants ouverts" "$_t63_present" 'yes'
st=$("$SCRIPT" status)
assert "T63.4, status lock absent expose children_running 2 (le gate de sortie le lit)" "$st" '"present": false, "lock": "'"$VF_DRIVER_LOCK"'", "children_running": 2'
out=$("$SCRIPT" acquire --owner=M63 --step=exec-B); rc=$?
assert "T63.5, l'acquisition suivante signale les orphelins hérités" "$out" '"orphans_count": 2, "orphans": ["ag-deep", "ag-reviewer"]'
"$SCRIPT" close --agent=ag-deep --status=stopped >/dev/null
"$SCRIPT" close --agent=ag-reviewer --status=stopped >/dev/null
out=$("$SCRIPT" release --owner=M63)
assert "T63.6, release sans enfant running : children_running 0" "$out" '"released": true, "owner": "M63", "children_running": 0}'
_t63_gone=$([ -f "$REG_FILE" ] && echo yes || echo no)
assert "T63.7, registre supprimé par un release propre" "$_t63_gone" 'no'
# T63.8 à T63.12 (P79-D-17) : le release propre verse le registre dans l'archive frère, qui survit au relâchement.
ARC_FILE="$VF_DRIVER_LOCK.children.closed.jsonl"
regq() { printf '%s' "$1" | python3 -c 'import json,sys; d=json.load(sys.stdin); a=[x for x in d["agents"] if x["agent_id"]==sys.argv[1]]; print(a[0][sys.argv[2]] if a else "")' "$2" "$3" 2>/dev/null; }
regn() { printf '%s' "$1" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(len([x for x in d["agents"] if x["agent_id"]==sys.argv[1]]))' "$2" 2>/dev/null; }
_t63_arc=$([ -f "$ARC_FILE" ] && echo yes || echo no)
assert "T63.8, l'archive frère du registre existe après le release propre" "$_t63_arc" 'yes'
out=$("$SCRIPT" registry 2>/dev/null); rc=$?
json_ok "$out"; assert_exit "T63.9, registry rend un JSON valide (parse réel)" $? 0
assert_exit "T63.9b, registry : exit 0" "$rc" 0
assert "T63.9c, registry : present true" "$out" '"present": true'
assert "T63.10a, count 4 (un agent par identifiant)" "$out" '"count": 4'
assert "T63.10b, ag-reviewer : nœud revue-A" "$(regq "$out" ag-reviewer node)" 'revue-A'
assert "T63.10c, ag-reviewer : statut stopped" "$(regq "$out" ag-reviewer status)" 'stopped'
assert "T63.10d, ag-planner : rôle gsd-planner" "$(regq "$out" ag-planner role)" 'gsd-planner'
assert "T63.10e, ag-planner : parent ag-coder" "$(regq "$out" ag-planner parent)" 'ag-coder'
assert "T63.10f, ag-planner : statut failed (dernière ligne gagne)" "$(regq "$out" ag-planner status)" 'failed'
assert "T63.10g, ag-coder : statut done" "$(regq "$out" ag-coder status)" 'done'
assert "T63.10h, ag-deep : statut stopped" "$(regq "$out" ag-deep status)" 'stopped'
_t63_sum1="$(cksum < "$ARC_FILE" 2>/dev/null)"; _t63_ls1="$(ls -A "$(dirname "$VF_DRIVER_LOCK")" 2>/dev/null)"
"$SCRIPT" registry >/dev/null 2>&1; out2=$("$SCRIPT" registry 2>/dev/null)
_t63_sum2="$(cksum < "$ARC_FILE" 2>/dev/null)"; _t63_ls2="$(ls -A "$(dirname "$VF_DRIVER_LOCK")" 2>/dev/null)"
assert "T63.11a, lecture seule : somme de contrôle de l'archive inchangée" "$_t63_sum2" "$_t63_sum1"
assert "T63.11b, lecture seule : liste du dossier du verrou inchangée" "$_t63_ls2" "$_t63_ls1"
assert "T63.11c, orphans : present false" "$("$SCRIPT" orphans)" '"present": false'
assert "T63.11d, orphans : count 0" "$("$SCRIPT" orphans)" '"count": 0'
case "$out2" in *"$WORK_DIR"*) echo "  ❌ FAIL — T63.11e, registry ne porte aucun chemin du poste"; FAIL=$((FAIL+1)) ;; *) if [ -n "$out2" ]; then echo "  ✅ PASS — T63.11e, registry ne porte aucun chemin du poste"; PASS=$((PASS+1)); else echo "  ❌ FAIL — T63.11e, registry ne porte aucun chemin du poste (sortie vide)"; FAIL=$((FAIL+1)); fi ;; esac
# T63.12 : un dossier occupe le nom de l'archive (échec d'écriture sur tout utilisateur) : le release relâche quand même.
rm -f "$ARC_FILE"; mkdir -p "$ARC_FILE"
"$SCRIPT" acquire --owner=M63c --step=exec-C >/dev/null
"$SCRIPT" register --agent=ag-t12 --role=vf-coder --node=exec-C >/dev/null
"$SCRIPT" close --agent=ag-t12 --status=done >/dev/null
out=$("$SCRIPT" release --owner=M63c 2>"$WORK_DIR/t63-12.err"); rc=$?
assert "T63.12a, archive non écrivable : le release relâche quand même" "$out" '"released": true'
assert_exit "T63.12b, archive non écrivable : exit 0" "$rc" 0
_t63_cur=$([ -f "$REG_FILE" ] && awk 'END { print NR }' "$REG_FILE" || echo absent)
assert "T63.12c, le registre courant est conservé avec ses 2 lignes" "$_t63_cur" '2'
_t63_dir=$([ -d "$ARC_FILE" ] && [ -z "$(ls -A "$ARC_FILE")" ] && echo intact || echo touche)
assert "T63.12d, l'archive (le dossier) est intacte" "$_t63_dir" 'intact'
assert "T63.12e, stderr dit « registre non archivé »" "$(cat "$WORK_DIR/t63-12.err")" 'registre non archivé'
rm -rf "$ARC_FILE" "$REG_FILE" "$WORK_DIR/t63-12.err"

echo "=== T64, sans registre : aucun verbe ne plante, compte 0 partout ==="
rm -rf "$VF_DRIVER_LOCK" "$REG_FILE"
out=$(CLAUDE_CODE_SESSION_ID=sess-t64 "$SCRIPT" acquire --owner=M64 --step=x)
assert "T64.1, acquire sans registre : orphans_count 0, orphans []" "$out" '"orphans_count": 0, "orphans": []'
out=$(CLAUDE_CODE_SESSION_ID=sess-t64b "$SCRIPT" reclaim --owner=M64)
assert "T64.2, reclaim sans registre : orphans_count 0" "$out" '"reclaimed": true'
assert "T64.3, reclaim sans registre : orphans []" "$out" '"orphans_count": 0, "orphans": []'
out=$("$SCRIPT" close --agent=ag-x --status=done); rc=$?
assert "T64.4, close sans registre : no-registry" "$out" '"reason": "no-registry"'
assert_exit "T64.5, close sans registre : exit 1" "$rc" 1
st=$("$SCRIPT" status)
assert "T64.6, status sans registre : children_running 0" "$st" '"children_running": 0'
age_stale "$VF_DRIVER_LOCK"
out=$("$SCRIPT" takeover --owner=M64b --step=x)
assert "T64.7, takeover sans registre : orphans_count 0" "$out" '"orphans_count": 0, "orphans": []'
"$SCRIPT" release --owner=M64b >/dev/null 2>&1

echo "=== T65, assainissement des champs du registre : JSON toujours parsable ==="
rm -rf "$VF_DRIVER_LOCK" "$REG_FILE"
"$SCRIPT" acquire --owner=M65 --step=x >/dev/null
out=$("$SCRIPT" register --agent='ag"65,x' --role='vf"coder\' --node='exec"A'); rc=$?
json_ok "$out"; assert_exit "T65.1, register avec guillemets/virgule/antislash : JSON parsable" $? 0
assert "T65.2, agent_id réduit à sa classe d'identifiant" "$out" '"agent_id": "ag65x"'
assert "T65.3, role/node sans guillemet ni antislash" "$out" '"role": "vfcoder", "node": "execA"'
out=$("$SCRIPT" orphans)
json_ok "$out"; assert_exit "T65.4, orphans après champs hostiles : JSON parsable" $? 0
out=$("$SCRIPT" register --agent=ag-tab --role="$(printf 'vf\tcoder')" --node=n)
out=$("$SCRIPT" orphans)
json_ok "$out"; assert_exit "T65.5, tabulation dans un champ : JSON parsable, fold intact" $? 0
assert "T65.6, la tabulation est retirée du champ" "$out" '"role": "vfcoder", "node": "n"'
"$SCRIPT" close --agent=ag65x --status=done >/dev/null; "$SCRIPT" close --agent=ag-tab --status=done >/dev/null
"$SCRIPT" release --owner=M65 >/dev/null 2>&1

echo "=== T66, append-only : une ligne par évènement, jamais de réécriture ==="
rm -rf "$VF_DRIVER_LOCK" "$REG_FILE"
"$SCRIPT" acquire --owner=M66 --step=x >/dev/null
"$SCRIPT" register --agent=ag-a --role=vf-coder --node=n >/dev/null
"$SCRIPT" register --agent=ag-b --role=vf-reviewer --node=n >/dev/null
"$SCRIPT" close --agent=ag-a --status=done >/dev/null
_t66_lines=$(awk 'END { print NR }' "$REG_FILE")
assert "T66.1, 2 register + 1 close = 3 lignes" "$_t66_lines" '3'
_t66_first=$(head -1 "$REG_FILE")
assert "T66.2, la première ligne (register ag-a) est intacte après le close" "$_t66_first" '"event": "register", "agent_id": "ag-a"'
_t66_valid=0
while IFS= read -r _l; do printf '%s' "$_l" | python3 -c 'import json,sys; json.load(sys.stdin)' 2>/dev/null || _t66_valid=1; done < "$REG_FILE"
assert_exit "T66.3, chaque ligne du registre est un JSON valide" "$_t66_valid" 0
out=$("$SCRIPT" orphans)
assert "T66.4, repli : dernière ligne par agent gagne (ag-a fermé, ag-b running)" "$out" '"count": 1'
assert "T66.5, ag-b seul dans l'inventaire" "$out" '"agent_id": "ag-b"'
"$SCRIPT" close --agent=ag-b --status=done >/dev/null
"$SCRIPT" release --owner=M66 >/dev/null 2>&1

echo "=== T67, outillage uutils coreutils : -h vaut --help (aide sur stdout, rc 0, rien fait) ==="
# Hypothèse SIMULÉE (aucun uutils réel n'est disponible dans cette suite) : des faux `ln` et `mv`, posés en
# tête d'un PATH temporaire, traitent toute option contenant `h` comme --help (aide, rc 0, aucun effet) ;
# `mv` comprend en plus -T : il le délègue au vrai mv avec l'option qui réalise -T SUR CET OS, sondée une fois
# ci-dessous (-T sous GNU/uutils, -h sous BSD/macOS) sans rien supposer — la suite rend le même verdict partout.
# Tout le reste est délégué au vrai binaire, résolu par chemin absolu AVANT de modifier le PATH. Sur le code
# où `ln -sh`/`mv -h` passaient en premier, le repli `||` ne jouait jamais : le second propriétaire recevait
# "acquired": true, et la reprise d'un lock périmé ne remplaçait pas le lien.
_t67_ln="$(command -v ln)"; _t67_mv="$(command -v mv)"
_t67_tflag=""; _t67_p="$WORK_DIR/probe67"; mkdir -p "$_t67_p/cible"
for _t67_o in T h; do   # première option qui remplace le lien SANS enterrer la source dans sa cible
  rm -rf "$_t67_p/l" "$_t67_p/f" "$_t67_p/cible/f"; : > "$_t67_p/f"; ln -s cible "$_t67_p/l"
  "$_t67_mv" "-$_t67_o" "$_t67_p/f" "$_t67_p/l" >/dev/null 2>&1
  if [ -f "$_t67_p/l" ] && [ ! -L "$_t67_p/l" ] && [ ! -e "$_t67_p/cible/f" ]; then _t67_tflag="$_t67_o"; break; fi
done
[ -n "$_t67_tflag" ]; assert_exit "T67.0, sonde : une option de mv (T ou h) réalise -T sur cet OS (obtenu : '$_t67_tflag')" "$?" 0
_t67_bin="$WORK_DIR/fakebin67"; mkdir -p "$_t67_bin"
cat > "$_t67_bin/ln" <<FAKE
#!/bin/sh
case "\$1" in -*h*) echo "Usage: ln [OPTION]... TARGET LINK_NAME (faux uutils)"; exit 0 ;; esac
exec "$_t67_ln" "\$@"
FAKE
cat > "$_t67_bin/mv" <<FAKE
#!/bin/sh
case "\$1" in
  -*h*) echo "Usage: mv [OPTION]... SOURCE DEST (faux uutils)"; exit 0 ;;
  -*T*) o="\$1"; shift; exec "$_t67_mv" "\$(printf '%s' "\$o" | tr T $_t67_tflag)" "\$@" ;;
esac
exec "$_t67_mv" "\$@"
FAKE
chmod +x "$_t67_bin/ln" "$_t67_bin/mv"
_t67_binmv="$WORK_DIR/fakebin67mv"; mkdir -p "$_t67_binmv"; cp "$_t67_bin/mv" "$_t67_binmv/mv"  # mv seul : isole mv_link/mv_noclobber de ln_atomic
rm -rf "$VF_DRIVER_LOCK"
PATH="$_t67_bin:$PATH" "$SCRIPT" acquire --owner=A67 --step=x >/dev/null 2>&1
out=$(PATH="$_t67_bin:$PATH" "$SCRIPT" acquire --owner=B67 --step=y 2>&1); rc=$?
assert "T67.1, ln qui prend -h pour --help : le second propriétaire est refusé" "$out" '"acquired": false'
assert_exit "T67.2, refus : exit 1" "$rc" 1
assert "T67.3, le verrou reste à A67" "$("$SCRIPT" status)" '"owner": "A67"'
rm -rf "$VF_DRIVER_LOCK"
"$SCRIPT" acquire --owner=DEAD67 --step=x >/dev/null
age_stale "$VF_DRIVER_LOCK"
out=$(PATH="$_t67_binmv:$PATH" "$SCRIPT" takeover --owner=B67 --step=y 2>&1); rc=$?
assert "T67.4, mv qui prend -h pour --help : la reprise d'un lock périmé aboutit" "$out" '"acquired": true'
assert "T67.5, le lien a réellement été remplacé (status = B67)" "$("$SCRIPT" status)" '"owner": "B67"'
"$SCRIPT" release --owner=B67 >/dev/null 2>&1
rm -rf "$VF_DRIVER_LOCK"
# mv_noclobber (restitution d'un dossier réel pendant une reprise, chemin ws) : la fonction est extraite du script et
# jouée seule, avec le faux mv — le chemin réel exige une course entre la sonde et la pose, injouable ici. Les cas
# WS-TKR/TKV/TKP de test-driver-lock-ws.sh couvrent le chemin complet.
eval "$(sed -n '/^mv_noclobber() {/,/^}/p' "$SCRIPT")"
_t67_d="$WORK_DIR/nc67"; rm -rf "$_t67_d"; mkdir -p "$_t67_d/src" "$_t67_d/autre"; echo s > "$_t67_d/src/f"
( PATH="$_t67_binmv:$PATH"; mv_noclobber "$_t67_d/src" "$_t67_d/dst" )
[ -f "$_t67_d/dst/f" ] && [ ! -e "$_t67_d/src" ]; assert_exit "T67.6, mv qui prend -h pour --help : mv_noclobber déplace vers un nom libre" "$?" 0
mkdir -p "$_t67_d/src2"; echo s2 > "$_t67_d/src2/f"; ln -s autre "$_t67_d/lien"
( PATH="$_t67_binmv:$PATH"; mv_noclobber "$_t67_d/src2" "$_t67_d/lien" )
[ -f "$_t67_d/src2/f" ] && [ ! -e "$_t67_d/autre/src2" ] && [ -L "$_t67_d/lien" ]; assert_exit "T67.7, nom pris par un lien vers un dossier : rien écrasé, rien enterré dans la cible" "$?" 0
# Aucun texte de mv ne pollue la sortie du script (JSON) et un déplacement qui n'a rien fait n'est pas un succès :
# -T échoue vraiment (destination dans un dossier absent) et le repli -h imprimerait l'aide du faux mv, rc 0.
eval "$(sed -n '/^mv_link() {/,/^}/p' "$SCRIPT")"
echo s > "$_t67_d/s8"
out=$(PATH="$_t67_binmv:$PATH"; mv_link "$_t67_d/s8" "$_t67_d/absent/dst"); rc=$?
[ -z "$out" ]; assert_exit "T67.8, mv_link : aucune sortie parasite quand le déplacement échoue" "$?" 0
[ "$rc" -ne 0 ]; assert_exit "T67.9, mv_link qui n'a rien déplacé ne rend pas 0 (rc=$rc)" "$?" 0
out=$(PATH="$_t67_binmv:$PATH"; mv_link "$_t67_d/inexistant" "$_t67_d/dst"); rc=$?
[ -z "$out" ] && [ "$rc" -ne 0 ]; assert_exit "T67.9b, mv_link sur une source absente : ni sortie ni succès (rc=$rc)" "$?" 0
out=$(PATH="$_t67_binmv:$PATH"; mv_noclobber "$_t67_d/s8" "$_t67_d/absent/dst"); rc=$?
[ -z "$out" ]; assert_exit "T67.10, mv_noclobber : aucune sortie parasite quand le déplacement échoue" "$?" 0
rm -rf "$_t67_d"
rm -rf "$_t67_bin" "$_t67_binmv"

# ---------------------------------------------------------------------------------------------------
# T68 : registre archivé au relâchement et verbe registry (P79-D-17). T68.1 à T68.4 ; la rétention et les
# mutants viennent à la tâche suivante du plan.
# ---------------------------------------------------------------------------------------------------
echo "=== T68, archive du registre : lecture par registry (le courant prime, orphelin non versé, dix clés) ==="
rm -rf "$VF_DRIVER_LOCK" "$REG_FILE" "$ARC_FILE"
out=$("$SCRIPT" registry 2>/dev/null); rc=$?
assert "T68.1a, sans registre ni archive : present false" "$out" '"present": false'
assert "T68.1b, sans registre ni archive : count 0" "$out" '"count": 0'
assert "T68.1c, sans registre ni archive : agents []" "$out" '"agents": []'
assert_exit "T68.1d, sans registre ni archive : exit 0" "$rc" 0
"$SCRIPT" acquire --owner=M68 --step=exec-A >/dev/null
"$SCRIPT" register --agent=ag-x --role=vf-coder --node=n-old >/dev/null
"$SCRIPT" close --agent=ag-x --status=done >/dev/null
"$SCRIPT" release --owner=M68 >/dev/null 2>&1
"$SCRIPT" acquire --owner=M68b --step=exec-B >/dev/null
"$SCRIPT" register --agent=ag-x --role=vf-coder --node=n-new >/dev/null
out=$("$SCRIPT" registry 2>/dev/null)
assert "T68.2a, ag-x ré-enregistré : rendu une seule fois" "$(regn "$out" ag-x)" '1'
assert "T68.2b, ag-x : statut running (le courant prime sur l'archive)" "$(regq "$out" ag-x status)" 'running'
assert "T68.2c, ag-x : le nœud neuf" "$(regq "$out" ag-x node)" 'n-new'
_t68_sum1="$(cksum < "$ARC_FILE" 2>/dev/null)"
"$SCRIPT" release --owner=M68b >/dev/null 2>&1
_t68_sum2="$(cksum < "$ARC_FILE" 2>/dev/null)"
assert "T68.3a, release avec un enfant running : l'archive n'est pas touchée" "$_t68_sum2" "$_t68_sum1"
_t68_cur=$([ -f "$REG_FILE" ] && echo yes || echo no)
assert "T68.3b, release avec un enfant running : le registre courant est gardé" "$_t68_cur" 'yes'
out=$("$SCRIPT" registry 2>/dev/null)
assert "T68.3c, registry rend encore cet enfant, running" "$(regq "$out" ag-x status)" 'running'
_t68_bad=$(printf '%s' "$out" | python3 -c 'import json,sys; d=json.load(sys.stdin); k=sorted(["agent_id","parent","role","node","owner","generation","dispatched_at","epoch","depth","status"]); print(len([a for a in d["agents"] if sorted(a.keys())!=k]) + (0 if d["agents"] else 1))' 2>/dev/null)
assert "T68.4a, chaque entrée porte exactement les dix clés" "$_t68_bad" '0'
for _t68_k in doing mandat messages outils fil; do
  case "$out" in *"\"$_t68_k\""*) echo "  ❌ FAIL — T68.4b, clé refusée « $_t68_k » dans la sortie"; FAIL=$((FAIL+1)) ;; *) if [ -n "$out" ]; then echo "  ✅ PASS — T68.4b, clé refusée « $_t68_k » absente"; PASS=$((PASS+1)); else echo "  ❌ FAIL — T68.4b, clé « $_t68_k » : sortie vide"; FAIL=$((FAIL+1)); fi ;; esac
done
"$SCRIPT" acquire --owner=M68c --step=exec-C >/dev/null
"$SCRIPT" close --agent=ag-x --status=done >/dev/null
"$SCRIPT" release --owner=M68c >/dev/null 2>&1
# Ligne d'archive falsifiée : dérivée d'une ligne réelle (aide python), jamais écrite à la main.
head -1 "$ARC_FILE" | python3 -c 'import sys,re; l=sys.stdin.readline().rstrip("\n"); l=l.replace("\"agent_id\": \"ag-x\"","\"agent_id\": \"ag-forged\""); l=re.sub(r"\"role\": \"[^\"]*\"", lambda m: "\"role\": \"ev\\\"il\\\\z\"", l); print(l)' >> "$ARC_FILE" 2>/dev/null
out=$("$SCRIPT" registry 2>/dev/null)
json_ok "$out"; assert_exit "T68.4c, archive falsifiée : registry reste un JSON valide" $? 0
_t68_role="$(regq "$out" ag-forged role)"
case "$_t68_role" in *'"'*|*'\'*|'') echo "  ❌ FAIL — T68.4d, valeur de role réduite (obtenu : '$_t68_role')"; FAIL=$((FAIL+1)) ;; *) echo "  ✅ PASS — T68.4d, valeur de role réduite"; PASS=$((PASS+1)) ;; esac
rm -rf "$VF_DRIVER_LOCK" "$REG_FILE" "$ARC_FILE"

# ---------------------------------------------------------------------------------------------------
# T68.5 à T68.10, T68.G, T68.M : rétention du registre archivé (24 h, 2 000 lignes), propriété générative et mutants
# (P79-D-17). Aucune édition à la main du format dans les cas : l'antidatage passe par un aide, les lignes volumineuses
# sont dérivées d'une ligne `register` réelle.
# ---------------------------------------------------------------------------------------------------
echo "=== T68.5 à T68.10, rétention de l'archive : fenêtre, plafond, variables, --all, temporaire occupé ==="
antidate_file() { # <fichier> <secondes> : recule chaque "epoch": N de <secondes> (le format n'est jamais réécrit à la main)
  [ -f "$1" ] || return 0
  python3 -I -c 'import re,sys
p,d=sys.argv[1],int(sys.argv[2])
s=open(p,encoding="utf-8").read()
open(p,"w",encoding="utf-8").write(re.sub(r"\"epoch\": (\d+)", lambda m: "\"epoch\": %d" % (int(m.group(1))-d), s))' "$1" "$2"
}
arch_antidate() { antidate_file "$ARC_FILE" "$1"; }
arch_lines() { if [ -f "$1" ]; then wc -l < "$1" | tr -d ' '; else echo 0; fi; }
t68_reset() { rm -rf "$VF_DRIVER_LOCK" "$REG_FILE" "$ARC_FILE" "$ARC_FILE.tmp"; }
t68_cycle() { # <owner> <agent> <node> : un cycle acquire, register, close done, release
  "$SCRIPT" acquire --owner="$1" --step=s >/dev/null 2>&1
  "$SCRIPT" register --agent="$2" --role=vf-coder --node="$3" >/dev/null 2>&1
  "$SCRIPT" close --agent="$2" --status=done >/dev/null 2>&1
  "$SCRIPT" release --owner="$1" >/dev/null 2>&1
}
# T68.5 : une archive antidatée au-delà de la fenêtre est élaguée au release suivant ; les lignes récentes restent, dans l'ordre.
t68_reset
t68_cycle M68o ag-old n-old
arch_antidate 200000
printf 'ligne sans epoch, texte quelconque\n' >> "$ARC_FILE"
t68_cycle M68n ag-new n-new
out="$("$SCRIPT" registry 2>/dev/null)"
assert "T68.5a, l'agent hors fenêtre a disparu de registry" "$(regn "$out" ag-old)" '0'
assert "T68.5b, l'agent récent est rendu" "$(regn "$out" ag-new)" '1'
assert "T68.5c, les lignes hors fenêtre sont élaguées de l'archive" "$(grep -c ag-old "$ARC_FILE" 2>/dev/null)" '0'
assert "T68.5d, la ligne sans epoch est élaguée" "$(grep -c 'sans epoch' "$ARC_FILE" 2>/dev/null)" '0'
assert "T68.5e, les lignes récentes restent, dans l'ordre (register puis close)" "$(grep -o '"event": "[a-z]*"' "$ARC_FILE" 2>/dev/null | tr -d '\n')" '"event": "register""event": "close"'
assert "T68.5f, l'archive ne porte plus que les deux lignes récentes" "$(arch_lines "$ARC_FILE")" '2'
# T68.6 : sans release, registry omet un agent clos hors fenêtre et garde un agent running même ancien.
t68_reset
"$SCRIPT" acquire --owner=M68s --step=s >/dev/null 2>&1
"$SCRIPT" register --agent=ag-run --role=vf-coder --node=n-r >/dev/null 2>&1
"$SCRIPT" register --agent=ag-clos --role=vf-coder --node=n-c >/dev/null 2>&1
"$SCRIPT" close --agent=ag-clos --status=done >/dev/null 2>&1
antidate_file "$REG_FILE" 500
out="$(VF_DRIVER_REGISTRY_WINDOW=100 "$SCRIPT" registry 2>/dev/null)"
assert "T68.6a, agent clos hors fenêtre omis" "$(regn "$out" ag-clos)" '0'
assert "T68.6b, agent running ancien gardé" "$(regn "$out" ag-run)" '1'
assert "T68.6c, window_seconds vaut la fenêtre demandée" "$out" '"window_seconds": 100'
assert "T68.6d, count cohérent avec les agents rendus" "$out" '"count": 1'
t68_reset
# T68.7 : plus de 2 000 lignes récentes, dérivées d'une ligne register réelle : le release garde les 2 000 dernières.
t68_big() { # <nombre de lignes> : archive de N lignes register récentes, identifiants ag-0001.. (ligne réelle capturée)
  "$SCRIPT" acquire --owner=M68g --step=s >/dev/null 2>&1
  "$SCRIPT" register --agent=ag-seed --role=vf-coder --node=n-seed >/dev/null 2>&1
  head -1 "$REG_FILE" > "$VF_DRIVER_LOCK.seed"
  "$SCRIPT" close --agent=ag-seed --status=done >/dev/null 2>&1
  "$SCRIPT" release --owner=M68g >/dev/null 2>&1
  awk -v n="$1" 'NR==1{ for (i = 1; i <= n; i++) { l = $0; sub(/"agent_id": "ag-seed"/, sprintf("\"agent_id\": \"ag-%04d\"", i), l); print l } }' "$VF_DRIVER_LOCK.seed" > "$ARC_FILE"
  rm -f "$VF_DRIVER_LOCK.seed"
}
t68_big 2100
t68_cycle M68z ag-last n-last
assert "T68.7a, 2 000 lignes exactement" "$(arch_lines "$ARC_FILE")" '2000'
assert "T68.7b, la plus ancienne est absente" "$(grep -c '"agent_id": "ag-0001"' "$ARC_FILE" 2>/dev/null)" '0'
assert "T68.7c, la plus ancienne gardée est la 103e" "$(head -1 "$ARC_FILE" | grep -c '"agent_id": "ag-0103"')" '1'
assert "T68.7d, la plus récente est la fermeture du dernier agent" "$(tail -1 "$ARC_FILE" | grep -c '"event": "close".*"agent_id": "ag-last"\|"agent_id": "ag-last".*"event": "close"')" '1'
t68_reset
# T68.8 : variables non numériques, vides ou nulles : retour aux défauts (patron du TTL, T24).
for _t68_bad in abc '' 0; do
  t68_reset
  t68_big 2100
  VF_DRIVER_REGISTRY_MAX="$_t68_bad" t68_cycle M68b ag-last n-last
  assert "T68.8a, VF_DRIVER_REGISTRY_MAX='$_t68_bad' : défaut 2000" "$(arch_lines "$ARC_FILE")" '2000'
  out="$(VF_DRIVER_REGISTRY_WINDOW="$_t68_bad" "$SCRIPT" registry 2>/dev/null)"
  assert "T68.8b, VF_DRIVER_REGISTRY_WINDOW='$_t68_bad' : défaut 86400" "$out" '"window_seconds": 86400'
done
t68_reset
# T68.9 : en mode verrou unique, registry --all rend la même sortie que registry.
t68_cycle M68a ag-a n-a
out="$("$SCRIPT" registry 2>/dev/null)"; out2="$("$SCRIPT" registry --all 2>/dev/null)"
assert "T68.9a, registry --all : mode verrou unique, même sortie que registry (non vide)" "$out2" "$out"
assert "T68.9b, registry --all : l'agent est rendu" "$out2" '"agent_id": "ag-a"'
t68_reset
# T68.10 : un dossier occupe le nom du temporaire : le release relâche, le courant est gardé, l'archive est identique à l'octet.
t68_cycle M68t ag-t1 n-t1
_t68_sum1="$(cksum < "$ARC_FILE" 2>/dev/null)"
mkdir "$ARC_FILE.tmp"
"$SCRIPT" acquire --owner=M68u --step=s >/dev/null 2>&1
"$SCRIPT" register --agent=ag-t2 --role=vf-coder --node=n-t2 >/dev/null 2>&1
"$SCRIPT" close --agent=ag-t2 --status=done >/dev/null 2>&1
out="$("$SCRIPT" release --owner=M68u 2>"$WORK_DIR/t68-10.err")"; rc=$?
assert "T68.10a, temporaire occupé : le release relâche quand même" "$out" '"released": true'
assert_exit "T68.10b, temporaire occupé : exit 0" "$rc" 0
assert "T68.10c, le registre courant est conservé avec ses 2 lignes" "$(arch_lines "$REG_FILE")" '2'
assert "T68.10d, l'archive est identique à l'octet" "$(cksum < "$ARC_FILE" 2>/dev/null)" "$_t68_sum1"
assert "T68.10e, stderr dit « registre non archivé »" "$(cat "$WORK_DIR/t68-10.err")" 'registre non archivé'
rmdir "$ARC_FILE.tmp" 2>/dev/null
t68_reset

# --- Scénario court : les marqueurs que les mutants font basculer (jouable contre une copie du script) ---
t68_markers() { # <script> <dossier de travail> -> « MARK <nom> ok|ko » (et « MARKINFO <nom> attendu obtenu » au ko)
  local S="$1" D="$2"
  mkdir -p "$D"
  (
    L="$D/DRIVER.lock"; R="$L.children.jsonl"; A="$L.children.closed.jsonl"
    export VF_DRIVER_LOCK="$L"; unset VF_DRIVER_REGISTRY_WINDOW VF_DRIVER_REGISTRY_MAX CLAUDE_CODE_SESSION_ID
    r() { bash "$S" "$@" 2>/dev/null; }
    mk() { if [ "$2" = "$3" ]; then echo "MARK $1 ok"; else echo "MARK $1 ko"; echo "MARKINFO $1 attendu=[$3] obtenu=[$2]"; fi; }
    sum() { if [ -f "$1" ]; then cksum < "$1"; else echo absent; fi; }
    cyc() { r acquire --owner="$1" --step=s >/dev/null; r register --agent="$2" --role=vf-coder --node="$3" >/dev/null; r close --agent="$2" --status=done >/dev/null; r release --owner="$1" >/dev/null; }
    rm -rf "$L" "$R" "$A"
    cyc Ma ag-1 nd-1
    out="$(r registry)"
    mk archive-lisible "$(regq "$out" ag-1 node)/$(regq "$out" ag-1 status)" "nd-1/done"
    r acquire --owner=Mb --step=s >/dev/null
    r register --agent=ag-1 --role=vf-coder --node=nd-2 >/dev/null
    out="$(r registry)"
    mk courant-prime "$(regn "$out" ag-1)/$(regq "$out" ag-1 status)/$(regq "$out" ag-1 node)" "1/running/nd-2"
    s1="$(sum "$A")"
    r release --owner=Mb >/dev/null
    s2="$(sum "$A")"
    mk orphelin-non-verse "$([ "$s1" = "$s2" ] && [ -f "$R" ] && echo intact || echo verse)" intact
    rm -rf "$L" "$R" "$A"
    export VF_DRIVER_REGISTRY_WINDOW=120
    cyc Mc ag-old n-o
    antidate_file "$A" 1000
    printf 'ligne sans epoch\n' >> "$A"
    cyc Md ag-new n-n
    mk fenetre-purge "old:$(grep -c ag-old "$A")/new:$(grep -c ag-new "$A")/sans:$(grep -c 'sans epoch' "$A")" "old:0/new:2/sans:0"
    rm -rf "$L" "$R" "$A"
    export VF_DRIVER_REGISTRY_WINDOW=100
    r acquire --owner=Me --step=s >/dev/null
    r register --agent=ag-run --role=vf-coder --node=n-r >/dev/null
    r register --agent=ag-c --role=vf-coder --node=n-c >/dev/null
    r close --agent=ag-c --status=done >/dev/null
    antidate_file "$R" 500
    out="$(r registry)"
    mk fenetre-lecture "run:$(regn "$out" ag-run)/clos:$(regn "$out" ag-c)" "run:1/clos:0"
    rm -rf "$L" "$R" "$A"
    unset VF_DRIVER_REGISTRY_WINDOW; export VF_DRIVER_REGISTRY_MAX=3
    r acquire --owner=Mf --step=s >/dev/null
    for i in 1 2 3; do r register --agent=ag-p$i --role=vf-coder --node=n-p$i >/dev/null; r close --agent=ag-p$i --status=done >/dev/null; done
    r release --owner=Mf >/dev/null
    mk plafond "lignes:$(arch_lines "$A")/derniere:$(tail -n 1 "$A" | sed -n 's/.*"agent_id": "\([^"]*\)".*/\1/p')" "lignes:3/derniere:ag-p3"
    rm -rf "$L" "$R" "$A"
  )
}

# --- Propriété générative : cycles aléatoires reproductibles (graine imprimée), invariants I1 à I6 + témoin de couverture ---
t68_gen() { # <script> <dossier de travail> <graine> -> « graine=… », compteurs, « MARK gen-… ok|ko »
  mkdir -p "$2"
  python3 -I - "$1" "$2" "$3" <<'PY'
import json, os, random, re, subprocess, sys, time
S, D, seed = sys.argv[1], sys.argv[2], int(sys.argv[3])
WIN, CAP, CYC = 120, 9, 40
rnd = random.Random(seed)
L = os.path.join(D, "DRIVER.lock"); R = L + ".children.jsonl"; A = L + ".children.closed.jsonl"
env = dict(os.environ, VF_DRIVER_LOCK=L, VF_DRIVER_REGISTRY_WINDOW=str(WIN), VF_DRIVER_REGISTRY_MAX=str(CAP))
env.pop("CLAUDE_CODE_SESSION_ID", None)
def run(*a):
    p = subprocess.run(["bash", S] + list(a), env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
    return p.returncode, p.stdout
def lines(p):
    try:
        with open(p, encoding="utf-8") as f: return f.read().splitlines()
    except OSError: return []
def raw(p):
    try:
        with open(p, "rb") as f: return f.read()
    except OSError: return None
def ep(l):
    m = re.search(r'"epoch": (\d+)', l); return int(m.group(1)) if m else None
def val(l, k):
    m = re.search(r'"%s": "([^"]*)"' % k, l); return m.group(1) if m else ""
def fold(ls):
    st = {}
    for l in ls:
        ev, i = val(l, "event"), val(l, "agent_id")
        if not i: continue
        if ev == "register": st[i] = {"status": "running", "node": val(l, "node"), "epoch": ep(l) or 0}
        elif ev == "close" and i in st:
            s = val(l, "status")
            if s: st[i]["status"] = s
    return st
def antidate(p, d):
    s = raw(p)
    if s is None: return
    t = re.sub(r'"epoch": (\d+)', lambda m: '"epoch": %d' % (int(m.group(1)) - d), s.decode("utf-8"))
    with open(p, "w", encoding="utf-8") as f: f.write(t)
def subseq(sub, full):
    it = iter(full)
    return all(any(x == y for y in it) for x in sub)
viol = {}
def bad(k, msg):
    viol.setdefault(k, msg)
cov = {"fenetre": 0, "plafond": 0, "running": 0, "reenregistre": 0}
pool = ["ag-%s" % c for c in "abcdef"]
for c in range(CYC):
    rc, out = run("acquire", "--owner=G%d" % c, "--step=c%d" % c)
    if '"acquired": true' not in out:
        bad("gen-couverture", "cycle %d : acquire refusé (%s)" % (c, out.strip()[:80])); continue
    for i, st in sorted(fold(lines(R)).items()):
        if st["status"] == "running" and rnd.random() < 0.7: run("close", "--agent=" + i, "--status=done")
    archived = set(fold(lines(A)).keys())
    ids = rnd.sample(pool, rnd.randint(1, 3))
    for n, i in enumerate(ids):
        if i in archived: cov["reenregistre"] += 1
        run("register", "--agent=" + i, "--role=vf-coder", "--node=n%d-%d" % (c, n))
    for i in ids:
        if rnd.random() < 0.7: run("close", "--agent=" + i, "--status=done")
    if lines(A) and rnd.random() < 0.4: antidate(A, rnd.randint(WIN // 2, 2 * WIN))
    arc_before, cur_before, bytes_before = lines(A), lines(R), raw(A)
    running_left = any(s["status"] == "running" for s in fold(cur_before).values())
    t0 = int(time.time())
    run("release", "--owner=G%d" % c)
    arc_after, cur_after = lines(A), lines(R)
    if running_left:
        cov["running"] += 1
        if not os.path.exists(R) or raw(A) != bytes_before:
            bad("gen-conservation", "cycle %d : enfant running, courant %s, archive %s" % (c, "présent" if os.path.exists(R) else "ABSENT", "inchangée" if raw(A) == bytes_before else "MODIFIÉE"))
    else:
        cut = t0 - WIN
        if any(ep(l) is None or ep(l) < cut - 2 for l in arc_before): cov["fenetre"] += 1
        if len([l for l in arc_before + cur_before if ep(l) is not None and ep(l) >= cut + 2]) > CAP: cov["plafond"] += 1
        if os.path.exists(R): bad("gen-conservation", "cycle %d : courant encore présent sans enfant running" % c)
        m = min(CAP, len(cur_before))
        if m and arc_after[-m:] != cur_before[-m:]:
            bad("gen-conservation", "cycle %d : les %d dernières lignes de l'archive ne sont pas celles du courant" % (c, m))
        if not subseq(arc_after, arc_before + cur_before):
            bad("gen-conservation", "cycle %d : l'archive n'est pas une sous-suite de l'archive avant release suivie du courant" % c)
        for l in arc_after:
            if ep(l) is None or ep(l) < cut:
                bad("gen-fenetre", "cycle %d : ligne d'epoch %s sous la coupe %d" % (c, ep(l), cut)); break
    if len(arc_after) > CAP:
        bad("gen-plafond", "cycle %d : %d lignes pour un plafond de %d" % (c, len(arc_after), CAP))
    rc, o = run("registry")
    t1 = int(time.time()); cutr = t1 - WIN
    try:
        got = {a["agent_id"]: (a["status"], a["node"]) for a in json.loads(o)["agents"]}
    except Exception:
        bad("gen-lecture", "cycle %d : registry n'est pas un JSON" % c); continue
    model = fold(arc_after + cur_after)
    skip = set(i for i, s in model.items() if s["status"] != "running" and abs(s["epoch"] - cutr) <= 2)
    exp = {i: (s["status"], s["node"]) for i, s in model.items() if i not in skip and (s["status"] == "running" or s["epoch"] >= cutr)}
    got = {i: v for i, v in got.items() if i not in skip}
    if got != exp:
        bad("gen-lecture", "cycle %d : registry %s, repli indépendant %s" % (c, sorted(got.items()), sorted(exp.items())))
print("graine=%d cycles=%d fenetre=%d plafond=%d" % (seed, CYC, WIN, CAP))
print("couverture : fenetre_elaguee=%d plafond_elague=%d enfant_running=%d reenregistre=%d" % (cov["fenetre"], cov["plafond"], cov["running"], cov["reenregistre"]))
if not all(cov.values()): bad("gen-couverture", "compteur de couverture à 0 : %s" % cov)
for k in ("gen-plafond", "gen-fenetre", "gen-conservation", "gen-lecture", "gen-couverture"):
    if k in viol:
        print("MARK %s ko" % k); print("MARKINFO %s %s" % (k, viol[k]))
    else:
        print("MARK %s ok" % k)
PY
}

echo "=== T68.G (propriété générative) et T68.M (mutants M-ARC-*) : script réel, témoin, puis copies mutées ==="
T68_DIR="$WORK_DIR/t68m"; mkdir -p "$T68_DIR"
T68_SEED="${VF_T68_SEED:-20261111}"
T68_POLICY="$(cd "$(dirname "$SCRIPT")/../.." && pwd)/planning-core/scripts/workstream-policy.sh"
T68_IDS=""; T68_KILLED=0; T68_TOTAL=6; T68_T0=$SECONDS
t68_variant() { # <id> <ancre BRE> <expression sed s> <gen 0|1> : prépare la copie mutée, lance ses scénarios en arrière-plan
  local id="$1" anchor="$2" expr="$3" gen="$4" d="$T68_DIR/$1" n
  mkdir -p "$d"; T68_IDS="$T68_IDS $id"
  cp "$SCRIPT" "$d/driver-lock.sh"; cp "$T68_POLICY" "$d/workstream-policy.sh"; cp "$d/driver-lock.sh" "$d/copie-temoin.sh"
  if [ -n "$anchor" ]; then
    n="$(grep -c -e "$anchor" "$d/driver-lock.sh")"
    if [ "$n" != "1" ]; then echo "ancre non unique ($n occurrences de [$anchor])" > "$d/prepko"; return; fi
    sed -i.bak -e "/$anchor/$expr" "$d/driver-lock.sh"; rm -f "$d/driver-lock.sh.bak"
    if cmp -s "$d/driver-lock.sh" "$d/copie-temoin.sh"; then echo "mutant NON OPPOSABLE : la substitution n'a rien changé" > "$d/prepko"; return; fi
    if ! bash -n "$d/driver-lock.sh" 2>/dev/null; then echo "le mutant n'est pas un script valide" > "$d/prepko"; return; fi
  fi
  chmod +x "$d/driver-lock.sh"
  ( { t68_markers "$d/driver-lock.sh" "$d/w"; if [ "$gen" = 1 ]; then t68_gen "$d/driver-lock.sh" "$d/g" "$T68_SEED"; fi; } > "$d/out.txt" 2>&1 ) &
}
t68_ko() { sed -n 's/^MARK \(.*\) ko$/\1/p' "$1/out.txt" | LC_ALL=C sort; }
t68_nb() { grep -c '^MARK ' "$1/out.txt"; }
t68_eval() { # <id> <gen 0|1> <attendu : marqueurs séparés par des espaces>
  local id="$1" gen="$2" d="$T68_DIR/$1" want got nb nbw=6
  [ "$gen" = 1 ] && nbw=11
  if [ -f "$d/prepko" ]; then assert_exit "M-ARC-$id — $(cat "$d/prepko")" 1 0; return; fi
  nb="$(t68_nb "$d")"
  if [ "$nb" != "$nbw" ]; then assert_exit "M-ARC-$id — scénarios incomplets ($nb marqueurs sur $nbw)" 1 0; sed -n '1,12p' "$d/out.txt"; return; fi
  want="$(printf '%s\n' $3 | LC_ALL=C sort | tr '\n' ' ')"; got="$(t68_ko "$d" | tr '\n' ' ')"
  if [ "$want" = "$got" ]; then
    assert_exit "M-ARC-$id — mutant tué : bascule exactement {$got}" 0 0
    T68_KILLED=$((T68_KILLED+1))
    for m in $got; do grep "^MARKINFO $m " "$d/out.txt" | head -1 | sed 's/^/      /'; done
  else
    assert_exit "M-ARC-$id — ensemble basculé INATTENDU" 1 0
    echo "     attendu: {$want}"; echo "     obtenu:  {$got}"
    grep '^MARKINFO ' "$d/out.txt" | head -6 | sed 's/^/      /'
  fi
}
mkdir -p "$T68_DIR/reel"; ( { t68_markers "$SCRIPT" "$T68_DIR/reel/w"; t68_gen "$SCRIPT" "$T68_DIR/reel/g" "$T68_SEED"; } > "$T68_DIR/reel/out.txt" 2>&1 ) &
t68_variant temoin '' '' 0
t68_variant ARCHIVE 'cat "$REG"; } | awk -v cut' 's@cat "$REG"; } | awk -v cut@: ; } | awk -v cut@' 1
t68_variant FENETRE 'ep >= cut' 's@ep >= cut@1@' 1
t68_variant PLAFOND 'tail -n "$REG_MAX"' 's@tail -n "$REG_MAX"@cat@' 1
t68_variant COURANT 'registry_fold "$_arc" "$REG"' 's@registry_fold "$_arc" "$REG"@registry_fold "$REG" "$_arc"@' 0
t68_variant LECTURE '$10 == "running" || $8 + 0 >= cut' 's@$10 == "running" || $8 + 0 >= cut@1@' 0
t68_variant ORPHELIN '\[ "$_orph" -gt 0 \] || registry_archive' 's@\[ "$_orph" -gt 0 \] || registry_archive@registry_archive@' 0
wait
echo "  graine=$T68_SEED"
sed -n '/^graine=/p;/^couverture :/p' "$T68_DIR/reel/out.txt"
for _t68_m in archive-lisible courant-prime orphelin-non-verse fenetre-purge fenetre-lecture plafond gen-plafond gen-fenetre gen-conservation gen-lecture gen-couverture; do
  _t68_v=ko; grep -q "^MARK $_t68_m ok\$" "$T68_DIR/reel/out.txt" && _t68_v=ok
  [ "$_t68_v" = ok ]; assert_exit "T68.M réel — marqueur $_t68_m ok" "$?" 0
  case "$_t68_m" in gen-*) assert_exit "T68.G — $_t68_m (script réel)" "$([ "$_t68_v" = ok ] && echo 0 || echo 1)" 0 ;; esac
  [ "$_t68_v" = ok ] || grep "^MARKINFO $_t68_m " "$T68_DIR/reel/out.txt" | sed 's/^/      /'
done
assert_exit "T68.M témoin — la copie non mutée ne bascule aucun marqueur" "$(t68_ko "$T68_DIR/temoin" | wc -l | tr -d ' ')" 0
t68_eval ARCHIVE 1 "archive-lisible fenetre-purge plafond gen-conservation gen-couverture"
t68_eval FENETRE 1 "fenetre-purge gen-fenetre"
t68_eval PLAFOND 1 "plafond gen-plafond"
t68_eval COURANT 0 "courant-prime"
t68_eval LECTURE 0 "fenetre-lecture"
t68_eval ORPHELIN 0 "orphelin-non-verse"
echo "  durée T68.G + T68.M : $((SECONDS-T68_T0))s"
assert_exit "T68.M — les $T68_TOTAL mutants M-ARC-* sont tués ($T68_KILLED)" "$([ "$T68_KILLED" = "$T68_TOTAL" ] && echo 0 || echo 1)" 0
rm -rf "$T68_DIR"
t68_reset

# ---------------------------------------------------------------------------------------------------
# T69 : plan de mission publié à côté du verrou (A16, SOCL-04). T69.1 à T69.9, T69.G (propriété générative de la
# projection), T69.M (mutants M-PLAN-*). Le DAG vient de dag.sh (init puis add), jamais d'un JSON écrit à la main,
# sauf pour les cas de bornes (230 nœuds) que dag.sh ne produirait pas en un temps raisonnable.
# ---------------------------------------------------------------------------------------------------
echo "=== T69, plan de mission publié : publish-plan, champ dag de status, refus, génération, falsification, bornes ==="
assert_not() { if [[ "$2" != *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     interdit: $3"; echo "     obtenu:   $2"; FAIL=$((FAIL+1)); fi; }
PLAN_TSV="$VF_DRIVER_LOCK.plan.tsv"
DAGSH="$(dirname "$SCRIPT")/dag.sh"
T69_MARK="MK69"
mk_dag() { # <fichier> : DAG réel (dag.sh init puis add) : trois nœuds, dépendances, texte libre et chemin de scope
  rm -f "$1"
  (
    export VF_DRIVER_LOCK="$WORK_DIR/dag-none.lock"
    bash "$DAGSH" init --file="$1" >/dev/null 2>&1
    bash "$DAGSH" add --file="$1" --id=n1 --step="FREETEXT-$T69_MARK étape un" --scope="SCOPEPATH-$T69_MARK/a.txt" >/dev/null 2>&1
    bash "$DAGSH" add --file="$1" --id=n2 --step="FREETEXT-$T69_MARK deux" --deps=n1 >/dev/null 2>&1
    bash "$DAGSH" add --file="$1" --id=n3 --step=x --deps=n1,n2 --scope="SCOPEPATH-$T69_MARK/b.txt" >/dev/null 2>&1
  )
}
mk_dag1() { # <fichier> : DAG réel à un seul nœud (publication d'un autre contenu)
  rm -f "$1"
  ( export VF_DRIVER_LOCK="$WORK_DIR/dag-none.lock"
    bash "$DAGSH" init --file="$1" >/dev/null 2>&1
    bash "$DAGSH" add --file="$1" --id=solo --step="FREETEXT-$T69_MARK solo" >/dev/null 2>&1 )
}
plan_sig() { # <JSON de status> -> « id:statut:dep,dep|… », « absent » sans champ dag, « invalide » si le JSON ne se lit pas
  printf '%s' "$1" | python3 -I -c 'import json,sys
try:
    d=json.load(sys.stdin); g=d.get("dag")
    print("absent" if g is None else "|".join("%s:%s:%s" % (n["id"], n["status"], ",".join(n["deps"])) for n in g["nodes"]))
except Exception:
    print("invalide")' 2>/dev/null
}
dag_nodes_ok() { # <JSON de status> <dag.json> -> 0 si les nœuds de status sont ceux du DAG réduits à id, deps, status (même ordre)
  python3 -I -c 'import json,sys
s=json.loads(sys.argv[1])["dag"]["nodes"]
d=json.load(open(sys.argv[2]))["nodes"]
sys.exit(0 if s==[{"id":n["id"],"deps":n["deps"],"status":n["status"]} for n in d] else 1)' "$1" "$2" 2>/dev/null
}
plan_forge() { # <fichier plan> <genre> : falsifie le plan publié (en-tête ou lignes de nœuds) sans réécrire le format à la main
  python3 -I - "$1" "$2" <<'PY'
import sys
p, kind = sys.argv[1], sys.argv[2]
rows = open(p, "rb").read().decode("utf-8").split("\n")
if rows and rows[-1] == "": rows = rows[:-1]
h = rows[0].split("\t")
if kind == "schema": h[0] = "vibeflow/driver-plan@9"
elif kind == "gen": h[1] = "DRIVER.lock.gen.1.1"
elif kind == "epoch": h[2] = "12ab"
elif kind == "wsbad": h[3] = 'al"pha'
rows[0] = "\t".join(h)
if kind == "nodes":
    rows += ['bad"id\tready\t', 'bad\\id\tready\t', 'tab\tid\tready\t', 'bad\nready', ("x" * 65) + "\tready\t",
             'okstat\tbogus\t', 'okdep\tready\tgood,bad"dep,n1', 'fine\tdone\tn1']
open(p, "wb").write(("\n".join(rows) + "\n").encode("utf-8"))
PY
}
T69_DAG="$WORK_DIR/t69-dag.json"; T69_DAG1="$WORK_DIR/t69-dag1.json"
mk_dag "$T69_DAG"; mk_dag1 "$T69_DAG1"
SIG3='n1:ready:|n2:blocked:n1|n3:blocked:n1,n2'
rm -rf "$VF_DRIVER_LOCK" "$REG_FILE" "$ARC_FILE" "$PLAN_TSV" "$PLAN_TSV.tmp"
"$SCRIPT" acquire --owner=M69 --step=exec-A >/dev/null 2>&1
# T69.1 : publication par le détenteur ; le fichier de plan ne contient pas le texte libre.
out="$("$SCRIPT" publish-plan --owner=M69 --file="$T69_DAG" 2>/dev/null)"; rc=$?
assert "T69.1a, publish-plan : published true" "$out" '"published": true'
assert "T69.1b, publish-plan : 3 nœuds" "$out" '"nodes": 3'
assert "T69.1c, publish-plan : 0 ignoré" "$out" '"ignored": 0'
assert_exit "T69.1d, publish-plan : exit 0" "$rc" 0
[ -f "$PLAN_TSV" ]; assert_exit "T69.1e, le fichier de plan existe à côté du verrou" $? 0
assert_not "T69.1f, le fichier de plan ne contient pas le texte libre" "$(cat "$PLAN_TSV" 2>/dev/null)" "FREETEXT-$T69_MARK"
assert_not "T69.1g, le fichier de plan ne contient pas le chemin du scope" "$(cat "$PLAN_TSV" 2>/dev/null)" "SCOPEPATH-$T69_MARK"
# T69.2 : status rend le champ dag, ids, dépendances et statuts du DAG, rien d'autre.
st="$("$SCRIPT" status 2>/dev/null)"
assert "T69.2a, status : champ dag en fin de ligne" "$st" '"dag": {"ws": "", "phase": "", "at": '
json_ok "$st"; assert_exit "T69.2b, status avec dag : JSON valide" $? 0
dag_nodes_ok "$st" "$T69_DAG"; assert_exit "T69.2c, les nœuds sont ceux du DAG (id, deps, status, exactement ces trois clés)" $? 0
assert_not "T69.2d, le texte libre est absent de status" "$st" "FREETEXT-$T69_MARK"
assert_not "T69.2e, le chemin du scope est absent de status" "$st" "SCOPEPATH-$T69_MARK"
assert "T69.2f, at est un epoch numérique" "$(json_field "$st" '["dag"]["at"]' | grep -cE '^[0-9]{10}$')" '1'
# T69.3 : refus nommés, exit 1, rien d'écrit.
t69_refus() { # <id> <raison> <commande…> : refus nommé, published false, exit 1
  local id="$1" why="$2" o r; shift 2
  o="$("$@" 2>/dev/null)"; r=$?
  assert "$id, refus $why" "$o" "\"reason\": \"$why\""
  assert "$id, published false" "$o" '"published": false'
  assert_exit "$id, exit 1" "$r" 1
  T69_LAST="$o"
}
_t69_sum1="$(cksum < "$PLAN_TSV" 2>/dev/null)"
[ -n "$_t69_sum1" ]; assert_exit "T69.3, témoin préalable : le plan du détenteur existe (les contrôles d'intégrité qui suivent ne sont pas vides)" $? 0
t69_refus T69.3a not-owner "$SCRIPT" publish-plan --owner=Autre --file="$T69_DAG1"
assert "T69.3a, le plan du détenteur est intact" "$(cksum < "$PLAN_TSV" 2>/dev/null)" "$_t69_sum1"
t69_refus T69.3b file-required "$SCRIPT" publish-plan --owner=M69
t69_refus T69.3c file-unreadable "$SCRIPT" publish-plan --owner=M69 --file="$WORK_DIR/absent.json"
t69_refus T69.3d file-unreadable "$SCRIPT" publish-plan --owner=M69 --file="$WORK_DIR"
printf '{"nodes": 5} SECRET-%s' "$T69_MARK" > "$WORK_DIR/t69-bad1.json"
t69_refus T69.3e plan-invalid "$SCRIPT" publish-plan --owner=M69 --file="$WORK_DIR/t69-bad1.json"
assert_not "T69.3e, le contenu du fichier n'apparaît pas dans la sortie" "$T69_LAST" "SECRET-$T69_MARK"
printf '[1, 2, 3]' > "$WORK_DIR/t69-bad2.json"
t69_refus T69.3f plan-invalid "$SCRIPT" publish-plan --owner=M69 --file="$WORK_DIR/t69-bad2.json"
head -c 1048577 /dev/zero | tr '\0' ' ' > "$WORK_DIR/t69-big.json"
t69_refus T69.3g plan-too-large "$SCRIPT" publish-plan --owner=M69 --file="$WORK_DIR/t69-big.json"
out="$("$SCRIPT" publish-plan --file="$T69_DAG1" 2>/dev/null)"; rc=$?
assert "T69.3h, sans --owner : owner-required" "$out" '"error": "owner-required"'
assert_exit "T69.3h, sans --owner : exit 1" "$rc" 1
assert "T69.3i, rien d'écrit par les refus (plan intact)" "$(cksum < "$PLAN_TSV" 2>/dev/null)" "$_t69_sum1"
mkdir -p "$WORK_DIR/t69-fakepy"; printf '#!/bin/sh\nexit 127\n' > "$WORK_DIR/t69-fakepy/python3"; chmod +x "$WORK_DIR/t69-fakepy/python3"
out="$(PATH="$WORK_DIR/t69-fakepy:$PATH" "$SCRIPT" publish-plan --owner=M69 --file="$T69_DAG1" 2>/dev/null)"; rc=$?
assert "T69.3j, python3 qui sort en 127 : python3-missing" "$out" '"reason": "python3-missing"'
assert_exit "T69.3j, python3-missing : exit 1" "$rc" 1
printf '#!/bin/sh\nexit 3\n' > "$WORK_DIR/t69-fakepy/python3"
out="$(PATH="$WORK_DIR/t69-fakepy:$PATH" "$SCRIPT" publish-plan --owner=M69 --file="$T69_DAG1" 2>/dev/null)"
assert "T69.3k, python3 qui sort en 3 : plan-invalid (jamais python3-missing)" "$out" '"reason": "plan-invalid"'
assert "T69.3l, après python3 en échec, le plan est toujours celui du détenteur" "$(cksum < "$PLAN_TSV" 2>/dev/null)" "$_t69_sum1"
rm -f "$PLAN_TSV"; mkdir "$PLAN_TSV"
t69_refus T69.3m plan-unwritable "$SCRIPT" publish-plan --owner=M69 --file="$T69_DAG1"
[ ! -e "$PLAN_TSV.tmp" ]; assert_exit "T69.3m, aucun temporaire laissé" $? 0
rmdir "$PLAN_TSV"
rm -rf "$VF_DRIVER_LOCK"
t69_refus T69.3n no-lock "$SCRIPT" publish-plan --owner=M69 --file="$T69_DAG1"
[ ! -e "$PLAN_TSV" ]; assert_exit "T69.3n, sans verrou, aucun plan écrit" $? 0
# T69.4 : republier remplace le résumé ; aucun temporaire.
"$SCRIPT" acquire --owner=M69 --step=exec-A >/dev/null 2>&1
"$SCRIPT" publish-plan --owner=M69 --file="$T69_DAG" >/dev/null 2>&1
out="$("$SCRIPT" publish-plan --owner=M69 --file="$T69_DAG1" 2>/dev/null)"
assert "T69.4a, republication : un nœud" "$out" '"nodes": 1'
st="$("$SCRIPT" status 2>/dev/null)"
assert "T69.4b, status rend le plan neuf" "$(plan_sig "$st")" 'solo:ready:'
[ ! -e "$PLAN_TSV.tmp" ]; assert_exit "T69.4c, aucun temporaire laissé à côté du plan" $? 0
# T69.5 : le plan est masqué quand la génération change ; reclaim le garde ; release et recover le suppriment.
"$SCRIPT" publish-plan --owner=M69 --file="$T69_DAG" >/dev/null 2>&1
CLAUDE_CODE_SESSION_ID=s69 "$SCRIPT" reclaim --owner=M69 >/dev/null 2>&1
assert "T69.5a, reclaim par le même propriétaire : le plan reste" "$(plan_sig "$("$SCRIPT" status 2>/dev/null)")" "$SIG3"
age_stale "$VF_DRIVER_LOCK"
"$SCRIPT" takeover --owner=M69b --step=exec-B >/dev/null 2>&1
assert "T69.5b, takeover par un autre propriétaire : le champ dag est masqué" "$(plan_sig "$("$SCRIPT" status 2>/dev/null)")" 'absent'
"$SCRIPT" publish-plan --owner=M69b --file="$T69_DAG1" >/dev/null 2>&1
assert "T69.5c, le repreneur republie : son plan est rendu" "$(plan_sig "$("$SCRIPT" status 2>/dev/null)")" 'solo:ready:'
"$SCRIPT" release --owner=M69b >/dev/null 2>&1
[ ! -e "$PLAN_TSV" ]; assert_exit "T69.5d, release supprime le fichier de plan" $? 0
"$SCRIPT" acquire --owner=M69c --step=exec-C >/dev/null 2>&1
"$SCRIPT" publish-plan --owner=M69c --file="$T69_DAG" >/dev/null 2>&1
age_stale "$VF_DRIVER_LOCK"
"$SCRIPT" recover >/dev/null 2>&1
[ ! -e "$PLAN_TSV" ]; assert_exit "T69.5e, recover d'un verrou périmé supprime le fichier de plan" $? 0
# T69.6 : fichier falsifié à la main (par un aide de la suite) : JSON toujours valide, seuls les nœuds valides sortent.
"$SCRIPT" acquire --owner=M69 --step=exec-A >/dev/null 2>&1
for _t69_k in schema gen epoch wsbad; do
  "$SCRIPT" publish-plan --owner=M69 --file="$T69_DAG" >/dev/null 2>&1
  plan_forge "$PLAN_TSV" "$_t69_k"
  st="$("$SCRIPT" status 2>/dev/null)"
  assert "T69.6a, en-tête falsifié ($_t69_k) : le champ dag disparaît" "$(plan_sig "$st")" 'absent'
  json_ok "$st"; assert_exit "T69.6b, en-tête falsifié ($_t69_k) : status reste un JSON valide" $? 0
done
"$SCRIPT" publish-plan --owner=M69 --file="$T69_DAG" >/dev/null 2>&1
plan_forge "$PLAN_TSV" nodes
st="$("$SCRIPT" status 2>/dev/null)"; st_all="$("$SCRIPT" status --all 2>/dev/null)"
assert "T69.6c, lignes falsifiées : seuls les nœuds valides sortent" "$(plan_sig "$st")" "$SIG3|okdep:ready:good,n1|fine:done:n1"
json_ok "$st"; assert_exit "T69.6d, lignes falsifiées : status reste un JSON valide" $? 0
json_ok "$st_all"; assert_exit "T69.6e, lignes falsifiées : status --all reste un JSON valide" $? 0
assert "T69.6f, status --all rend les mêmes nœuds" "$(plan_sig "$st_all")" "$SIG3|okdep:ready:good,n1|fine:done:n1"
# T69.7 : bornes.
python3 -I - "$WORK_DIR/t69-big230.json" "$WORK_DIR/t69-deps.json" <<'PY'
import json, sys
json.dump({"nodes": [{"id": "b%03d" % i, "status": "ready", "deps": [], "step": "F", "scope": []} for i in range(230)]}, open(sys.argv[1], "w"))
json.dump({"nodes": [{"id": "d1", "status": "ready", "deps": ["z" * 65, "ok1"]},
                     {"id": "d2", "status": "ready", "deps": ["dep%02d" % i for i in range(40)]},
                     {"id": "d1", "status": "done", "deps": []}]}, open(sys.argv[2], "w"))
PY
out="$("$SCRIPT" publish-plan --owner=M69 --file="$WORK_DIR/t69-big230.json" 2>/dev/null)"
assert "T69.7a, 230 nœuds : 200 gardés" "$out" '"nodes": 200'
assert "T69.7b, 230 nœuds : 30 ignorés" "$out" '"ignored": 30'
st="$("$SCRIPT" status 2>/dev/null)"
assert "T69.7c, status rend 200 nœuds" "$(printf '%s' "$st" | python3 -I -c 'import json,sys; print(len(json.load(sys.stdin)["dag"]["nodes"]))' 2>/dev/null)" '200'
out="$("$SCRIPT" publish-plan --owner=M69 --file="$WORK_DIR/t69-deps.json" 2>/dev/null)"
assert "T69.7d, doublon : deux nœuds, un ignoré" "$out" '"nodes": 2, "ignored": 1'
st="$("$SCRIPT" status 2>/dev/null)"
assert "T69.7e, dépendance de 65 caractères écartée, doublon : le premier gagne" "$(plan_sig "$st" | tr '|' '\n' | sed -n 1p)" 'd1:ready:ok1'
assert "T69.7f, 40 dépendances : 32 gardées" "$(json_field "$st" '["dag"]["nodes"][1]["deps"].__len__()')" '32'
# T69.8 : aucun chemin, aucune clé refusée.
out="$("$SCRIPT" publish-plan --owner=M69 --file="$T69_DAG" 2>/dev/null)"; st="$("$SCRIPT" status 2>/dev/null)"
case "$out$st" in *"$WORK_DIR"*) echo "  ❌ FAIL — T69.8a, aucune valeur de WORK_DIR dans publish-plan ni dans dag"; FAIL=$((FAIL+1)) ;; *) if [ -n "$out" ] && [ -n "$st" ]; then echo "  ✅ PASS — T69.8a, aucune valeur de WORK_DIR dans publish-plan ni dans dag"; PASS=$((PASS+1)); else echo "  ❌ FAIL — T69.8a, sorties vides"; FAIL=$((FAIL+1)); fi ;; esac
for _t69_k in doing mandat messages outils fil; do
  case "$out$st" in *"\"$_t69_k\""*) echo "  ❌ FAIL — T69.8b, clé refusée « $_t69_k »"; FAIL=$((FAIL+1)) ;; *) if [ -n "$out" ]; then echo "  ✅ PASS — T69.8b, clé refusée « $_t69_k » absente"; PASS=$((PASS+1)); else echo "  ❌ FAIL — T69.8b, sortie vide"; FAIL=$((FAIL+1)); fi ;; esac
done
# T69.9 : sans plan publié, aucun champ dag et la ligne de status est celle d'avant.
"$SCRIPT" release --owner=M69 >/dev/null 2>&1
"$SCRIPT" acquire --owner=M69 --step=exec-A >/dev/null 2>&1
st="$("$SCRIPT" status 2>/dev/null)"; st_all="$("$SCRIPT" status --all 2>/dev/null)"
assert_not "T69.9a, sans plan : status n'a pas de champ dag" "$st" '"dag"'
assert_not "T69.9b, sans plan : status --all n'a pas de champ dag" "$st_all" '"dag"'
assert "T69.9c, sans plan : la ligne finit comme avant" "$st" '"children_running": 0}'
"$SCRIPT" release --owner=M69 >/dev/null 2>&1
rm -rf "$VF_DRIVER_LOCK" "$REG_FILE" "$ARC_FILE" "$PLAN_TSV" "$PLAN_TSV.tmp"

# --- Scénario court : les marqueurs que les mutants du plan font basculer ---
t69_markers() { # <script> <dossier de travail> <DAG à 3 nœuds> <DAG à 1 nœud> -> « MARK <nom> ok|ko »
  local S="$1" D="$2" G="$3" G1="$4"
  mkdir -p "$D"
  (
    L="$D/DRIVER.lock"; P="$L.plan.tsv"
    export VF_DRIVER_LOCK="$L"; unset CLAUDE_CODE_SESSION_ID
    r() { bash "$S" "$@" 2>/dev/null; }
    mk() { if [ "$2" = "$3" ]; then echo "MARK $1 ok"; else echo "MARK $1 ko"; echo "MARKINFO $1 attendu=[$3] obtenu=[$2]"; fi; }
    rm -rf "$L" "$L".*
    r acquire --owner=Pa --step=s >/dev/null
    r publish-plan --owner=Pa --file="$G" >/dev/null
    st="$(r status)"
    mk plan-publie "$(plan_sig "$st")" "$SIG3"
    mk plan-sans-texte "fichier:$(grep -c "FREETEXT-$T69_MARK" "$P")/status:$(printf '%s' "$st" | grep -c "FREETEXT-$T69_MARK")/scope:$(printf '%s' "$st$(cat "$P")" | grep -c "SCOPEPATH-$T69_MARK")" "fichier:0/status:0/scope:0"
    plan_forge "$P" nodes
    s1="$(plan_sig "$(r status)")"
    r publish-plan --owner=Pa --file="$G" >/dev/null
    plan_forge "$P" epoch
    s2="$(plan_sig "$(r status)")"
    mk plan-falsifie "$s1/$s2" "$SIG3|okdep:ready:good,n1|fine:done:n1/absent"
    r publish-plan --owner=Pa --file="$G" >/dev/null
    c1="$(cksum < "$P")"
    o="$(r publish-plan --owner=Pb --file="$G1")"
    c2="$(cksum < "$P")"
    mk plan-proprietaire "$(printf '%s' "$o" | grep -c 'not-owner')/$([ "$c1" = "$c2" ] && echo intact || echo ecrase)" "1/intact"
    age_stale "$L"
    r takeover --owner=Pc --step=s >/dev/null
    mk plan-perime-masque "$(plan_sig "$(r status)")" absent
    rm -rf "$L" "$L".*
  )
}

# --- Propriété générative de la projection : plans tirés au hasard (graine imprimée), P1 à P5 + témoin de couverture ---
t69_gen() { # <script> <dossier de travail> <graine> -> « graine=… », couverture, « MARK gen-plan-… ok|ko »
  mkdir -p "$2"
  python3 -I - "$1" "$2" "$3" <<'PY'
import json, os, random, re, subprocess, sys
S, D, seed = sys.argv[1], sys.argv[2], int(sys.argv[3])
PLANS = 60
rnd = random.Random(seed)
L = os.path.join(D, "DRIVER.lock"); P = L + ".plan.tsv"; F = os.path.join(D, "plan.json")
env = dict(os.environ, VF_DRIVER_LOCK=L); env.pop("CLAUDE_CODE_SESSION_ID", None)
def run(*a):
    p = subprocess.run(["bash", S] + list(a), env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
    return p.returncode, p.stdout
ID = re.compile(r"\A[A-Za-z0-9._:-]{1,64}\Z")
ST = ("blocked", "ready", "running", "done", "failed")
HOST = {"id_guillemet": 'a"b', "id_antislash": "a\\b", "id_tabulation": "a\tb", "id_saut": "a\nb", "id_espace": "a b",
        "id_accent": "café", "id_vide": "", "id_long": "x" * 65, "id_non_texte": 7}
CLASSES = list(HOST) + ["statut_inconnu", "statut_absent", "statut_non_texte", "dep_hostile", "dep_plus_de_32",
                        "dep_non_liste", "plus_de_200", "doublon", "cle_ws_phase_hostile"]
def model(nodes):
    kept, seen = [], set()
    for n in nodes:
        if not isinstance(n, dict): continue
        i, s = n.get("id"), n.get("status")
        if not (isinstance(i, str) and ID.match(i)): continue
        if not (isinstance(s, str) and s in ST): continue
        if i in seen or len(kept) >= 200: continue
        d, dl = n.get("deps"), []
        if isinstance(d, list):
            for x in d:
                if isinstance(x, str) and ID.match(x):
                    dl.append(x)
                    if len(dl) >= 32: break
        seen.add(i); kept.append({"id": i, "deps": dl, "status": s})
    return kept
def mkplan(c):
    used = set()
    force = CLASSES[c] if c < len(CLASSES) else None
    count = 230 if force == "plus_de_200" else rnd.choice([0, 1, 2, 3, 5, 8, 20, 40])
    if force and count < 3: count = 3
    nodes = []
    for i in range(count):
        free = "FM%d_%d_%d" % (seed, c, i)
        node = {"id": "n%d" % i, "status": rnd.choice(ST), "step": free + ' "libre"\\\t\né', "stage": "", "scope": [free + "/x"],
                "deps": ["n%d" % j for j in rnd.sample(range(i), min(i, rnd.randint(0, 3)))]}
        r = rnd.random()
        if r < 0.05:
            k = rnd.choice(list(HOST)); node["id"] = HOST[k]; used.add(k)
        elif r < 0.09:
            k = rnd.choice(["statut_inconnu", "statut_absent", "statut_non_texte"]); used.add(k)
            if k == "statut_inconnu": node["status"] = rnd.choice(["pending", "DONE", ""])
            elif k == "statut_absent": del node["status"]
            else: node["status"] = rnd.choice([1, None, ["done"]])
        elif r < 0.13:
            node["deps"].append(rnd.choice(["x\"y", "z" * 65, 5, None])); used.add("dep_hostile")
        nodes.append(node)
    if force in HOST and nodes: nodes[0]["id"] = HOST[force]; used.add(force)
    if force == "statut_inconnu" and nodes: nodes[0]["status"] = "pending"; used.add(force)
    if force == "statut_absent" and nodes: nodes[0].pop("status", None); used.add(force)
    if force == "statut_non_texte" and nodes: nodes[0]["status"] = 3; used.add(force)
    if force == "dep_hostile" and nodes: nodes[0]["deps"] = ["a b", "ok0"]; used.add(force)
    if force == "dep_plus_de_32" and nodes: nodes[0]["deps"] = ["d%02d" % j for j in range(40)]; used.add(force)
    if force == "dep_non_liste" and nodes: nodes[0]["deps"] = "n1,n2"; used.add(force)
    if force == "doublon" and len(nodes) > 1: nodes[1]["id"] = nodes[0]["id"]; nodes[1]["status"] = "failed"; used.add(force)
    if any(isinstance(n.get("deps"), list) and len(n["deps"]) > 32 for n in nodes): used.add("dep_plus_de_32")
    if any(isinstance(n.get("deps"), str) for n in nodes): used.add("dep_non_liste")
    if len(nodes) > 200: used.add("plus_de_200")
    plan = {"nodes": nodes}
    if force == "cle_ws_phase_hostile" or rnd.random() < 0.1:
        plan["ws"] = 'z"z\\'; plan["phase"] = "9\n9"; used.add("cle_ws_phase_hostile")
    ids = [n.get("id") for n in nodes if isinstance(n.get("id"), str)]
    if len(ids) != len(set(ids)): used.add("doublon")
    return plan, used
viol = {}
def bad(k, msg): viol.setdefault(k, msg)
cov = dict((k, 0) for k in CLASSES)
chk = {"n": 0}
run("acquire", "--owner=GP", "--step=gen")
for c in range(PLANS):
    plan, used = mkplan(c)
    for k in used: cov[k] += 1
    with open(F, "w") as f: json.dump(plan, f)
    rc, out = run("publish-plan", "--owner=GP", "--file=" + F)
    kept = model(plan["nodes"])
    try:
        pub = json.loads(out)
        if not (rc == 0 and pub["published"] is True and pub["nodes"] == len(kept) and pub["ignored"] == len(plan["nodes"]) - len(kept)):
            bad("gen-plan-noeuds", "plan %d : publish-plan %s (attendu %d gardés, %d ignorés)" % (c, out.strip()[:90], len(kept), len(plan["nodes"]) - len(kept)))
    except Exception:
        bad("gen-plan-json", "plan %d : publish-plan n'est pas un JSON : %r" % (c, out[:80])); continue
    def check(tag, want):
        rc2, so = run("status")
        try: d = json.loads(so)
        except Exception:
            bad("gen-plan-json", "plan %d %s : status n'est pas un JSON" % (c, tag)); return
        chk["n"] += 1
        g = d.get("dag")
        if g is None or g.get("nodes") != want:
            bad("gen-plan-noeuds", "plan %d %s : dag %s, modèle %d nœuds" % (c, tag, "absent" if g is None else "%d nœuds" % len(g.get("nodes", [])), len(want)))
        else:
            if any(sorted(n.keys()) != ["deps", "id", "status"] for n in g["nodes"]):
                bad("gen-plan-noeuds", "plan %d %s : un nœud n'a pas exactement trois clés" % (c, tag))
            if g.get("ws") != "" or g.get("phase") != "":
                bad("gen-plan-noeuds", "plan %d %s : ws/phase du champ ne valent pas la chaîne vide" % (c, tag))
        try: fb = open(P, "rb").read().decode("utf-8", "replace")
        except OSError: fb = ""
        if ("FM%d_" % seed) in so or ("FM%d_" % seed) in fb:
            bad("gen-plan-sans-texte", "plan %d %s : un texte libre est publié (status ou fichier)" % (c, tag))
    check("publié", kept)
    if c % 3 == 0:
        with open(P, "ab") as f:
            f.write('bad"id\tready\t\nokx\tbogus\t\nbad\\id\tready\t\nok2\tready\tbad"dep\n'.encode("utf-8"))
        want = list(kept) + ([{"id": "ok2", "deps": [], "status": "ready"}] if len(kept) < 200 else [])
        check("falsifié", want)
print("graine=%d plans=%d" % (seed, PLANS))
print("couverture : " + " ".join("%s=%d" % (k, cov[k]) for k in CLASSES))
print("plans relus par status : %d" % chk["n"])
if not all(cov.values()): bad("gen-plan-couverture", "classe à 0 : %s" % [k for k in CLASSES if not cov[k]])
if chk["n"] < PLANS: bad("gen-plan-couverture", "seuls %d relectures de status pour %d plans (la propriété n'a pas été jouée)" % (chk["n"], PLANS))
for k in ("gen-plan-json", "gen-plan-noeuds", "gen-plan-sans-texte", "gen-plan-couverture"):
    if k in viol:
        print("MARK %s ko" % k); print("MARKINFO %s %s" % (k, viol[k]))
    else:
        print("MARK %s ok" % k)
PY
}

echo "=== T69.G (propriété générative) et T69.M (mutants M-PLAN-*) : script réel, témoin, puis copies mutées ==="
T69_DIR="$WORK_DIR/t69m"; mkdir -p "$T69_DIR"
T69_SEED="${VF_T69_SEED:-20261112}"
T69_POLICY="$(cd "$(dirname "$SCRIPT")/../.." && pwd)/planning-core/scripts/workstream-policy.sh"
T69_IDS=""; T69_KILLED=0; T69_TOTAL=4; T69_T0=$SECONDS
t69_variant() { # <id> <ancre BRE> <expression sed s> <gen 0|1> : prépare la copie mutée, lance ses scénarios en arrière-plan
  local id="$1" anchor="$2" expr="$3" gen="$4" d="$T69_DIR/$1" n
  mkdir -p "$d"; T69_IDS="$T69_IDS $id"
  cp "$SCRIPT" "$d/driver-lock.sh"; cp "$T69_POLICY" "$d/workstream-policy.sh"; cp "$d/driver-lock.sh" "$d/copie-temoin.sh"
  if [ -n "$anchor" ]; then
    n="$(grep -c -e "$anchor" "$d/driver-lock.sh")"
    if [ "$n" != "1" ]; then echo "ancre non unique ($n occurrences de [$anchor])" > "$d/prepko"; return; fi
    sed -i.bak -e "/$anchor/$expr" "$d/driver-lock.sh"; rm -f "$d/driver-lock.sh.bak"
    if cmp -s "$d/driver-lock.sh" "$d/copie-temoin.sh"; then echo "mutant NON OPPOSABLE : la substitution n'a rien changé" > "$d/prepko"; return; fi
    if ! bash -n "$d/driver-lock.sh" 2>/dev/null; then echo "le mutant n'est pas un script valide" > "$d/prepko"; return; fi
  fi
  chmod +x "$d/driver-lock.sh"
  ( { t69_markers "$d/driver-lock.sh" "$d/w" "$T69_DAG" "$T69_DAG1"; if [ "$gen" = 1 ]; then t69_gen "$d/driver-lock.sh" "$d/g" "$T69_SEED"; fi; } > "$d/out.txt" 2>&1 ) &
}
t69_ko() { sed -n 's/^MARK \(.*\) ko$/\1/p' "$1/out.txt" | LC_ALL=C sort; }
t69_nb() { grep -c '^MARK ' "$1/out.txt"; }
t69_eval() { # <id> <gen 0|1> <attendu : marqueurs séparés par des espaces>
  local id="$1" gen="$2" d="$T69_DIR/$1" want got nb nbw=5
  [ "$gen" = 1 ] && nbw=9
  if [ -f "$d/prepko" ]; then assert_exit "M-PLAN-$id — $(cat "$d/prepko")" 1 0; return; fi
  nb="$(t69_nb "$d")"
  if [ "$nb" != "$nbw" ]; then assert_exit "M-PLAN-$id — scénarios incomplets ($nb marqueurs sur $nbw)" 1 0; sed -n '1,12p' "$d/out.txt"; return; fi
  want="$(printf '%s\n' $3 | LC_ALL=C sort | tr '\n' ' ')"; got="$(t69_ko "$d" | tr '\n' ' ')"
  if [ "$want" = "$got" ]; then
    assert_exit "M-PLAN-$id — mutant tué : bascule exactement {$got}" 0 0
    T69_KILLED=$((T69_KILLED+1))
    for m in $got; do grep "^MARKINFO $m " "$d/out.txt" | head -1 | sed 's/^/      /'; done
  else
    assert_exit "M-PLAN-$id — ensemble basculé INATTENDU" 1 0
    echo "     attendu: {$want}"; echo "     obtenu:  {$got}"
    grep '^MARKINFO ' "$d/out.txt" | head -6 | sed 's/^/      /'
  fi
}
mkdir -p "$T69_DIR/reel"; ( { t69_markers "$SCRIPT" "$T69_DIR/reel/w" "$T69_DAG" "$T69_DAG1"; t69_gen "$SCRIPT" "$T69_DIR/reel/g" "$T69_SEED"; } > "$T69_DIR/reel/out.txt" 2>&1 ) &
t69_variant temoin '' '' 0
t69_variant GENERATION '\$2 != ENVIRON\["PG"\]' 's@\$2 != ENVIRON\["PG"\]@0@' 0
t69_variant TEXTE '",".join(dl)' 's@",".join(dl)@",".join(dl + [str(n.get("step", ""))])@' 1
t69_variant VALIDATION '!okid(id) || !okst(st)' 's@!okid(id) || !okst(st)@0@' 1
t69_variant PROPRIETAIRE '|| plan_refuse not-owner' 's@\[ "$(meta_get owner)" = "$OWNER" \] || plan_refuse not-owner@true@' 0
wait
echo "  graine=$T69_SEED"
sed -n '/^graine=/p;/^couverture :/p' "$T69_DIR/reel/out.txt"
for _t69_m in plan-publie plan-sans-texte plan-perime-masque plan-falsifie plan-proprietaire gen-plan-json gen-plan-noeuds gen-plan-sans-texte gen-plan-couverture; do
  _t69_v=ko; grep -q "^MARK $_t69_m ok\$" "$T69_DIR/reel/out.txt" && _t69_v=ok
  [ "$_t69_v" = ok ]; assert_exit "T69.M réel — marqueur $_t69_m ok" "$?" 0
  case "$_t69_m" in gen-*) assert_exit "T69.G — $_t69_m (script réel)" "$([ "$_t69_v" = ok ] && echo 0 || echo 1)" 0 ;; esac
  [ "$_t69_v" = ok ] || grep "^MARKINFO $_t69_m " "$T69_DIR/reel/out.txt" | sed 's/^/      /'
done
assert_exit "T69.M témoin — la copie non mutée ne bascule aucun marqueur" "$(t69_ko "$T69_DIR/temoin" | wc -l | tr -d ' ')" 0
t69_eval GENERATION 0 "plan-perime-masque"
t69_eval TEXTE 1 "plan-sans-texte gen-plan-sans-texte"
t69_eval VALIDATION 1 "plan-falsifie gen-plan-json gen-plan-noeuds"
t69_eval PROPRIETAIRE 0 "plan-proprietaire"
echo "  durée T69.G + T69.M : $((SECONDS-T69_T0))s"
assert_exit "T69.M — les $T69_TOTAL mutants M-PLAN-* sont tués ($T69_KILLED)" "$([ "$T69_KILLED" = "$T69_TOTAL" ] && echo 0 || echo 1)" 0
rm -rf "$T69_DIR"

echo ""
echo "=================================="
echo "  Résultats : $PASS PASS / $FAIL FAIL"
echo "=================================="
# Garde anti-vert-à-vide STRUCTURELLE, dans l'épilogue lui-même (même patron que
# test-guard-driver-lock.sh §Q5) — pas seulement un cas de test mid-suite qui pourrait être
# neutralisé en même temps que le reste : si AUCUNE assertion n'a tourné (PASS+FAIL == 0), le
# résultat n'est jamais un succès, quel que soit FAIL.
if [ "$((PASS+FAIL))" -eq 0 ]; then
  echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE — zéro assertion exécutée, résultat non fiable"
  exit 1
fi
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
