#!/usr/bin/env bash
# test-driver-lock-phase.sh — Verrou de driver PAR PHASE, a l'interieur d'un compartiment.
#
# Regle de Samuel (session principale Claude Code, 2026-11-03) : « la regle est de parallèliser le plus possible, pas de
# regle "1 seul manager" » ; arbitrage (AskUserQuestion, session principale, 2026-11-03) : « Un verrou par phase ».
#
# Cette suite est NEUVE et ne touche pas test-driver-lock-ws.sh (temoin de non-regression du compartiment nu, lourd) :
# toute preuve du verrou de phase vit ici. Les cas du compartiment nu restent jugés par la suite d'origine.
#
#   PH-PAR   deux phases d'un meme compartiment s'acquierent en parallele
#   PH-SAME  la meme phase deux fois est refusee (held), le meme owner re-acquiert (reentrant)
#   PH-B2P   compartiment nu demande, phase tenue  -> phase-lock-held (hint release cible)
#   PH-P2B   phase demandee, compartiment nu tenu  -> compartment-lock-held
#   PH-OTH   un autre compartiment reste libre
#   PH-STALE perime : stale-requires-takeover avec le recover cible, takeover de la phase perimee
#   PH-LIFE  heartbeat, mark-progress, release d'une phase ; la liberation rend la main au compartiment nu
#   PH-REG   registre des agents par phase (register --node), frere du verrou de phase
#   PH-INV   noms invalides, --phase sans --ws, --phase avec --depot
#   PH-ALL   status --all liste les verrous de phase
#   PH-FLAT  lab plat : --phase est inerte
#   PH-CONC  un seul gagnant sous concurrence (meme phase) ; au plus un gagnant entre nu et phase
#
# Toute invocation passe par une fixture jetable (depot git sous un dossier temporaire), jamais par le verrou reel du depot.
# PHASE_SCRIPT (optionnel) substitue une copie du script (rejeu contre l'etat d'avant le correctif).
# Exit 0 si tout passe, 1 sinon, 2 si la fixture est cassee.

set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="${PHASE_SCRIPT:-$(cd "$HERE/.." && pwd)/driver-lock.sh}"
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/dl-phase.XXXXXX")" || exit 2
WORK_DIR="$(cd "$WORK_DIR" && pwd -P)"
trap 'rm -rf "$WORK_DIR"' EXIT

PASS=0; FAIL=0
assert()     { if [[ "$2" == *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: $3"; echo "     obtenu:  $2"; FAIL=$((FAIL+1)); fi; }
assert_not() { if [[ "$2" != *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     interdit: $3"; echo "     obtenu:   $2"; FAIL=$((FAIL+1)); fi; }
assert_exit(){ if [ "$2" -eq "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1 (exit $2 ≠ $3)"; FAIL=$((FAIL+1)); fi; }

mk_lab() { # <nom> -> chemin ; compartiments alpha et omega
  local d="$WORK_DIR/$1"
  mkdir -p "$d/.planning/workstreams/alpha" "$d/.planning/workstreams/omega"
  printf '# projet\n' > "$d/.planning/PROJECT.md"
  printf -- '---\nstatus: active\n---\n' > "$d/.planning/workstreams/alpha/STATE.md"
  printf -- '---\nstatus: active\n---\n' > "$d/.planning/workstreams/omega/STATE.md"
  git -C "$d" init -q -b main >/dev/null 2>&1 || git -C "$d" init -q >/dev/null 2>&1
  git -C "$d" add -A >/dev/null 2>&1
  git -C "$d" -c user.email=t@t -c user.name=t -c commit.gpgsign=false commit -q -m init >/dev/null 2>&1
  local gc; gc="$(cd "$d" && git rev-parse --git-common-dir)"; case "$gc" in /*) ;; *) gc="$d/$gc" ;; esac
  gc="$(cd "$gc" && pwd -P)"
  case "$gc" in "$WORK_DIR"/*) ;; *) echo "PRÉFLIGHT FIXTURE CASSÉ — '$gc' hors de '$WORK_DIR'" >&2; exit 2 ;; esac
  printf '%s' "$d"
}
mk_flat() {
  local d="$WORK_DIR/$1"
  mkdir -p "$d/.planning"; printf '# projet\n' > "$d/.planning/PROJECT.md"
  git -C "$d" init -q -b main >/dev/null 2>&1 || git -C "$d" init -q >/dev/null 2>&1
  git -C "$d" add -A >/dev/null 2>&1
  git -C "$d" -c user.email=t@t -c user.name=t -c commit.gpgsign=false commit -q -m init >/dev/null 2>&1
  printf '%s' "$d"
}
dl() { # <lab> <session> <args...>
  local lab="$1" sid="$2"; shift 2
  ( cd "$lab" && VF_DRIVER_LOCK= CLAUDE_CODE_SESSION_ID="$sid" "$SCRIPT" "$@" )
}
rc_of() { local o; o="$("$@")"; local r=$?; printf '%s' "$o"; return $r; }

# ---------------------------------------------------------------------------------------------
echo "== PH-PAR : deux phases du meme compartiment en parallele =="
L="$(mk_lab par)"
o1="$(dl "$L" sA acquire --ws=alpha --phase=69 --owner=mgrA --step=s69)"; r1=$?
o2="$(dl "$L" sB acquire --ws=alpha --phase=70 --owner=mgrB --step=s70)"; r2=$?
assert_exit "PH-PAR.1 phase 69 acquise" "$r1" 0
assert "PH-PAR.2 JSON acquired true" "$o1" '"acquired": true'
assert "PH-PAR.3 scope phase" "$o1" '"scope": "phase"'
assert "PH-PAR.4 phase 69 dans le JSON" "$o1" '"phase": "69"'
assert_exit "PH-PAR.5 phase 70 acquise en parallele (autre owner)" "$r2" 0
assert "PH-PAR.6 phase 70 acquired true" "$o2" '"acquired": true'
s69="$(dl "$L" sA status --ws=alpha --phase=69)"; s70="$(dl "$L" sB status --ws=alpha --phase=70)"
assert "PH-PAR.7 status 69 : owner mgrA" "$s69" '"owner": "mgrA"'
assert "PH-PAR.8 status 70 : owner mgrB" "$s70" '"owner": "mgrB"'
assert "PH-PAR.9 status phase porte scope phase + phase" "$s69" '"scope": "phase", "ws": "alpha", "phase": "69"'
assert "PH-PAR.10 le compartiment nu reste libre de lui-meme" "$(dl "$L" sA status --ws=alpha)" '"present": false'

echo "== PH-SAME : meme phase deux fois =="
o="$(dl "$L" sC acquire --ws=alpha --phase=69 --owner=mgrC --step=x)"; r=$?
assert_exit "PH-SAME.1 refus exit 1" "$r" 1
assert "PH-SAME.2 reason held" "$o" '"reason": "held"'
assert "PH-SAME.3 held_by mgrA" "$o" '"held_by": "mgrA"'
o="$(dl "$L" sA acquire --ws=alpha --phase=69 --owner=mgrA)"; r=$?
assert_exit "PH-SAME.4 meme owner : reentrant" "$r" 0
assert "PH-SAME.5 reentrant true" "$o" '"reentrant": true'

echo "== PH-B2P : compartiment nu demande, phase tenue =="
o="$(dl "$L" sC acquire --ws=alpha --owner=mgrC --step=nu)"; r=$?
assert_exit "PH-B2P.1 refus exit 1" "$r" 1
assert "PH-B2P.2 reason phase-lock-held" "$o" '"reason": "phase-lock-held"'
assert "PH-B2P.3 hint release cible la phase" "$o" 'release --owner=mgrA --ws=alpha --phase=69'
assert "PH-B2P.4 acquired false" "$o" '"acquired": false'
assert "PH-B2P.5 aucun verrou nu pose" "$(dl "$L" sC status --ws=alpha)" '"present": false'

echo "== PH-OTH : un autre compartiment reste libre =="
o="$(dl "$L" sC acquire --ws=omega --owner=mgrC --step=nu)"; r=$?
assert_exit "PH-OTH.1 omega nu acquis malgre les phases d'alpha" "$r" 0
dl "$L" sC release --ws=omega --owner=mgrC >/dev/null

echo "== PH-P2B : phase demandee, compartiment nu tenu =="
L2="$(mk_lab p2b)"
dl "$L2" sA acquire --ws=alpha --owner=mgrA --step=nu >/dev/null
o="$(dl "$L2" sB acquire --ws=alpha --phase=70 --owner=mgrB --step=p70)"; r=$?
assert_exit "PH-P2B.1 refus exit 1" "$r" 1
assert "PH-P2B.2 reason compartment-lock-held" "$o" '"reason": "compartment-lock-held"'
assert "PH-P2B.3 hint release cible le compartiment" "$o" 'release --owner=mgrA --ws=alpha"'
assert "PH-P2B.4 aucun verrou de phase pose" "$(dl "$L2" sB status --ws=alpha --phase=70)" '"present": false'
assert "PH-P2B.5 le verrou nu de mgrA est intact" "$(dl "$L2" sA status --ws=alpha)" '"owner": "mgrA"'
# le compartiment nu tenu continue de fonctionner sans changement : heartbeat, mark-progress
assert "PH-P2B.6 heartbeat du nu inchange" "$(dl "$L2" sA heartbeat --ws=alpha --owner=mgrA)" '"ok": true'
assert "PH-P2B.7 mark-progress du nu inchange" "$(dl "$L2" sA mark-progress --ws=alpha --owner=mgrA)" '"ok": true'

echo "== PH-STALE : verrou de phase perime =="
L3="$(mk_lab stale)"
VF_DRIVER_TTL=1 dl "$L3" sA acquire --ws=alpha --phase=69 --owner=mgrA --step=s >/dev/null
sleep 3
o="$(VF_DRIVER_TTL=1 dl "$L3" sB acquire --ws=alpha --owner=mgrB --step=nu)"; r=$?
assert_exit "PH-STALE.1 nu devant une phase perimee : refus" "$r" 1
assert "PH-STALE.2 stale-requires-takeover" "$o" '"reason": "stale-requires-takeover"'
assert "PH-STALE.3 recover cible la phase" "$o" 'recover --ws=alpha --phase=69'
o="$(VF_DRIVER_TTL=1 dl "$L3" sB acquire --ws=alpha --phase=69 --owner=mgrB --step=s)"; r=$?
assert "PH-STALE.4 acquire de la meme phase perimee : takeover requis" "$o" '"reason": "stale-requires-takeover"'
assert "PH-STALE.5 hint takeover porte la phase" "$o" 'takeover --owner=mgrB --step=<etape> --ws=alpha --phase=69'
o="$(VF_DRIVER_TTL=1 dl "$L3" sB takeover --ws=alpha --phase=69 --owner=mgrB --step=s)"; r=$?
assert_exit "PH-STALE.6 takeover de la phase perimee" "$r" 0
assert "PH-STALE.7 recovered true" "$o" '"recovered": true'
assert "PH-STALE.8 previous_owner mgrA" "$o" '"previous_owner": "mgrA"'

echo "== PH-LIFE : heartbeat, mark-progress, release =="
L4="$(mk_lab life)"
dl "$L4" sA acquire --ws=alpha --phase=70 --owner=mgrA --step=a >/dev/null
assert "PH-LIFE.1 heartbeat" "$(dl "$L4" sA heartbeat --ws=alpha --phase=70 --owner=mgrA)" '"ok": true'
assert "PH-LIFE.2 mark-progress" "$(dl "$L4" sA mark-progress --ws=alpha --phase=70 --owner=mgrA)" '"progress_epoch"'
assert "PH-LIFE.3 heartbeat d'un autre owner refuse" "$(dl "$L4" sB heartbeat --ws=alpha --phase=70 --owner=mgrB)" '"reason": "not-owner"'
assert "PH-LIFE.4 release d'un autre owner refuse" "$(dl "$L4" sB release --ws=alpha --phase=70 --owner=mgrB)" '"reason": "not-owner"'
assert "PH-LIFE.5 release par l'owner" "$(dl "$L4" sA release --ws=alpha --phase=70 --owner=mgrA)" '"released": true'
o="$(dl "$L4" sB acquire --ws=alpha --owner=mgrB --step=nu)"; r=$?
assert_exit "PH-LIFE.6 phase relachee : le compartiment nu s'acquiert" "$r" 0

echo "== PH-REG : registre par phase =="
L5="$(mk_lab reg)"
dl "$L5" sA acquire --ws=alpha --phase=69 --owner=mgrA >/dev/null
dl "$L5" sB acquire --ws=alpha --phase=70 --owner=mgrB >/dev/null
o="$(dl "$L5" sA register --ws=alpha --phase=69 --agent=ag69 --role=vf-coder --node=n1 --depth=2)"; r=$?
assert_exit "PH-REG.1 register" "$r" 0
assert "PH-REG.2 registered true avec node" "$o" '"node": "n1"'
assert "PH-REG.3 registre frere du verrou de phase" "$o" 'phases/69/DRIVER.lock.children.jsonl'
assert "PH-REG.4 orphans de la phase 69" "$(dl "$L5" sA orphans --ws=alpha --phase=69)" '"agent_id": "ag69"'
assert_not "PH-REG.5 la phase 70 ne voit pas l'agent de la 69" "$(dl "$L5" sB orphans --ws=alpha --phase=70)" 'ag69'
assert "PH-REG.6 close" "$(dl "$L5" sA close --ws=alpha --phase=69 --agent=ag69 --status=done)" '"closed": true'

echo "== PH-INV : noms et options invalides =="
for bad in '../x' 'a' '1/2' '.5' '5.' '1..2' ''; do
  o="$(dl "$L5" sA acquire --ws=alpha --phase="$bad" --owner=mgrA 2>&1)"; r=$?
  assert_exit "PH-INV.[$bad] refus" "$r" 1
  assert "PH-INV.[$bad] phase-invalid" "$o" '"reason": "phase-invalid"'
done
o="$(dl "$L5" sA acquire --phase=69 --owner=mgrA)"; r=$?
assert_exit "PH-INV.sans-ws refus" "$r" 1
assert "PH-INV.sans-ws ws-invalid" "$o" '"reason": "ws-invalid"'
o="$(dl "$L5" sA acquire --ws=alpha --phase=69 --depot --owner=mgrA)"; r=$?
assert "PH-INV.depot ws-invalid" "$o" '"reason": "ws-invalid"'
o="$(dl "$L5" sA status --all --phase=69)"
assert "PH-INV.all ws-invalid" "$o" '"error": "ws-invalid"'
o="$(dl "$L5" sA acquire --ws=nope --phase=69 --owner=mgrA)"
assert "PH-INV.unknown-ws" "$o" '"reason": "unknown-ws"'

echo "== PH-ALL : status --all =="
o="$(dl "$L5" sA status --all)"
assert "PH-ALL.1 entree phase 69" "$o" '"scope": "phase", "ws": "alpha", "phase": "69"'
assert "PH-ALL.2 entree phase 70" "$o" '"scope": "phase", "ws": "alpha", "phase": "70"'
assert "PH-ALL.3 present true" "$o" '"present": true'
assert_not "PH-ALL.4 aucune entree nue d'alpha (aucun verrou nu pose)" "$(printf '%s' "$o" | tr -d '\n')" '"scope": "compartiment", "ws": "alpha", "location": "git-common-dir"}, {"present": true'
printf '%s' "$o" | python3 -c 'import json,sys; json.load(sys.stdin)' 2>/dev/null; assert_exit "PH-ALL.5 JSON valide" "$?" 0

echo "== PH-FLAT : lab plat =="
LF="$(mk_flat flat)"
o="$(dl "$LF" sA acquire --ws=alpha --phase=69 --owner=mgrA --step=x)"; r=$?
assert_exit "PH-FLAT.1 acquire accepte (option inerte)" "$r" 0
o="$(dl "$LF" sB acquire --ws=alpha --phase=70 --owner=mgrB --step=x)"; r=$?
assert_exit "PH-FLAT.2 un seul verrou en lab plat : la 2e phase est refusee" "$r" 1

echo "== PH-CONC : concurrence =="
L6="$(mk_lab conc)"
for i in 1 2 3 4 5 6 7 8 9 10 11 12; do
  ( dl "$L6" "s$i" acquire --ws=alpha --phase=69 --owner="m$i" --step=c > "$WORK_DIR/conc.$i" 2>/dev/null ) &
done
wait
w=0; for i in 1 2 3 4 5 6 7 8 9 10 11 12; do grep -q '"acquired": true' "$WORK_DIR/conc.$i" && w=$((w+1)); done
assert "PH-CONC.1 un seul gagnant sur la meme phase (obtenu: $w)" "$w" "1"
for round in 1 2 3 4 5; do
  LR="$(mk_lab "race$round")"
  ( dl "$LR" sA acquire --ws=alpha --owner=nu --step=c > "$WORK_DIR/rn.$round" 2>/dev/null ) &
  ( dl "$LR" sB acquire --ws=alpha --phase=69 --owner=ph --step=c > "$WORK_DIR/rp.$round" 2>/dev/null ) &
  wait
  n=0; grep -q '"acquired": true' "$WORK_DIR/rn.$round" && n=$((n+1)); grep -q '"acquired": true' "$WORK_DIR/rp.$round" && n=$((n+1))
  [ "$n" -le 1 ] && v=ok || v=ko
  assert "PH-CONC.2.$round au plus un gagnant entre nu et phase (obtenu: $n)" "$v" "ok"
done

echo
echo "== bilan : $PASS ok, $FAIL ko =="
[ "$FAIL" -eq 0 ]
