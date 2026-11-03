#!/usr/bin/env bash
# test-driver-lock-phase-consumers.sh — consommateurs du verrou de PHASE autres que le guard (regle de Samuel, session
# principale, 2026-11-03 ; arbitrage « Un verrou par phase », AskUserQuestion session principale, 2026-11-03).
#
#   PC-DAG   dag.sh init --ws --phase lie le DAG a la phase : `mark` avance progress_epoch du verrou DE LA PHASE
#   PC-HLT   check-guard-health.sh nomme la phase dans la ligne du chien de garde (abandon d'un verrou de phase perime)
#   PC-CLM   check-branch-claim.sh voit un verrou de phase pose depuis un autre arbre sur la meme branche
#   PC-EXIT  check-mission-exit.sh --ws --phase juge E1 sur le verrou de la phase
#
# Verrous reels dans un depot jetable, jamais le verrou du vrai depot. Exit 0 si tout passe, 1 sinon, 2 si fixture cassee.
# PHASE_SCRIPTS (optionnel) : dossier de scripts conductor a la place du dossier courant (rejeu contre l'etat d'avant).

set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS="${PHASE_SCRIPTS:-$(cd "$HERE/.." && pwd)}"
PLUGIN_ROOT="$(cd "$SCRIPTS/../.." && pwd)"
MISSION_EXIT="$(cd "$HERE/../../../dev-orchestrator/scripts" && pwd)/check-mission-exit.sh"
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/dl-phasec.XXXXXX")" || exit 2
WORK_DIR="$(cd "$WORK_DIR" && pwd -P)"
trap 'rm -rf "$WORK_DIR"' EXIT

PASS=0; FAIL=0
assert()     { if [[ "$2" == *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: $3"; echo "     obtenu:  $2"; FAIL=$((FAIL+1)); fi; }
assert_not() { if [[ "$2" != *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     interdit: $3"; echo "     obtenu:   $2"; FAIL=$((FAIL+1)); fi; }

mk_lab() { # <nom>
  local d="$WORK_DIR/$1"
  mkdir -p "$d/.planning/workstreams/alpha"
  printf '# projet\n' > "$d/.planning/PROJECT.md"
  printf 'etat\n' > "$d/.planning/workstreams/alpha/STATE.md"
  git -C "$d" init -q -b main >/dev/null 2>&1 || git -C "$d" init -q >/dev/null 2>&1
  git -C "$d" add -A >/dev/null 2>&1
  git -C "$d" -c user.email=t@t -c user.name=t -c commit.gpgsign=false commit -q -m init >/dev/null 2>&1
  local gc; gc="$(cd "$d" && git rev-parse --git-common-dir)"; case "$gc" in /*) ;; *) gc="$d/$gc" ;; esac
  gc="$(cd "$gc" && pwd -P)"
  case "$gc" in "$WORK_DIR"/*) ;; *) echo "PRÉFLIGHT FIXTURE CASSÉ — '$gc' hors de '$WORK_DIR'" >&2; exit 2 ;; esac
  printf '%s' "$d"
}
dl()  { local lab="$1" sid="$2"; shift 2; ( cd "$lab" && VF_DRIVER_LOCK= CLAUDE_CODE_SESSION_ID="$sid" "$SCRIPTS/driver-lock.sh" "$@" ); }
dag() { local lab="$1"; shift; ( cd "$lab" && VF_DRIVER_LOCK= CLAUDE_CODE_SESSION_ID=s "$SCRIPTS/dag.sh" "$@" 2>&1 ); }
epoch_of() { printf '%s' "$1" | sed -n 's/.*"progress_epoch": \([0-9]*\).*/\1/p'; }

echo "== PC-DAG : le DAG d'une phase avance le progres de SA phase =="
L="$(mk_lab dag)"
dl "$L" s acquire --ws=alpha --phase=69 --owner=mgrA --step=s >/dev/null
dl "$L" s acquire --ws=alpha --phase=70 --owner=mgrB --step=s >/dev/null
out="$(dag "$L" init --file=.planning/m.dag.json --ws=alpha --phase=69)"
assert "PC-DAG.1 init porte phase" "$out" '"phase": "69"'
dag "$L" add --file=.planning/m.dag.json --id=n1 --step=x >/dev/null
b69="$(epoch_of "$(dl "$L" s status --ws=alpha --phase=69)")"; b70="$(epoch_of "$(dl "$L" s status --ws=alpha --phase=70)")"
sleep 2
dag "$L" mark --file=.planning/m.dag.json --id=n1 --status=running >/dev/null
a69="$(epoch_of "$(dl "$L" s status --ws=alpha --phase=69)")"; a70="$(epoch_of "$(dl "$L" s status --ws=alpha --phase=70)")"
[ -n "$a69" ] && [ "$a69" -gt "$b69" ]; assert "PC-DAG.2 le progres de la phase 69 avance ($b69 -> $a69)" "$?" "0"
[ -n "$a70" ] && [ "$a70" = "$b70" ]; assert "PC-DAG.3 celui de la phase 70 ne bouge pas ($b70 -> $a70)" "$?" "0"
out="$(dag "$L" mark --file=.planning/m.dag.json --id=n1 --status=done --phase=71)"
assert "PC-DAG.4 --phase refuse hors init" "$out" "--phase n'est admis que par init"
out="$(dag "$L" init --file=.planning/n.dag.json --phase=69)"
assert "PC-DAG.5 --phase sans --ws refuse" "$out" "--phase n'est admis que par init, avec --ws"

echo "== PC-HLT : la ligne du chien de garde nomme la phase =="
L2="$(mk_lab hlt)"
VF_DRIVER_TTL=1 dl "$L2" s acquire --ws=alpha --phase=69 --owner=mgrA --step=s >/dev/null
sleep 3
HD="$WORK_DIR/health-vide"; mkdir -p "$HD"
out="$(cd "$L2" && VF_DRIVER_LOCK= VF_DRIVER_TTL=1 VF_STALL_WINDOW=0 "$SCRIPTS/check-guard-health.sh" --hook --dir="$HD" 2>/dev/null)"
assert "PC-HLT.1 abandon detecte" "$out" "abandon detecte"
assert "PC-HLT.2 la ligne nomme le compartiment et la phase" "$out" "ws=alpha phase=69"

echo "== PC-CLM : un verrou de phase revendique la branche =="
L3="$(mk_lab clm)"
git -C "$L3" worktree add -q -b b2 "$WORK_DIR/wt2" >/dev/null 2>&1
dl "$WORK_DIR/wt2" s acquire --ws=alpha --phase=69 --owner=mgrA --step=s >/dev/null
git -C "$WORK_DIR/wt2" switch -q --detach >/dev/null 2>&1
git -C "$L3" switch -q b2 >/dev/null 2>&1
out="$(cd "$L3" && VF_DRIVER_LOCK= "$SCRIPTS/check-branch-claim.sh" --hook 2>/dev/null)"
assert "PC-CLM.1 signal [branch-claim]" "$out" "[branch-claim]"
assert "PC-CLM.2 le detail nomme la phase" "$out" "phase 69 du compartiment alpha"

echo "== PC-EXIT : E1 juge le verrou de la phase =="
L4="$(mk_lab exit)"
dl "$L4" s acquire --ws=alpha --phase=69 --owner=mgrA --step=s >/dev/null
out="$(cd "$L4" && HOME="$WORK_DIR/home" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" VF_DRIVER_LOCK= bash "$MISSION_EXIT" --root "$L4" --ws alpha --phase 69 --hook 2>&1)"
assert "PC-EXIT.1 phase tenue : manque E1" "$out" "[E1] verrou de driver présent — owner=mgrA"
out="$(cd "$L4" && HOME="$WORK_DIR/home" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" VF_DRIVER_LOCK= bash "$MISSION_EXIT" --root "$L4" --ws alpha --hook 2>&1)"
assert_not "PC-EXIT.2 sans --phase : le compartiment nu est libre, pas de manque E1" "$out" "[E1]"
dl "$L4" s release --ws=alpha --phase=69 --owner=mgrA >/dev/null
out="$(cd "$L4" && HOME="$WORK_DIR/home" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" VF_DRIVER_LOCK= bash "$MISSION_EXIT" --root "$L4" --ws alpha --phase 69 --hook 2>&1)"
assert_not "PC-EXIT.3 phase relachee : plus de manque E1" "$out" "[E1]"

echo
echo "== bilan : $PASS ok, $FAIL ko =="
[ "$FAIL" -eq 0 ]
