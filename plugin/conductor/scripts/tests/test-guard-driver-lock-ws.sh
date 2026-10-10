#!/usr/bin/env bash
# test-guard-driver-lock-ws.sh — Suite NEUVE du guard de verrou de driver PAR COMPARTIMENT (Phase 57, plan 57-05).
#
# Jamais un ajout à test-guard-driver-lock.sh ni à test-driver-lock.sh : ces deux suites sont le témoin de
# non-régression du lab PLAT (P57-D-03), elles ne bougent pas. Toute preuve neuve du chemin partitionné vit ici.
#
# TRACER (tâche 1) : une écriture dans le compartiment d'une autre session est refusée, le compartiment voisin
# reste libre, le détenteur passe, la racine suit le verrou de dépôt — verrous posés par le VRAI driver-lock.sh,
# guard réel, clone jetable.
#   GW-TRACE-1 deny (motif : compartiment + commande de reclaim) · GW-TRACE-2 voisin libre
#   GW-TRACE-3 détenteur (discriminance) · GW-TRACE-4 racine : libre sous verrou de dépôt libre, deny sinon
#
# Chaque payload porte `cwd` = le clone ; le guard est lancé depuis un sous-shell qui `cd` dans le clone (la
# sonde bash lit le cwd du process). Les payloads sont construits par python, jamais concaténés.
#
# Exit 0 si tout passe, 1 sinon, 2 si la fixture est cassée (préflight).

set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS="$(cd "$HERE/.." && pwd)"
GUARD="$SCRIPTS/guard-driver-lock.sh"
DRIVER="$SCRIPTS/driver-lock.sh"
BASH_BIN="${BASH:-bash}"

# DÉSARMEMENT en tête (P57-D-22) : un VF_DRIVER_LOCK hérité forcerait le régime « verrou unique » et la suite ne
# mesurerait plus rien du chemin partitionné.
unset VF_DRIVER_LOCK VF_DRIVER_CHILDREN VF_DRIVER_TTL VF_DRIVER_SESSION_MAX VF_DRIVER_TEST_DIE_AFTER_MUTEX \
      VF_DRIVER_LOCK_OVERRIDE VF_GUARD_TEST_RAISE GSD_WORKSTREAM VF_WORKSTREAM CLAUDE_CODE_SESSION_ID \
      GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE

WORK_DIR="$(mktemp -d)"
WORK_DIR="$(cd "$WORK_DIR" && pwd -P)"   # macOS : /var → /private/var, comparé canonicalisé
trap 'rm -rf "$WORK_DIR"' EXIT

PASS=0; FAIL=0
assert()       { if [[ "$2" == *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu (sous-chaîne): $3"; echo "     obtenu:  $2"; FAIL=$((FAIL+1)); fi; }
assert_empty() { if [ -z "$2" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1 (sortie non vide)"; echo "     obtenu:  $2"; FAIL=$((FAIL+1)); fi; }
assert_exit()  { if [ "$2" -eq "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1 (exit $2 ≠ $3)"; FAIL=$((FAIL+1)); fi; }

DENY='"permissionDecision": "deny"'

# Dossier commun d'une fixture, canonicalisé (git rendu relatif au cwd, puis pwd -P).
fixture_common_dir() { # <lab>
  local gc
  gc="$(cd "$1" && git rev-parse --git-common-dir 2>/dev/null)" || return 1
  case "$gc" in /*) ;; *) gc="$1/$gc" ;; esac
  (cd "$gc" 2>/dev/null && pwd -P)
}

# PRÉFLIGHT anti-pollution (piège P2) : le dossier commun de la fixture DOIT être sous $WORK_DIR, sinon une
# écriture du driver irait dans le vrai .git du dépôt. Arrêt AVANT toute écriture, exit 2.
lab_preflight() { # <lab>
  local gc; gc="$(fixture_common_dir "$1")" || gc=""
  case "$gc" in
    "$WORK_DIR"/*) return 0 ;;
    *) echo "PRÉFLIGHT FIXTURE CASSÉ — dossier commun '$gc' hors de '$WORK_DIR' : arrêt avant toute écriture" >&2
       exit 2 ;;
  esac
}

# Laboratoire PARTITIONNÉ jetable : dépôt git, deux compartiments (alpha = 1er, omega = dernier).
mk_lab() { # <nom>
  local d="$WORK_DIR/$1"
  mkdir -p "$d/.planning/workstreams/alpha" "$d/.planning/workstreams/omega"
  printf '# projet\n' > "$d/.planning/PROJECT.md"
  printf -- '---\nstatus: active\n---\n' > "$d/.planning/workstreams/alpha/STATE.md"
  printf -- '---\nstatus: active\n---\n' > "$d/.planning/workstreams/omega/STATE.md"
  git -C "$d" init -q -b main >/dev/null 2>&1 || git -C "$d" init -q >/dev/null 2>&1
  git -C "$d" add -A >/dev/null 2>&1
  git -C "$d" -c user.email=t@t -c user.name=t -c commit.gpgsign=false commit -q -m init >/dev/null 2>&1
  lab_preflight "$d"
  printf '%s' "$d"
}

# Invocation du VRAI driver-lock.sh depuis la fixture, sous une session simulée. Jamais depuis le vrai dépôt.
dl() { # <lab> <session> <args...>
  local lab="$1" sid="$2"; shift 2
  ( cd "$lab" && CLAUDE_CODE_SESSION_ID="$sid" "$DRIVER" "$@" )
}

# Payload Write/Edit : file_path absolu, contenu, session, cwd = le clone. `nul` en 5e argument : le chemin
# porte un octet NUL (échappement JSON \u0000), construit par python.
mk_write() { # file_path content session cwd [nul]
  python3 -c '
import json, sys
fp = sys.argv[1] + ("\x00x" if len(sys.argv) > 5 else "")
print(json.dumps({"tool_name": "Write", "tool_input": {"file_path": fp, "content": sys.argv[2]},
                   "session_id": sys.argv[3], "cwd": sys.argv[4]}))' "$@"
}

mk_bash() { # cmd session cwd
  python3 -c '
import json, sys
print(json.dumps({"tool_name": "Bash", "tool_input": {"command": sys.argv[1]},
                   "session_id": sys.argv[2], "cwd": sys.argv[3]}))' "$1" "$2" "$3"
}

# Le guard réel, lancé DEPUIS le clone. Variables d'environnement éventuelles en arguments (NOM=valeur).
run_guard_with() { # <lab> <payload> [NOM=valeur ...]
  local lab="$1" payload="$2"; shift 2
  ( cd "$lab" && printf '%s' "$payload" | env "$@" "$BASH_BIN" "$GUARD" 2>/dev/null )
}
run_guard_in() { run_guard_with "$1" "$2"; }

echo "=== GW-TRACE — écriture sous un compartiment tenu par une autre session, verrous et guard réels ==="
LAB="$(mk_lab trace)"
GC="$(fixture_common_dir "$LAB")"
case "$(bash -n "$GUARD" 2>&1)" in "") assert_exit "GW-PRE — guard syntaxiquement valide" 0 0 ;; *) assert_exit "GW-PRE — guard syntaxiquement valide" 1 0 ;; esac
out="$(dl "$LAB" sess-A acquire --ws=alpha --owner=m1 --step=s1)"
assert "GW-PRE — fixture : alpha acquis par sess-A" "$out" '"acquired": true'
[ -L "$GC/vf-driver/ws/alpha/DRIVER.lock" ]; assert_exit "GW-PRE — fixture : lien du verrou sous le dossier commun du clone" "$?" 0

STATE_A="$LAB/.planning/workstreams/alpha/STATE.md"
STATE_O="$LAB/.planning/workstreams/omega/STATE.md"

out="$(run_guard_in "$LAB" "$(mk_write "$STATE_A" "x" sess-B "$LAB")")"; rc=$?
assert_exit "GW-TRACE-1.1 — Write dans le compartiment d'autrui : exit 0" "$rc" 0
assert "GW-TRACE-1.2 — deny (permissionDecision)" "$out" "$DENY"
assert "GW-TRACE-1.3 — motif : le compartiment alpha est nommé" "$out" "alpha"
assert "GW-TRACE-1.4 — motif : commande exacte de reclaim ciblée" "$out" "driver-lock.sh reclaim --owner=m1 --ws=alpha"

out="$(run_guard_in "$LAB" "$(mk_write "$STATE_O" "x" sess-B "$LAB")")"; rc=$?
assert_exit "GW-TRACE-2.1 — Write dans le compartiment voisin : exit 0" "$rc" 0
assert_empty "GW-TRACE-2.2 — compartiment voisin libre : stdout vide" "$out"

out="$(run_guard_in "$LAB" "$(mk_write "$STATE_A" "x" sess-A "$LAB")")"; rc=$?
assert_exit "GW-TRACE-3.1 — détenteur : exit 0" "$rc" 0
assert_empty "GW-TRACE-3.2 — détenteur dans SON compartiment : stdout vide (discriminance)" "$out"

ROOT_F="$LAB/.planning/PROJECT.md"
out="$(run_guard_in "$LAB" "$(mk_write "$ROOT_F" "x" sess-B "$LAB")")"
assert_empty "GW-TRACE-4.1 — fichier racine, verrou de dépôt libre (alpha tenu) : stdout vide" "$out"
out="$(dl "$LAB" sess-A acquire --depot --owner=md --step=sd)"
assert "GW-PRE — fixture : verrou de dépôt acquis par sess-A" "$out" '"acquired": true'
out="$(run_guard_in "$LAB" "$(mk_write "$ROOT_F" "x" sess-B "$LAB")")"
assert "GW-TRACE-4.2 — fichier racine, verrou de dépôt tenu par autrui : deny" "$out" "$DENY"
assert "GW-TRACE-4.3 — motif : verrou de dépôt, commande de reclaim --depot" "$out" "driver-lock.sh reclaim --owner=md --depot"
out="$(run_guard_in "$LAB" "$(mk_write "$ROOT_F" "x" sess-A "$LAB")")"
assert_empty "GW-TRACE-4.4 — fichier racine, détenteur du dépôt : stdout vide" "$out"

# ---------------------------------------------------------------------------------------------------------------
# Tâche 2 — écritures aux bords : ancien verrou, casse, chemin non cartographiable, worktrees, échappatoire,
# quatre issues (QUAL-01), sondes de crash avant et pendant la décision.
# ---------------------------------------------------------------------------------------------------------------

# Laboratoire PLAT jetable : STATE.md racine, aucun dossier de compartiments.
mk_flat() { # <nom>
  local d="$WORK_DIR/$1"
  mkdir -p "$d/.planning"
  printf '# projet\n' > "$d/.planning/PROJECT.md"
  printf -- '---\nstatus: active\n---\n' > "$d/.planning/STATE.md"
  git -C "$d" init -q -b main >/dev/null 2>&1 || git -C "$d" init -q >/dev/null 2>&1
  git -C "$d" add -A >/dev/null 2>&1
  git -C "$d" -c user.email=t@t -c user.name=t -c commit.gpgsign=false commit -q -m init >/dev/null 2>&1
  lab_preflight "$d"
  printf '%s' "$d"
}

# Ancien verrou unique (.planning/DRIVER.lock) posé par le VRAI driver-lock.sh en régime « verrou unique ».
legacy_acquire() { # <lab> <session> <owner>
  ( cd "$1" && CLAUDE_CODE_SESSION_ID="$2" VF_DRIVER_LOCK=.planning/DRIVER.lock "$DRIVER" acquire --owner="$3" --step=leg )
}

echo
echo "=== GW-W-LEG — ancien verrou unique d'autrui : la racine suit, le compartiment reste libre (P57-D-26) ==="
LAB="$(mk_lab wleg)"
out="$(legacy_acquire "$LAB" sess-A old)"
assert "GW-PRE — fixture : ancien verrou acquis par sess-A" "$out" '"acquired": true'
out="$(run_guard_in "$LAB" "$(mk_write "$LAB/.planning/PROJECT.md" x sess-B "$LAB")")"
assert "GW-W-LEG-1 — Write racine sous l'ancien verrou d'autrui : deny" "$out" "$DENY"
assert "GW-W-LEG-2 — motif : ancien verrou nommé, reclaim au régime VF_DRIVER_LOCK" "$out" "VF_DRIVER_LOCK=.planning/DRIVER.lock driver-lock.sh reclaim --owner=old"
out="$(run_guard_in "$LAB" "$(mk_write "$LAB/.planning/workstreams/alpha/STATE.md" x sess-B "$LAB")")"
assert_empty "GW-W-LEG-3 — Write de compartiment sous l'ancien verrou d'autrui : permis" "$out"
out="$(run_guard_in "$LAB" "$(mk_write "$LAB/.planning/PROJECT.md" x sess-A "$LAB")")"
assert_empty "GW-W-LEG-4 — détenteur de l'ancien verrou : Write racine permis" "$out"

echo
echo "=== GW-W-CASE — le segment de compartiment s'apparie à l'égalité exacte ou casefold ==="
LAB="$(mk_lab wcase)"
dl "$LAB" sess-A acquire --ws=alpha --owner=m1 --step=s >/dev/null
out="$(run_guard_in "$LAB" "$(mk_write "$LAB/.planning/workstreams/ALPHA/STATE.md" x sess-B "$LAB")")"
assert "GW-W-CASE-1 — ALPHA sous le verrou alpha d'autrui : deny (casefold)" "$out" "$DENY"
out="$(run_guard_in "$LAB" "$(mk_write "$LAB/.planning/workstreams/ALPHA/STATE.md" x sess-A "$LAB")")"
assert_empty "GW-W-CASE-2 — le détenteur écrit sous ALPHA : permis (discriminance)" "$out"
out="$(run_guard_in "$LAB" "$(mk_write "$LAB/.planning/WORKSTREAMS/alpha/STATE.md" x sess-B "$LAB")")"
assert "GW-W-CASE-3 — le dossier workstreams lui-même en casse différente : deny" "$out" "$DENY"

echo
echo "=== GW-W-UNMAP — chemin non cartographiable : refusé sous tout verrou d'autrui (T-57-14) ==="
LAB="$(mk_lab wunmap)"
mkdir -p "$LAB/elsewhere"
mv "$LAB/.planning/workstreams/alpha" "$LAB/alpha-gone"
ln -s ../../elsewhere "$LAB/.planning/workstreams/alpha"
[ -L "$LAB/.planning/workstreams/alpha" ]; assert_exit "GW-PRE — fixture : alpha est un lien qui sort de .planning/ (reste dans le lab)" "$?" 0
out="$(run_guard_in "$LAB" "$(mk_write "$LAB/.planning/workstreams/alpha/STATE.md" x sess-B "$LAB")")"
assert_empty "GW-W-UNMAP-0 — lien non cartographiable SANS verrou d'autrui : permis (le refus vient du verrou)" "$out"
dl "$LAB" sess-A acquire --ws=omega --owner=m9 --step=s >/dev/null
out="$(run_guard_in "$LAB" "$(mk_write "$LAB/.planning/workstreams/alpha/STATE.md" x sess-B "$LAB")")"
assert "GW-W-UNMAP-1 — lien qui sort de .planning/, un verrou d'autrui tenu ailleurs : deny" "$out" "$DENY"
out="$(run_guard_in "$LAB" "$(mk_write "$LAB/.planning/workstreams/alpha/STATE.md" x sess-A "$LAB")")"
assert_empty "GW-W-UNMAP-2 — le détenteur du seul verrou tenu : permis" "$out"
out="$(run_guard_in "$LAB" "$(mk_write "$LAB/.planning/workstreams" x sess-B "$LAB")")"
assert "GW-W-UNMAP-3 — « workstreams » seul : non cartographiable, deny sous verrou d'autrui" "$out" "$DENY"

echo
echo "=== GW-LOC — les verrous se résolvent au même endroit que driver-lock.sh (P57-D-07, P57-D-08) ==="
LAB="$(mk_lab loc)"
WT="$WORK_DIR/loc-wt"
git -C "$LAB" worktree add -q -b wtb "$WT" >/dev/null 2>&1
lab_preflight "$WT"
[ -d "$WT/.planning/workstreams" ]; assert_exit "GW-PRE — fixture : le worktree lié est partitionné" "$?" 0
out="$(dl "$WT" sess-A acquire --ws=alpha --owner=mw --step=s)"
assert "GW-PRE — fixture : alpha acquis DEPUIS le worktree" "$out" '"acquired": true'
out="$(run_guard_in "$LAB" "$(mk_write "$LAB/.planning/workstreams/alpha/STATE.md" x sess-B "$LAB")")"
assert "GW-LOC-1.1 — verrou pris depuis un worktree, vu depuis le checkout principal : deny" "$out" "$DENY"
dl "$LAB" sess-A acquire --ws=omega --owner=mp --step=s >/dev/null
out="$(run_guard_in "$WT" "$(mk_write "$WT/.planning/workstreams/omega/STATE.md" x sess-B "$WT")")"
assert "GW-LOC-1.2 — verrou pris depuis le checkout principal, vu depuis le worktree : deny" "$out" "$DENY"
out="$(run_guard_in "$WT" "$(mk_write "$WT/.planning/workstreams/omega/STATE.md" x sess-A "$WT")")"
assert_empty "GW-LOC-1.3 — le détenteur, depuis le worktree : permis" "$out"

# PATH sans git (python joignable) : la lecture documentée du layout `.git` doit retrouver le dossier commun.
LOC_BIN="$WORK_DIR/loc-bin"; mkdir -p "$LOC_BIN"
for t in cat dirname basename sed grep mkdir rm mv date readlink stat uname tr head awk env; do
  p="$(command -v "$t" 2>/dev/null)" && ln -sf "$p" "$LOC_BIN/$t" 2>/dev/null
done
PYP="$(command -v python3 2>/dev/null)"; [ -n "$PYP" ] && ln -sf "$PYP" "$LOC_BIN/python3"
LOC_PRE=1
hash -r   # la table de hachage de bash garde « git » des appels précédents et fausserait le test de PATH
PATH="$LOC_BIN" command -v git >/dev/null 2>&1 && LOC_PRE=0
PATH="$LOC_BIN" command -v python3 >/dev/null 2>&1 || LOC_PRE=0
for t in cat dirname; do [ -x "$LOC_BIN/$t" ] || LOC_PRE=0; done
assert_exit "GW-PRE — fixture : PATH sans git, avec python3" "$LOC_PRE" 1
if [ "$LOC_PRE" -eq 1 ]; then
  out="$(run_guard_with "$LAB" "$(mk_write "$LAB/.planning/workstreams/alpha/STATE.md" x sess-B "$LAB")" PATH="$LOC_BIN")"
  assert "GW-LOC-2.1 — PATH sans git, checkout principal : verrou toujours découvert, deny" "$out" "$DENY"
  out="$(run_guard_with "$WT" "$(mk_write "$WT/.planning/workstreams/omega/STATE.md" x sess-B "$WT")" PATH="$LOC_BIN")"
  assert "GW-LOC-2.2 — PATH sans git, worktree lié (.git fichier + commondir) : verrou toujours découvert, deny" "$out" "$DENY"
  out="$(run_guard_with "$WT" "$(mk_write "$WT/.planning/workstreams/omega/STATE.md" x sess-A "$WT")" PATH="$LOC_BIN")"
  assert_empty "GW-LOC-2.3 — PATH sans git, le détenteur : permis (discriminance)" "$out"
fi

echo
echo "=== GW-MARK-W — l'échappatoire est évaluée APRÈS le calcul du refus, et journalisée à côté du verrou refusant ==="
LAB="$(mk_lab mark)"
GCM="$(fixture_common_dir "$LAB")"
dl "$LAB" sess-A acquire --ws=alpha --owner=m1 --step=s >/dev/null
EVLOG="$GCM/vf-driver/ws/alpha/DRIVER.lock.events.log"
count_override() { if [ -f "$EVLOG" ]; then grep -c '"event": "override"' "$EVLOG" 2>/dev/null || true; else echo 0; fi; }
n0="$(count_override)"
out="$(run_guard_in "$LAB" "$(mk_write "$LAB/.planning/workstreams/alpha/STATE.md" "x vibeflow:allow-lock-override" sess-B "$LAB")")"
assert_empty "GW-MARK-W-1 — marqueur dans le contenu d'un Write qui serait refusé : stdout vide" "$out"
n1="$(count_override)"
assert_exit "GW-MARK-W-2 — une ligne override apparaît dans le journal du verrou refusant" "$((n1 - n0))" 1
out="$(run_guard_in "$LAB" "$(mk_write "$LAB/.planning/workstreams/omega/STATE.md" "x vibeflow:allow-lock-override" sess-B "$LAB")")"
assert_empty "GW-MARK-W-3 — Write permis avec marqueur : stdout vide" "$out"
n2="$(count_override)"
assert_exit "GW-MARK-W-4 — un Write qui serait permis sort sans journal" "$((n2 - n1))" 0
out="$(run_guard_in "$LAB" "$(mk_write "$LAB/.planning/workstreams/alpha/STATE.md" "x" sess-B "$LAB")")"
assert "GW-MARK-W-5 — sans marqueur le même Write reste refusé (discriminance)" "$out" "$DENY"

echo
echo "=== GW-Q — QUAL-01 : quatre issues sur le chemin partitionné ==="
LAB="$(mk_lab q)"
dl "$LAB" sess-A acquire --ws=alpha --owner=m1 --step=s >/dev/null
out="$(run_guard_in "$LAB" "$(mk_write "$LAB/.planning/workstreams/omega/STATE.md" x sess-B "$LAB")")"
assert_empty "GW-Q-PASS — issue 1, PASS : silence (voir GW-TRACE-2)" "$out"
out="$(run_guard_in "$LAB" "$(mk_write "$LAB/.planning/workstreams/alpha/STATE.md" x sess-B "$LAB")")"
assert "GW-Q-DENY — issue 2, DENY : JSON (voir GW-TRACE-1)" "$out" "$DENY"
out="$(run_guard_with "$LAB" 'ceci n est pas du json mais ca contient le mot commit quelque part')"; rc=$?
assert_exit "GW-Q-UNPARSE.1 — payload non JSON : exit 0" "$rc" 0
assert_empty "GW-Q-UNPARSE.2 — payload non JSON : stdout STRICTEMENT vide (issue 3)" "$out"
out="$(run_guard_with "$LAB" '["commit"]')"; rc=$?
assert_exit "GW-Q-UNPARSE-OBJ.1 — JSON valide mais tableau : exit 0" "$rc" 0
assert_empty "GW-Q-UNPARSE-OBJ.2 — JSON valide mais tableau : stdout vide" "$out"
out="$(run_guard_with "$LAB" '')"; rc=$?
assert_exit "GW-Q-EMPTY.1 — payload vide : exit 0" "$rc" 0
assert_empty "GW-Q-EMPTY.2 — payload vide : stdout vide" "$out"
Q_BIN="$WORK_DIR/q-bin"; mkdir -p "$Q_BIN"
for t in cat dirname basename sed grep mkdir rm mv date readlink stat; do
  p="$(command -v "$t" 2>/dev/null)" && ln -sf "$p" "$Q_BIN/$t" 2>/dev/null
done
Q_PRE=1
for t in cat dirname mkdir mv rm date; do [ -x "$Q_BIN/$t" ] || Q_PRE=0; done
if PATH="$Q_BIN" command -v python3 >/dev/null 2>&1 || PATH="$Q_BIN" command -v python >/dev/null 2>&1; then Q_PRE=0; fi
assert_exit "GW-PRE — fixture : outils présents, aucun interprète joignable" "$Q_PRE" 1
if [ "$Q_PRE" -eq 1 ]; then
  Q_HEALTH="$WORK_DIR/q-health"
  out="$(cd "$LAB" && printf '%s' "$(mk_write "$LAB/.planning/workstreams/alpha/STATE.md" x sess-B "$LAB")" | env PATH="$Q_BIN" VF_GUARD_HEALTH_DIR="$Q_HEALTH" "$BASH_BIN" "$GUARD" 2>"$WORK_DIR/q.err")"; rc=$?
  assert_exit "GW-Q-NOPY.1 — interprète indisponible, lab partitionné : code de garde 17 (issue 4)" "$rc" 17
  assert_empty "GW-Q-NOPY.2 — stdout vide" "$out"
  assert "GW-Q-NOPY.3 — diagnostic préfixé sur stderr" "$(cat "$WORK_DIR/q.err" 2>/dev/null)" "guard-driver-lock.sh"
  [ -f "$Q_HEALTH/guard-driver-lock.sh.marker" ] && mk=present || mk=absent
  assert "GW-Q-NOPY.4 — marqueur de santé écrit" "$mk" "present"
fi

echo
echo "=== GW-CRASH — fail-closed : une exception du chemin partitionné rend un refus (T-57-08) ==="
LAB="$(mk_lab crash)"
PAY_W="$(mk_write "$LAB/.planning/workstreams/omega/STATE.md" x sess-B "$LAB")"
out="$(run_guard_with "$LAB" "$PAY_W" VF_GUARD_TEST_RAISE=decide)"; rc=$?
assert_exit "GW-CRASH.1 — exception de la décision : exit 0 (le repli bash ramène le code)" "$rc" 0
assert "GW-CRASH.2 — deny" "$out" "$DENY"
assert "GW-CRASH.3 — motif « erreur interne du guard, fail-closed »" "$out" "erreur interne du guard, fail-closed"
json_ok() { printf '%s' "$1" | python3 -c 'import json,sys; json.load(sys.stdin)' 2>/dev/null; }
json_ok "$out"; assert_exit "GW-CRASH.4 — la sortie est un JSON valide, une seule décision" "$?" 0
errout="$(cd "$LAB" && printf '%s' "$PAY_W" | env VF_GUARD_TEST_RAISE=decide "$BASH_BIN" "$GUARD" 2>&1 >/dev/null)"
assert_empty "GW-CRASH.5 — aucune trace sur stderr" "$errout"
out="$(run_guard_with "$LAB" "$PAY_W" VF_GUARD_TEST_RAISE=autre-valeur)"
assert_empty "GW-CRASH.6 — la sonde est inerte pour toute autre valeur" "$out"

echo
echo "=== GW-CRASH-PRE — exception AVANT la décision : dispatch, règle C6 (T-57-08) ==="
out="$(run_guard_with "$LAB" "$PAY_W" VF_GUARD_TEST_RAISE=dispatch)"; rc=$?
assert_exit "GW-CRASH-PRE-a.1 — sonde « dispatch » : exit 0" "$rc" 0
assert "GW-CRASH-PRE-a.2 — deny « erreur interne » (verrou libre)" "$out" "erreur interne du guard, fail-closed"
NUL_PAY="$(mk_write "$LAB/.planning/workstreams/alpha/STATE.md" x sess-B "$LAB" nul)"
out="$(run_guard_in "$LAB" "$NUL_PAY")"; rc=$?
assert_exit "GW-CRASH-PRE-b.1 — chemin à octet NUL : exit 0" "$rc" 0
assert "GW-CRASH-PRE-b.2 — realpath lève dans la règle C6 : deny « erreur interne » (verrou libre)" "$out" "erreur interne du guard, fail-closed"
dl "$LAB" sess-A acquire --ws=alpha --owner=m1 --step=s >/dev/null
out="$(run_guard_in "$LAB" "$NUL_PAY")"
assert "GW-CRASH-PRE-b.3 — chemin à octet NUL, verrou tenu : deny « erreur interne »" "$out" "erreur interne du guard, fail-closed"
FLAT="$(mk_flat flat)"
legacy_acquire "$FLAT" sess-A old >/dev/null
NUL_FLAT="$(mk_write "$FLAT/.planning/STATE.md" x sess-B "$FLAT" nul)"
out="$(run_guard_in "$FLAT" "$NUL_FLAT")"; rc=$?
assert_exit "GW-CRASH-PRE-c.1 — lab PLAT, même payload à octet NUL : exit 0" "$rc" 0
assert_empty "GW-CRASH-PRE-c.2 — lab PLAT : comportement d'aujourd'hui, stdout vide (repli silencieux conservé)" "$out"
out="$(run_guard_with "$FLAT" "$(mk_write "$FLAT/.planning/STATE.md" x sess-B "$FLAT")" VF_GUARD_TEST_RAISE=dispatch)"
assert "GW-CRASH-PRE-c.3 — lab PLAT : la sonde « dispatch » est inerte, le guard historique refuse (ancien verrou d'autrui)" "$out" "$DENY"
assert_not_internal() { if [[ "$2" != *"erreur interne"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; FAIL=$((FAIL+1)); fi; }
assert_not_internal "GW-CRASH-PRE-c.4 — lab PLAT : aucun refus « erreur interne »" "$out"

# ---------------------------------------------------------------------------------------------------------------
# Plan 57-08 — volet Bash : un commit est jugé sur ce qu'il embarque (P57-D-10, P57-D-18, P57-D-19, P57-D-33).
# Tâche 1 (tracer) : GW-C-IDX, GW-C-EMPTY, GW-NOLOCK. Index RÉEL, guard RÉEL, clone jetable.
# ---------------------------------------------------------------------------------------------------------------
stage()   { git -C "$1" add -- "${@:2}" >/dev/null 2>&1; }   # <lab> <chemins...>
unstage() { git -C "$1" reset -q >/dev/null 2>&1; git -C "$1" checkout -q -- . >/dev/null 2>&1; }   # <lab> : jetable, vide index et arbre suivi
touch_file() { mkdir -p "$(dirname "$2")"; printf 'x %s\n' "$RANDOM" >> "$2"; }   # <lab> <chemin absolu>

echo
echo "=== GW-C-IDX — un commit est jugé sur son index (P57-D-10) ==="
LAB="$(mk_lab cidx)"
dl "$LAB" sess-A acquire --ws=alpha --owner=m1 --step=s >/dev/null
touch_file "$LAB" "$LAB/.planning/workstreams/alpha/STATE.md"; stage "$LAB" .planning/workstreams/alpha/STATE.md
out="$(run_guard_in "$LAB" "$(mk_bash 'git commit -m x' sess-B "$LAB")")"
assert "GW-C-IDX-1 — alpha indexé, alpha tenu par autrui : deny" "$out" "$DENY"
assert "GW-C-IDX-2 — motif : le chemin indexé est cité" "$out" ".planning/workstreams/alpha/STATE.md"
out="$(run_guard_in "$LAB" "$(mk_bash 'git commit -m x' sess-A "$LAB")")"
assert_empty "GW-C-IDX-3 — le détenteur commite son compartiment : stdout vide (discriminance)" "$out"
unstage "$LAB"
touch_file "$LAB" "$LAB/.planning/workstreams/omega/STATE.md"; stage "$LAB" .planning/workstreams/omega/STATE.md
out="$(run_guard_in "$LAB" "$(mk_bash 'git commit -m x' sess-B "$LAB")")"
assert_empty "GW-C-IDX-4 — seul omega indexé (alpha tenu par autrui) : stdout vide" "$out"
unstage "$LAB"
touch_file "$LAB" "$LAB/src/x.sh"; stage "$LAB" src/x.sh
out="$(run_guard_in "$LAB" "$(mk_bash 'git commit -m x' sess-B "$LAB")")"
assert_empty "GW-C-IDX-5 — un fichier de code seul : stdout vide (P57-D-10)" "$out"

echo
echo "=== GW-C-EMPTY — union des sources vide : le commit passe ==="
LAB="$(mk_lab cempty)"
dl "$LAB" sess-A acquire --ws=alpha --owner=m1 --step=s >/dev/null
out="$(run_guard_in "$LAB" "$(mk_bash 'git commit -m x' sess-B "$LAB")")"; rc=$?
assert_exit "GW-C-EMPTY-1 — rien d'indexé : exit 0" "$rc" 0
assert_empty "GW-C-EMPTY-2 — rien d'indexé, pas de -a, verrou alpha d'autrui : stdout vide" "$out"

echo
echo "=== GW-NOLOCK — partition sans verrou : aucun git diff n'est lancé ==="
LAB="$(mk_lab nolock)"
FAKE_BIN="$WORK_DIR/fake-bin"; FAKE_LOG="$WORK_DIR/fake-git.log"; mkdir -p "$FAKE_BIN"; : > "$FAKE_LOG"
REAL_GIT="$(command -v git)"
printf '#!/bin/bash\nprintf "%%s\\n" "$@" >> "%s"\nprintf -- "---\\n" >> "%s"\nexec "%s" "$@"\n' "$FAKE_LOG" "$FAKE_LOG" "$REAL_GIT" > "$FAKE_BIN/git"
chmod +x "$FAKE_BIN/git"
touch_file "$LAB" "$LAB/.planning/workstreams/alpha/STATE.md"; stage "$LAB" .planning/workstreams/alpha/STATE.md
hash -r
out="$(run_guard_with "$LAB" "$(mk_bash 'git commit -m x' sess-B "$LAB")" PATH="$FAKE_BIN:$PATH")"
assert_empty "GW-NOLOCK-1 — aucun verrou : commit permis" "$out"
out="$(run_guard_with "$LAB" "$(mk_write "$LAB/.planning/workstreams/alpha/STATE.md" x sess-B "$LAB")" PATH="$FAKE_BIN:$PATH")"
assert_empty "GW-NOLOCK-2 — aucun verrou : Write permis" "$out"
[ "$(grep -cx 'rev-parse' "$FAKE_LOG" 2>/dev/null || true)" -ge 1 ]; assert_exit "GW-NOLOCK-3 — témoin positif : au moins un rev-parse vu par la sonde" "$?" 0
assert_exit "GW-NOLOCK-4 — aucun git diff lancé (DLWS-06 « empty », volet commit)" "$(grep -cx 'diff' "$FAKE_LOG" 2>/dev/null || true)" 0

# ---------------------------------------------------------------------------------------------------------------
# Tâche 2 — union des sources du commit, fichiers de forme de release, sources illisibles, trois classes de gestes,
# même worktree, échappatoire Bash.
# ---------------------------------------------------------------------------------------------------------------
gb() { # <lab> <cmd> <session> [cwd]   : guard réel sur une commande Bash, lancé depuis le cwd donné (défaut : le lab)
  local lab="$1" cwd="${4:-$1}"
  run_guard_in "$cwd" "$(mk_bash "$2" "$3" "$cwd")"
}

echo
echo "=== GW-C-REN / GW-C-NONASCII — la source est vue malgré le renommage et le nom non ASCII ==="
LAB="$(mk_lab cren)"
dl "$LAB" sess-A acquire --ws=alpha --owner=m1 --step=s >/dev/null
git -C "$LAB" mv .planning/workstreams/alpha/STATE.md .planning/workstreams/omega/MOVED.md >/dev/null 2>&1
out="$(gb "$LAB" 'git commit -m x' sess-B)"
assert "GW-C-REN-1 — alpha/STATE.md renommé vers omega, alpha tenu par autrui : deny (--no-renames)" "$out" "$DENY"
assert "GW-C-REN-2 — motif : la source alpha est citée" "$out" "workstreams/alpha/STATE.md"
LAB="$(mk_lab cnonascii)"
dl "$LAB" sess-A acquire --ws=alpha --owner=m1 --step=s >/dev/null
touch_file "$LAB" "$LAB/.planning/workstreams/alpha/é.md"; stage "$LAB" ".planning/workstreams/alpha/é.md"
out="$(gb "$LAB" 'git commit -m x' sess-B)"
assert "GW-C-NONASCII-1 — alpha/é.md indexé : deny" "$out" "$DENY"
unstage "$LAB"; git -C "$LAB" rm -q --cached -r -f .planning/workstreams/alpha/é.md >/dev/null 2>&1
touch_file "$LAB" "$LAB/é.md"; stage "$LAB" "é.md"
out="$(gb "$LAB" 'git commit -m x' sess-B)"
assert_empty "GW-C-NONASCII-2 — é.md hors .planning/ : stdout vide (jamais une cause de refus)" "$out"

echo
echo "=== GW-C-ALL / GW-C-PATH / GW-C-AMEND — sources hors index (P57-D-19) ==="
LAB="$(mk_lab call)"
dl "$LAB" sess-A acquire --ws=alpha --owner=m1 --step=s >/dev/null
touch_file "$LAB" "$LAB/.planning/workstreams/alpha/STATE.md"
out="$(gb "$LAB" 'git commit -am x' sess-B)"
assert "GW-C-ALL-1 — modification non indexée d'alpha, git commit -am : deny" "$out" "$DENY"
out="$(gb "$LAB" 'git commit --all -m x' sess-B)"
assert "GW-C-ALL-2 — forme longue --all : deny" "$out" "$DENY"
out="$(gb "$LAB" 'git commit -m x' sess-B)"
assert_empty "GW-C-ALL-3 — sans -a, la même modification non indexée n'est pas embarquée : stdout vide (discriminance)" "$out"
out="$(gb "$LAB" 'git commit -m x -- .planning/workstreams/alpha/STATE.md' sess-B)"
assert "GW-C-PATH-1 — pathspec sur alpha : deny" "$out" "$DENY"
out="$(gb "$LAB" 'git commit -m x -- src/x.sh' sess-B)"
assert "GW-C-PATH-2 — pathspec sur un autre chemin, même modification non indexée d'alpha : deny (doute = union)" "$out" "$DENY"
LAB="$(mk_lab camend)"
dl "$LAB" sess-A acquire --ws=alpha --owner=m1 --step=s >/dev/null
touch_file "$LAB" "$LAB/.planning/workstreams/alpha/STATE.md"
GIT_T() { git -c user.email=t@t -c user.name=t -c commit.gpgsign=false "$@"; }
git -C "$LAB" add -A >/dev/null 2>&1; GIT_T -C "$LAB" commit -q -m "touche alpha" >/dev/null 2>&1
out="$(gb "$LAB" 'git commit --amend --no-edit' sess-B)"
assert "GW-C-AMEND-1 — HEAD touche alpha, --amend : deny" "$out" "$DENY"
out="$(gb "$LAB" 'git commit -m x' sess-B)"
assert_empty "GW-C-AMEND-2 — sans --amend, HEAD n'est pas embarqué : stdout vide (discriminance)" "$out"
touch_file "$LAB" "$LAB/.planning/workstreams/omega/STATE.md"
git -C "$LAB" add -A >/dev/null 2>&1; GIT_T -C "$LAB" commit -q -m "touche omega" >/dev/null 2>&1
out="$(gb "$LAB" 'git commit --amend --no-edit' sess-B)"
assert_empty "GW-C-AMEND-3 — HEAD ne touche qu'omega, --amend : stdout vide" "$out"

echo
echo "=== GW-C-ADD — un git add de la même commande entre dans le jugement (P57-D-33) ==="
LAB="$(mk_lab cadd)"
dl "$LAB" sess-A acquire --ws=alpha --owner=m1 --step=s >/dev/null
out="$(gb "$LAB" 'git add .planning/workstreams/alpha/STATE.md && git commit -m x' sess-B)"
assert "GW-C-ADD-1 — add littéral d'alpha puis commit (index vide au moment du hook) : deny" "$out" "$DENY"
touch_file "$LAB" "$LAB/.planning/workstreams/alpha/new.md"
out="$(gb "$LAB" 'git add . && git commit -m x' sess-B)"
assert "GW-C-ADD-2 — git add . avec un non-suivi dans alpha : deny" "$out" "$DENY"
out="$(gb "$LAB" 'git add -A && git commit -m x' sess-B)"
assert "GW-C-ADD-3 — git add -A : deny" "$out" "$DENY"
out="$(gb "$LAB" 'git add src/x.sh && git commit -m x' sess-B)"
assert_empty "GW-C-ADD-4 — add d'un fichier de code seul : stdout vide" "$out"
out="$(gb "$LAB" 'git add .planning/workstreams/omega/STATE.md && git commit -m x' sess-B)"
assert_empty "GW-C-ADD-5 — add littéral d'omega : stdout vide" "$out"
out="$(gb "$LAB" 'git add .planning/workstreams/alpha/STATE.md && git commit -m x' sess-A)"
assert_empty "GW-C-ADD-6 — le détenteur : stdout vide (discriminance)" "$out"

echo
echo "=== GW-C-REL — fichiers de forme de release = gestes de dépôt (P57-D-18) ==="
LAB="$(mk_lab crel)"
printf '1.0.0\n' > "$LAB/VERSION"; mkdir -p "$LAB/docs"; printf '# adr\n' > "$LAB/docs/ADR.md"; printf '# b\n' > "$LAB/.planning/BACKLOG.md"
git -C "$LAB" add -A >/dev/null 2>&1; GIT_T -C "$LAB" commit -q -m "base" >/dev/null 2>&1
dl "$LAB" sess-A acquire --ws=alpha --owner=m1 --step=s >/dev/null
for f in VERSION docs/ADR.md .planning/BACKLOG.md; do
  touch_file "$LAB" "$LAB/$f"; stage "$LAB" "$f"
  out="$(gb "$LAB" 'git commit -m x' sess-B)"
  assert_empty "GW-C-REL-libre — $f, aucun verrou de dépôt (alpha seul tenu) : stdout vide" "$out"
  unstage "$LAB"
done
dl "$LAB" sess-A acquire --depot --owner=md --step=sd >/dev/null
for f in VERSION docs/ADR.md .planning/BACKLOG.md; do
  touch_file "$LAB" "$LAB/$f"; stage "$LAB" "$f"
  out="$(gb "$LAB" 'git commit -m x' sess-B)"
  assert "GW-C-REL-tenu — $f, verrou de dépôt d'autrui : deny" "$out" "$DENY"
  out="$(gb "$LAB" 'git commit -m x' sess-A)"
  assert_empty "GW-C-REL-detenteur — $f, détenteur du dépôt : stdout vide" "$out"
  unstage "$LAB"
done
touch_file "$LAB" "$LAB/src/x.sh"; stage "$LAB" src/x.sh
out="$(gb "$LAB" 'git commit -m x' sess-B)"
assert_empty "GW-C-REL-code — fichier de code seul sous verrou de dépôt d'autrui : stdout vide (P57-D-10)" "$out"

echo
echo "=== GW-C-CORRUPT / GW-C-NOGITBIN — source illisible = refus, jamais ouverture (P57-D-10, P57-D-33) ==="
LAB="$(mk_lab ccorrupt)"
GCC="$(fixture_common_dir "$LAB")"
dl "$LAB" sess-A acquire --ws=alpha --owner=m1 --step=s >/dev/null
printf 'ceci n est pas un index git' > "$GCC/index"
out="$(gb "$LAB" 'git commit -m x' sess-B)"
assert "GW-C-CORRUPT-1 — index corrompu (rc 128), un verrou d'autrui : deny" "$out" "$DENY"
assert "GW-C-CORRUPT-2 — motif : source illisible, source nommée" "$out" "source illisible : diff --cached"
out="$(gb "$LAB" 'git commit -m x' sess-A)"
assert_empty "GW-C-CORRUPT-3 — le détenteur n'est pas refusé par une source illisible : stdout vide" "$out"
LAB="$(mk_lab cnogit)"
dl "$LAB" sess-A acquire --ws=alpha --owner=m1 --step=s >/dev/null
hash -r
if [ "$LOC_PRE" -eq 1 ]; then
  out="$(run_guard_with "$LAB" "$(mk_bash 'git commit -m x' sess-B "$LAB")" PATH="$LOC_BIN")"
  assert "GW-C-NOGITBIN-1 — PATH sans git, un verrou d'autrui (découvert par le layout) : deny" "$out" "$DENY"
  assert "GW-C-NOGITBIN-2 — motif : source illisible" "$out" "source illisible"
  out="$(run_guard_with "$LAB" "$(mk_bash 'git commit -m x' sess-A "$LAB")" PATH="$LOC_BIN")"
  assert_empty "GW-C-NOGITBIN-3 — PATH sans git, le détenteur : stdout vide" "$out"
else
  assert_exit "GW-C-NOGITBIN — fixture PATH sans git indisponible" 1 0
fi

echo
echo "=== GW-T-SAME / GW-T-OTHERWT / GW-T-EXEMPT / GW-T-REMOVE / GW-T-C — gestes d'arbre, même worktree (P57-D-11, P57-D-16, P57-D-17) ==="
LAB="$(mk_lab tree)"
WTT="$WORK_DIR/tree-wt"
git -C "$LAB" worktree add -q -b wtt "$WTT" >/dev/null 2>&1
lab_preflight "$WTT"
dl "$LAB" sess-A acquire --ws=omega --owner=m1 --step=s >/dev/null
for c in 'git checkout -b x' 'git switch main' 'git reset --hard' 'git rebase main' 'git stash' 'git restore src/x.sh' 'git clean -fd' 'git merge main' 'git cherry-pick abc' 'git revert abc'; do
  out="$(gb "$LAB" "$c" sess-B)"
  assert "GW-T-SAME — « $c » depuis le checkout où le verrou a été pris : deny" "$out" "$DENY"
done
out="$(gb "$LAB" 'git reset --hard' sess-A)"
assert_empty "GW-T-SAME-detenteur — le détenteur : stdout vide (discriminance)" "$out"
for c in 'git checkout -b x' 'git switch main' 'git reset --hard' 'git rebase main' 'git stash' 'git clean -fd'; do
  out="$(gb "$LAB" "$c" sess-B "$WTT")"
  assert_empty "GW-T-OTHERWT — « $c » depuis un AUTRE worktree : stdout vide (P57-D-17)" "$out"
done
out="$(gb "$LAB" 'git worktree add ../w -b w' sess-B)"
assert_empty "GW-T-EXEMPT-1 — git worktree add : exemption D-32-06 intacte" "$out"
out="$(gb "$LAB" 'git rebase --abort' sess-B)"
assert_empty "GW-T-EXEMPT-2 — git rebase --abort : exemption D-32-06 intacte" "$out"
out="$(gb "$LAB" 'git rebase main' sess-B)"
assert "GW-T-EXEMPT-3 — git rebase sans option de sortie reste refusé (exemption non élargie)" "$out" "$DENY"
out="$(gb "$LAB" 'git worktree remove ../w' sess-B "$WTT")"
assert "GW-T-REMOVE-1 — git worktree remove depuis un autre worktree : deny" "$out" "$DENY"
out="$(gb "$LAB" 'git worktree remove ../w' sess-B)"
assert "GW-T-REMOVE-2 — git worktree remove depuis le même checkout : deny" "$out" "$DENY"
UNDER="$LAB/.wts/under"
git -C "$LAB" worktree add -q -b under "$UNDER" >/dev/null 2>&1
out="$(gb "$LAB" "git -C $UNDER reset --hard" sess-B "$WTT")"
assert "GW-T-C-1 — git -C vers un autre worktree rangé sous le lab : cible incertaine, deny" "$out" "$DENY"
out="$(gb "$LAB" "git -C $UNDER reset --hard" sess-A "$WTT")"
assert_empty "GW-T-C-2 — le détenteur : stdout vide (discriminance)" "$out"
out="$(gb "$LAB" "git -C $WORK_DIR reset --hard" sess-B)"
assert_empty "GW-T-C-3 — git -C vers un dossier hors du lab : C7 inchangé, stdout vide" "$out"
# verrou pris depuis un autre worktree : les gestes d'arbre du checkout principal ne sont pas refusés
LAB="$(mk_lab tree2)"
WT2="$WORK_DIR/tree2-wt"
git -C "$LAB" worktree add -q -b wt2 "$WT2" >/dev/null 2>&1
lab_preflight "$WT2"
dl "$WT2" sess-A acquire --ws=omega --owner=m1 --step=s >/dev/null
out="$(gb "$LAB" 'git reset --hard' sess-B)"
assert_empty "GW-T-OTHERWT-bis — verrou pris depuis un worktree lié, geste depuis le checkout principal : stdout vide" "$out"
out="$(gb "$LAB" 'git reset --hard' sess-B "$WT2")"
assert "GW-T-SAME-bis — même verrou, geste depuis le worktree qui l'a pris : deny" "$out" "$DENY"

echo
echo "=== GW-D-PUSH / GW-D-TAG — gestes de dépôt (P57-D-16, P57-D-02) ==="
LAB="$(mk_lab dpush)"
dl "$LAB" sess-A acquire --ws=alpha --owner=m1 --step=s >/dev/null
for c in 'git push' 'git branch -D x' 'gh pr create' 'git tag v1' 'gh release create v1'; do
  out="$(gb "$LAB" "$c" sess-B)"
  assert_empty "GW-D-PUSH — « $c » sous un verrou de compartiment d'autrui : stdout vide" "$out"
done
dl "$LAB" sess-A acquire --depot --owner=md --step=sd >/dev/null
for c in 'git push' 'git branch -D x' 'gh pr create' 'git tag v1' 'gh release create v1'; do
  out="$(gb "$LAB" "$c" sess-B)"
  assert "GW-D-TAG — « $c » sous le verrou de dépôt d'autrui : deny" "$out" "$DENY"
done
out="$(gb "$LAB" 'git tag v1' sess-A)"
assert_empty "GW-D-TAG-detenteur — le détenteur du dépôt : stdout vide (discriminance)" "$out"

echo
echo "=== GW-MARK-B — l'échappatoire Bash est évaluée APRÈS le calcul du refus, journal à côté de chaque verrou refusant ==="
LAB="$(mk_lab markb)"
GCB="$(fixture_common_dir "$LAB")"
dl "$LAB" sess-A acquire --ws=alpha --owner=m1 --step=s >/dev/null
dl "$LAB" sess-A acquire --ws=omega --owner=m2 --step=s >/dev/null
EV_A="$GCB/vf-driver/ws/alpha/DRIVER.lock.events.log"; EV_O="$GCB/vf-driver/ws/omega/DRIVER.lock.events.log"
cnt() { if [ -f "$1" ]; then grep -c '"event": "override"' "$1" 2>/dev/null || true; else echo 0; fi; }
a0="$(cnt "$EV_A")"; o0="$(cnt "$EV_O")"
out="$(gb "$LAB" 'git reset --hard # vibeflow:allow-lock-override' sess-B)"
assert_empty "GW-MARK-B-1 — marqueur dans un geste qui serait refusé : stdout vide" "$out"
assert_exit "GW-MARK-B-2 — une ligne override à côté du verrou alpha" "$(( $(cnt "$EV_A") - a0 ))" 1
assert_exit "GW-MARK-B-3 — une ligne override à côté du verrou omega" "$(( $(cnt "$EV_O") - o0 ))" 1
a1="$(cnt "$EV_A")"
out="$(gb "$LAB" 'git push # vibeflow:allow-lock-override' sess-B)"
assert_empty "GW-MARK-B-4 — geste permis avec marqueur : stdout vide" "$out"
assert_exit "GW-MARK-B-5 — un geste qui serait permis sort sans journal" "$(( $(cnt "$EV_A") - a1 ))" 0
out="$(gb "$LAB" 'git reset --hard' sess-B)"
assert "GW-MARK-B-6 — sans marqueur le même geste reste refusé (discriminance)" "$out" "$DENY"

echo
echo "=== Bilan : $PASS PASS · $FAIL FAIL ==="
echo "== resultat : $PASS ok, $FAIL ko =="
[ "$PASS" -gt 0 ] || { echo "❌ FAIL — zéro assertion exécutée"; exit 1; }
[ "$FAIL" -eq 0 ]
