#!/usr/bin/env bash
# test-guard-driver-lock-phase.sh — guard-driver-lock.sh face a un verrou de PHASE (regle de Samuel, session principale,
# 2026-11-03 ; arbitrage « Un verrou par phase », AskUserQuestion session principale, 2026-11-03).
#
# Suite NEUVE : test-guard-driver-lock-ws.sh (lourde, mutants et A/B) n'est pas touchee. Ici, verrous et guard REELS dans
# un depot jetable (jamais le verrou du vrai depot).
#
#   GP-W   ecriture : la phase tenue par autrui est refusee, la sienne, une autre phase, un fichier partage et un autre
#          compartiment sont permis
#   GP-C   commit : meme jugement sur ce que le commit embarque
#   GP-X   deux phases tenues par deux sessions : chacune ecrit chez elle, pas chez l'autre
#   GP-N   le numero de phase s'apparie sans deborder (6 ne couvre pas 69 ; 41 ne couvre pas 41.1)
#   GP-B   compartiment nu tenu par autrui : refus inchange (non-regression)
#
# PHASE_DL / PHASE_GUARD (optionnels) substituent des copies (rejeu contre l'etat d'avant le correctif).
# Exit 0 si tout passe, 1 sinon, 2 si la fixture est cassee.

set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS="$(cd "$HERE/.." && pwd)"
DRIVER="${PHASE_DL:-$SCRIPTS/driver-lock.sh}"
GUARD="${PHASE_GUARD:-$SCRIPTS/guard-driver-lock.sh}"
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/gd-phase.XXXXXX")" || exit 2
WORK_DIR="$(cd "$WORK_DIR" && pwd -P)"
trap 'rm -rf "$WORK_DIR"' EXIT

PASS=0; FAIL=0
assert()       { if [[ "$2" == *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu (sous-chaîne): $3"; echo "     obtenu:  $2"; FAIL=$((FAIL+1)); fi; }
assert_empty() { if [ -z "$2" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1 (sortie non vide)"; echo "     obtenu:  $2"; FAIL=$((FAIL+1)); fi; }
DENY='"permissionDecision": "deny"'

mk_lab() { # <nom>
  local d="$WORK_DIR/$1"
  mkdir -p "$d/.planning/workstreams/alpha/phases/VFDO-69-a" "$d/.planning/workstreams/alpha/phases/VFDO-70-b" \
           "$d/.planning/workstreams/alpha/phases/VFDO-6-c" "$d/.planning/workstreams/alpha/phases/VFDO-41-d" \
           "$d/.planning/workstreams/alpha/phases/VFDO-41.1-e" "$d/.planning/workstreams/omega"
  printf '# projet\n' > "$d/.planning/PROJECT.md"
  printf 'etat\n' > "$d/.planning/workstreams/alpha/STATE.md"
  printf 'etat\n' > "$d/.planning/workstreams/omega/STATE.md"
  git -C "$d" init -q -b main >/dev/null 2>&1 || git -C "$d" init -q >/dev/null 2>&1
  git -C "$d" add -A >/dev/null 2>&1
  git -C "$d" -c user.email=t@t -c user.name=t -c commit.gpgsign=false commit -q -m init >/dev/null 2>&1
  local gc; gc="$(cd "$d" && git rev-parse --git-common-dir)"; case "$gc" in /*) ;; *) gc="$d/$gc" ;; esac
  gc="$(cd "$gc" && pwd -P)"
  case "$gc" in "$WORK_DIR"/*) ;; *) echo "PRÉFLIGHT FIXTURE CASSÉ — '$gc' hors de '$WORK_DIR'" >&2; exit 2 ;; esac
  printf '%s' "$d"
}
dl() { local lab="$1" sid="$2"; shift 2; ( cd "$lab" && VF_DRIVER_LOCK= CLAUDE_CODE_SESSION_ID="$sid" "$DRIVER" "$@" ); }
mk_write() { python3 -c '
import json, sys
print(json.dumps({"tool_name": "Write", "tool_input": {"file_path": sys.argv[1], "content": "x"}, "session_id": sys.argv[2], "cwd": sys.argv[3]}))' "$1" "$2" "$3"; }
mk_bash() { python3 -c '
import json, sys
print(json.dumps({"tool_name": "Bash", "tool_input": {"command": sys.argv[1]}, "session_id": sys.argv[2], "cwd": sys.argv[3]}))' "$1" "$2" "$3"; }
guard() { local lab="$1" payload="$2"; ( cd "$lab" && printf '%s' "$payload" | env VF_DRIVER_LOCK= bash "$GUARD" 2>/dev/null ); }
gw() { guard "$1" "$(mk_write "$2" "$3" "$1")"; } # <lab> <fichier> <session>
commit_as() { # <lab> <session> <fichier a stager...> : stage puis juge `git commit`
  local lab="$1" sid="$2"; shift 2
  ( cd "$lab" && for f in "$@"; do printf 'm %s\n' "$RANDOM" >> "$f"; git add "$f"; done )
  guard "$lab" "$(mk_bash 'git commit -m x' "$sid" "$lab")"
  ( cd "$lab" && git reset -q >/dev/null 2>&1; git checkout -q -- . >/dev/null 2>&1 )
}

echo "== GP-W : ecritures sous un verrou de phase tenu par sess-A =="
L="$(mk_lab w)"
dl "$L" sess-A acquire --ws=alpha --phase=69 --owner=mgrA --step=s >/dev/null
P69="$L/.planning/workstreams/alpha/phases/VFDO-69-a/PLAN.md"
P70="$L/.planning/workstreams/alpha/phases/VFDO-70-b/PLAN.md"
out="$(gw "$L" "$P69" sess-B)"
assert "GP-W.1 sess-B dans la phase 69 : deny" "$out" "$DENY"
assert "GP-W.2 le motif nomme la phase" "$out" "phase 69 du compartiment"
assert "GP-W.3 reclaim cible la phase" "$out" "driver-lock.sh reclaim --owner=mgrA --ws=alpha --phase=69"
assert_empty "GP-W.4 sess-A (detenteur) dans la phase 69 : permis" "$(gw "$L" "$P69" sess-A)"
assert_empty "GP-W.5 sess-B dans la phase 70 (non tenue) : permis" "$(gw "$L" "$P70" sess-B)"
assert_empty "GP-W.6 fichier partage du compartiment (STATE.md) : permis" "$(gw "$L" "$L/.planning/workstreams/alpha/STATE.md" sess-B)"
assert_empty "GP-W.7 autre compartiment : permis" "$(gw "$L" "$L/.planning/workstreams/omega/STATE.md" sess-B)"
assert "GP-W.8 chemin incertain (workstreams seul) : refus conserve" "$(gw "$L" "$L/.planning/workstreams" sess-B)" "$DENY"

echo "== GP-C : commits =="
out="$(commit_as "$L" sess-B ".planning/workstreams/alpha/phases/VFDO-69-a/PLAN.md")"
assert "GP-C.1 sess-B commite la phase 69 : deny" "$out" "$DENY"
assert_empty "GP-C.2 sess-A (detenteur) commite la phase 69 : accepte" "$(commit_as "$L" sess-A ".planning/workstreams/alpha/phases/VFDO-69-a/PLAN.md")"
assert_empty "GP-C.3 sess-B commite la phase 70 (non tenue) : accepte" "$(commit_as "$L" sess-B ".planning/workstreams/alpha/phases/VFDO-70-b/PLAN.md")"
assert_empty "GP-C.4 sess-B commite le STATE partage : accepte" "$(commit_as "$L" sess-B ".planning/workstreams/alpha/STATE.md")"

echo "== GP-X : deux phases, deux sessions =="
L2="$(mk_lab x)"
dl "$L2" sess-A acquire --ws=alpha --phase=69 --owner=mgrA --step=s >/dev/null
dl "$L2" sess-B acquire --ws=alpha --phase=70 --owner=mgrB --step=s >/dev/null
Q69="$L2/.planning/workstreams/alpha/phases/VFDO-69-a/PLAN.md"; Q70="$L2/.planning/workstreams/alpha/phases/VFDO-70-b/PLAN.md"
assert_empty "GP-X.1 sess-A chez elle (69)" "$(gw "$L2" "$Q69" sess-A)"
assert "GP-X.2 sess-A chez sess-B (70) : deny" "$(gw "$L2" "$Q70" sess-A)" "$DENY"
assert_empty "GP-X.3 sess-B chez elle (70)" "$(gw "$L2" "$Q70" sess-B)"
assert "GP-X.4 sess-B chez sess-A (69) : deny" "$(gw "$L2" "$Q69" sess-B)" "$DENY"

echo "== GP-N : appariement du numero =="
L3="$(mk_lab n)"
dl "$L3" sess-A acquire --ws=alpha --phase=6 --owner=mgrA --step=s >/dev/null
assert_empty "GP-N.1 phase 6 ne couvre pas la 69" "$(gw "$L3" "$L3/.planning/workstreams/alpha/phases/VFDO-69-a/PLAN.md" sess-B)"
assert "GP-N.2 phase 6 couvre VFDO-6-c" "$(gw "$L3" "$L3/.planning/workstreams/alpha/phases/VFDO-6-c/PLAN.md" sess-B)" "$DENY"
L4="$(mk_lab n2)"
dl "$L4" sess-A acquire --ws=alpha --phase=41 --owner=mgrA --step=s >/dev/null
assert_empty "GP-N.3 phase 41 ne couvre pas 41.1" "$(gw "$L4" "$L4/.planning/workstreams/alpha/phases/VFDO-41.1-e/PLAN.md" sess-B)"
assert "GP-N.4 phase 41 couvre VFDO-41-d" "$(gw "$L4" "$L4/.planning/workstreams/alpha/phases/VFDO-41-d/PLAN.md" sess-B)" "$DENY"
L5="$(mk_lab n3)"
dl "$L5" sess-A acquire --ws=alpha --phase=41.1 --owner=mgrA --step=s >/dev/null
assert "GP-N.5 phase 41.1 couvre VFDO-41.1-e" "$(gw "$L5" "$L5/.planning/workstreams/alpha/phases/VFDO-41.1-e/PLAN.md" sess-B)" "$DENY"
assert_empty "GP-N.6 phase 41.1 ne couvre pas VFDO-41-d" "$(gw "$L5" "$L5/.planning/workstreams/alpha/phases/VFDO-41-d/PLAN.md" sess-B)"

echo "== GP-B : compartiment nu tenu par autrui (non-regression) =="
L6="$(mk_lab b)"
dl "$L6" sess-A acquire --ws=alpha --owner=mgrA --step=s >/dev/null
assert "GP-B.1 STATE.md d'alpha : deny" "$(gw "$L6" "$L6/.planning/workstreams/alpha/STATE.md" sess-B)" "$DENY"
assert "GP-B.2 dossier de phase d'alpha : deny" "$(gw "$L6" "$L6/.planning/workstreams/alpha/phases/VFDO-70-b/PLAN.md" sess-B)" "$DENY"
assert_empty "GP-B.3 detenteur : permis" "$(gw "$L6" "$L6/.planning/workstreams/alpha/STATE.md" sess-A)"
assert_empty "GP-B.4 omega : permis" "$(gw "$L6" "$L6/.planning/workstreams/omega/STATE.md" sess-B)"

echo
echo "== bilan : $PASS ok, $FAIL ko =="
[ "$FAIL" -eq 0 ]
