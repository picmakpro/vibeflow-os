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
# Plan 57-11 : GW-AB (le guard d'un lab PLAT rend, sur une matrice de payloads, les mêmes stdout/stderr/code que la
# copie gelée d'avant la phase, au bit près, deux régimes de verrou), GW-AB-INTEGRITE (T-57-40) et les douze mutants
# GW-M-a à GW-M-l (QUAL-01 : chaque comportement neuf du guard rougit sous sa mutation, ensemble basculé exact).
#
# Exit 0 si tout passe, 1 sinon, 2 si la fixture est cassée (préflight).

set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS="$(cd "$HERE/.." && pwd)"
GUARD="$SCRIPTS/guard-driver-lock.sh"
DRIVER="$SCRIPTS/driver-lock.sh"
BASH_BIN="${BASH:-bash}"
# Mode de la suite. `full` (défaut) : tout, A/B et mutants compris. `matrice` : sous-processus d'un mutant (GW-M-*),
# qui rejoue les cas GW-* (A/B exclu) contre une COPIE mutée du guard (GW_GUARD) posée à côté de vf-portable.sh ;
# ni A/B ni mutants (pas de récursion).
GW_MODE="${GW_MODE:-full}"
SUITE="$HERE/$(basename "$0")"
[ -z "${GW_GUARD:-}" ] || GUARD="$GW_GUARD"
PORTABLE="$(cd "$SCRIPTS/../../_internal/lib" && pwd)/vf-portable.sh"

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

# R-6 : le guard de production ne porte AUCUN crochet de test. Les exceptions du chemin partitionné sont provoquées
# dans une COPIE du guard fabriquée ici, dans le dossier temporaire de la suite (la copie est faite du guard sous
# test, mutant éventuel compris) : une ligne `raise` est insérée à un point d'ancrage unique ; le reste du programme
# (crochet fail-closed compris) est celui du guard mesuré.
mk_raise_copy() { # <decide|dispatch> <dossier> : écrit <dossier>/guard-driver-lock.sh, côte à côte avec vf-portable.sh
  mkdir -p "$2"; cp "$PORTABLE" "$2/vf-portable.sh"
  python3 -I - "$GUARD" "$2/guard-driver-lock.sh" "$1" <<'PYRAISE'
import sys
src, dst, point = sys.argv[1], sys.argv[2], sys.argv[3]
t = open(src, encoding="utf-8").read()
if point == "decide":
    a = '    if tool == "Bash":\n        if not bash_command_concerned(target):\n'
    b = '    raise RuntimeError("sonde de la suite : exception de la decision")\n' + a
else:
    a = '\ntool = payload.get("tool_name") or ""\n'
    b = '\nif PARTITIONED:\n    raise RuntimeError("sonde de la suite : exception du dispatch")\n' + a[1:]
if t.count(a) != 1:
    sys.stderr.write("ancre non unique (%d) pour %s\n" % (t.count(a), point)); sys.exit(3)
open(dst, "w", encoding="utf-8").write(t.replace(a, b))
PYRAISE
  chmod +x "$2/guard-driver-lock.sh"
}
run_guard_copy() { # <guard> <lab> <payload>
  ( cd "$2" && printf '%s' "$3" | env "$BASH_BIN" "$1" 2>/dev/null )
}

echo
echo "=== GW-CRASH — fail-closed : une exception du chemin partitionné rend un refus (T-57-08 ; R-6 : exception injectée dans une copie, aucun crochet en production) ==="
LAB="$(mk_lab crash)"
PAY_W="$(mk_write "$LAB/.planning/workstreams/omega/STATE.md" x sess-B "$LAB")"
mk_raise_copy decide "$WORK_DIR/raise-decide"; assert_exit "GW-CRASH.0 — copie « exception de la décision » fabriquée (ancre unique)" "$?" 0
RAISE_DECIDE="$WORK_DIR/raise-decide/guard-driver-lock.sh"
out="$(run_guard_copy "$RAISE_DECIDE" "$LAB" "$PAY_W")"; rc=$?
assert_exit "GW-CRASH.1 — exception de la décision : exit 0 (le repli bash ramène le code)" "$rc" 0
assert "GW-CRASH.2 — deny" "$out" "$DENY"
assert "GW-CRASH.3 — motif « erreur interne du guard, fail-closed »" "$out" "erreur interne du guard, fail-closed"
json_ok() { printf '%s' "$1" | python3 -c 'import json,sys; json.load(sys.stdin)' 2>/dev/null; }
json_ok "$out"; assert_exit "GW-CRASH.4 — la sortie est un JSON valide, une seule décision" "$?" 0
errout="$(cd "$LAB" && printf '%s' "$PAY_W" | env "$BASH_BIN" "$RAISE_DECIDE" 2>&1 >/dev/null)"
assert_empty "GW-CRASH.5 — aucune trace sur stderr" "$errout"
out="$(run_guard_with "$LAB" "$PAY_W" VF_GUARD_TEST_RAISE=decide)"
assert_empty "GW-CRASH.6 — le guard de production ignore VF_GUARD_TEST_RAISE=decide (aucun crochet de test en production)" "$out"
out="$(run_guard_with "$LAB" "$PAY_W" VF_GUARD_TEST_RAISE=dispatch)"
assert_empty "GW-CRASH.7 — le guard de production ignore VF_GUARD_TEST_RAISE=dispatch" "$out"
assert_exit "GW-CRASH.8 — le texte du guard ne contient plus aucune lecture de VF_GUARD_TEST_RAISE" "$(grep -c 'VF_GUARD_TEST_RAISE' "$GUARD" || true)" 0

echo
echo "=== GW-CRASH-PRE — exception AVANT la décision : dispatch, règle C6 (T-57-08) ==="
mk_raise_copy dispatch "$WORK_DIR/raise-dispatch"; assert_exit "GW-CRASH-PRE-a.0 — copie « exception du dispatch » fabriquée (ancre unique)" "$?" 0
RAISE_DISPATCH="$WORK_DIR/raise-dispatch/guard-driver-lock.sh"
out="$(run_guard_copy "$RAISE_DISPATCH" "$LAB" "$PAY_W")"; rc=$?
assert_exit "GW-CRASH-PRE-a.1 — exception du dispatch : exit 0" "$rc" 0
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
out="$(run_guard_copy "$RAISE_DISPATCH" "$FLAT" "$(mk_write "$FLAT/.planning/STATE.md" x sess-B "$FLAT")")"
assert "GW-CRASH-PRE-c.3 — lab PLAT : l'exception du dispatch n'est pas levée, le guard historique refuse (ancien verrou d'autrui)" "$out" "$DENY"
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
  assert "GW-C-NOGITBIN-4 — motif : la source nommée est rev-parse --show-toplevel (pas une exception interne)" "$out" "source illisible : rev-parse --show-toplevel"
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
out="$(gb "$LAB" "git -C $UNDER reset --hard" sess-B)"
assert "GW-T-C-1 — git -C vers un autre worktree rangé sous le lab : cible incertaine, deny" "$out" "$DENY"
out="$(gb "$LAB" "git -C $UNDER reset --hard" sess-A)"
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
echo "=== GW-UNREAD — lab partitionné : un verrou, ou un dossier de verrous, qui EXISTE mais est illisible = refus nommé, jamais « pas de verrou » (P57-D-33, correction R-2) ==="
LAB="$(mk_lab unread1)"; GCU="$(fixture_common_dir "$LAB")"
dl "$LAB" sess-A acquire --ws=alpha --owner=m1 --step=s >/dev/null
W_A="$LAB/.planning/workstreams/alpha/STATE.md"
out="$(run_guard_in "$LAB" "$(mk_write "$W_A" x sess-B "$LAB")")"
assert "GW-UNREAD-0 — témoin : alpha tenu par autrui, lisible : deny" "$out" "$DENY"
chmod 000 "$GCU/vf-driver/ws"
out="$(run_guard_in "$LAB" "$(mk_write "$W_A" x sess-B "$LAB")")"; rc=$?
chmod 755 "$GCU/vf-driver/ws"
assert_exit "GW-UNREAD-1.1 — dossier des verrous de compartiments illisible : exit 0" "$rc" 0
assert "GW-UNREAD-1.2 — Write dans alpha : deny, jamais un allow silencieux" "$out" "$DENY"
assert "GW-UNREAD-1.3 — le refus nomme l'illisibilité du verrou" "$out" "illisible"
chmod 000 "$GCU/vf-driver/ws"
out="$(run_guard_in "$LAB" "$(mk_bash 'git commit -m x' sess-B "$LAB")")"
chmod 755 "$GCU/vf-driver/ws"
assert "GW-UNREAD-1.4 — geste Bash concerné : deny aussi" "$out" "$DENY"
assert "GW-UNREAD-1.5 — le refus nomme l'illisibilité du verrou" "$out" "illisible"
chmod 000 "$GCU/vf-driver/ws/alpha/DRIVER.lock/meta"
out="$(run_guard_in "$LAB" "$(mk_write "$W_A" x sess-B "$LAB")")"
chmod 644 "$GCU/vf-driver/ws/alpha/DRIVER.lock/meta"
assert "GW-UNREAD-2.1 — meta d'alpha illisible : deny, jamais un allow silencieux" "$out" "$DENY"
assert "GW-UNREAD-2.2 — le refus nomme l'illisibilité du verrou" "$out" "illisible"
out="$(run_guard_in "$LAB" "$(mk_write "$W_A" x sess-B "$LAB")")"
assert "GW-UNREAD-2.3 — droits rendus : le refus redevient celui du verrou tenu (témoin)" "$out" "tenu par"
LAB="$(mk_lab unread3)"
out="$(run_guard_in "$LAB" "$(mk_write "$LAB/.planning/workstreams/alpha/STATE.md" x sess-B "$LAB")")"
assert_empty "GW-UNREAD-3 — aucun verrou, aucun dossier de verrous : permis (pas de sur-refus)" "$out"
LAB="$(mk_lab unread4)"; GCU="$(fixture_common_dir "$LAB")"
mkdir -p "$GCU/vf-driver/ws/alpha/DRIVER.lock"
out="$(run_guard_in "$LAB" "$(mk_write "$LAB/.planning/workstreams/alpha/STATE.md" x sess-B "$LAB")")"
assert_empty "GW-UNREAD-4 — dossier de verrou sans meta (verrou en cours de pose) : permis, comportement historique" "$out"
FLAT="$(mk_flat unread5)"
legacy_acquire "$FLAT" sess-A old >/dev/null
out="$(run_guard_in "$FLAT" "$(mk_write "$FLAT/.planning/STATE.md" x sess-B "$FLAT")")"
assert "GW-UNREAD-5.1 — témoin lab PLAT : verrou d'autrui lisible, deny" "$out" "$DENY"
chmod 000 "$FLAT/.planning/DRIVER.lock/meta"
out="$(run_guard_in "$FLAT" "$(mk_write "$FLAT/.planning/STATE.md" x sess-B "$FLAT")")"
chmod 644 "$FLAT/.planning/DRIVER.lock/meta"
assert_empty "GW-UNREAD-5.2 — lab PLAT, meta illisible : allow, posture historique inchangée (Q3c)" "$out"

echo
echo "=== GW-TTL — un verrou PÉRIMÉ d'autrui n'est plus un verrou (règle 2 historique, chemin partitionné ; correction R-3 a) ==="
backdate_ws() { # <dossier commun> <ws/alpha|repo> : antidate heartbeat ET progress (réécriture du meta)
  local m="$1/vf-driver/$2/DRIVER.lock/meta"
  sed -e 's/^heartbeat_epoch=.*/heartbeat_epoch=1000/' -e 's/^progress_epoch=.*/progress_epoch=1000/' "$m" > "$m.tmp" && mv "$m.tmp" "$m"
}
LAB="$(mk_lab ttl)"; GCT="$(fixture_common_dir "$LAB")"
dl "$LAB" sess-A acquire --ws=alpha --owner=m1 --step=s >/dev/null
dl "$LAB" sess-A acquire --depot --owner=md --step=sd >/dev/null
out="$(run_guard_in "$LAB" "$(mk_write "$LAB/.planning/workstreams/alpha/STATE.md" x sess-B "$LAB")")"
assert "GW-TTL-0.1 — témoin : alpha frais tenu par autrui : deny" "$out" "$DENY"
out="$(run_guard_in "$LAB" "$(mk_write "$LAB/.planning/PROJECT.md" x sess-B "$LAB")")"
assert "GW-TTL-0.2 — témoin : dépôt frais tenu par autrui : deny" "$out" "$DENY"
backdate_ws "$GCT" ws/alpha; backdate_ws "$GCT" repo
out="$(run_guard_in "$LAB" "$(mk_write "$LAB/.planning/workstreams/alpha/STATE.md" x sess-B "$LAB")")"
assert_empty "GW-TTL-1 — alpha périmé (TTL 1800 s dépassé) : Write permis" "$out"
out="$(run_guard_in "$LAB" "$(mk_write "$LAB/.planning/PROJECT.md" x sess-B "$LAB")")"
assert_empty "GW-TTL-2 — verrou de dépôt périmé : Write racine permis" "$out"
out="$(gb "$LAB" 'git reset --hard' sess-B)"
assert_empty "GW-TTL-3 — geste d'arbre sous des verrous périmés : permis" "$out"
out="$(run_guard_with "$LAB" "$(mk_write "$LAB/.planning/workstreams/alpha/STATE.md" x sess-B "$LAB")" VF_DRIVER_TTL=99999999999)"
assert "GW-TTL-4 — le même verrou sous un TTL élargi (VF_DRIVER_TTL) redevient vivant : deny" "$out" "$DENY"

echo
echo "=== GW-UNC — cible git incertaine (-C, --git-dir, --work-tree) : refus sous tout verrou d'autrui, même quand le geste serait permis (P57-D-33 ; correction R-3 b) ==="
LAB="$(mk_lab unc)"
dl "$LAB" sess-A acquire --ws=alpha --owner=m1 --step=s >/dev/null
out="$(gb "$LAB" 'git commit -m x' sess-B)"
assert_empty "GW-UNC-0 — témoin : index vide, commit sans option de cible : permis" "$out"
out="$(gb "$LAB" 'git --git-dir=.git commit -m x' sess-B)"
assert "GW-UNC-1 — git --git-dir=.git commit (index vide) : deny, cible incertaine" "$out" "$DENY"
out="$(gb "$LAB" 'git -C . commit -m x' sess-B)"
assert "GW-UNC-2 — git -C . commit (index vide) : deny" "$out" "$DENY"
out="$(gb "$LAB" 'git --work-tree=. commit -m x' sess-B)"
assert "GW-UNC-3 — git --work-tree=. commit (index vide) : deny" "$out" "$DENY"
LAB="$(mk_lab unctree)"
WTU="$WORK_DIR/unctree-wt"
git -C "$LAB" worktree add -q -b wtu "$WTU" >/dev/null 2>&1
lab_preflight "$WTU"
dl "$WTU" sess-A acquire --ws=omega --owner=m1 --step=s >/dev/null
out="$(gb "$LAB" 'git reset --hard' sess-B)"
assert_empty "GW-UNC-4.1 — verrou pris depuis un autre worktree, geste d'arbre ordinaire : permis (témoin)" "$out"
out="$(gb "$LAB" 'git -C . reset --hard' sess-B)"
assert "GW-T-C-1b — le même geste avec -C : deny, SEULE la cible incertaine le distingue" "$out" "$DENY"

echo
echo "=== GW-F3 — globaux git SANS argument et wrapper exec : reconnus comme le verbe qui suit (correction F-3, 57-SECURITY.md ; lab partitionné) ==="
LAB="$(mk_lab f3)"
dl "$LAB" sess-A acquire --ws=alpha --owner=m1 --step=s >/dev/null
touch_file "$LAB" "$LAB/.planning/workstreams/alpha/STATE.md"
out="$(gb "$LAB" 'git commit -am x' sess-B)"
assert "GW-F3-0 — témoin : git commit -am sans global, alpha tenu par autrui : deny" "$out" "$DENY"
out="$(gb "$LAB" 'git --no-pager commit -am x' sess-B)"
assert "GW-F3-1 — git --no-pager commit -am : deny" "$out" "$DENY"
out="$(gb "$LAB" 'git --paginate commit -am x' sess-B)"
assert "GW-F3-2 — git --paginate commit -am : deny" "$out" "$DENY"
out="$(gb "$LAB" 'git -p commit -am x' sess-B)"
assert "GW-F3-3 — git -p commit -am : deny" "$out" "$DENY"
out="$(gb "$LAB" 'git --no-optional-locks commit -am x' sess-B)"
assert "GW-F3-4 — git --no-optional-locks commit -am : deny" "$out" "$DENY"
out="$(gb "$LAB" 'git --literal-pathspecs commit -am x' sess-B)"
assert "GW-F3-5 — git --literal-pathspecs commit -am : deny" "$out" "$DENY"
out="$(gb "$LAB" 'exec git commit -am x' sess-B)"
assert "GW-F3-6 — exec git commit -am (exec est un wrapper) : deny" "$out" "$DENY"
out="$(gb "$LAB" 'git --glob-pathspecs commit -am x' sess-B)"
assert "GW-F3-7 — git --glob-pathspecs commit -am : deny" "$out" "$DENY"
out="$(gb "$LAB" 'git --noglob-pathspecs commit -am x' sess-B)"
assert "GW-F3-8 — git --noglob-pathspecs commit -am : deny" "$out" "$DENY"
out="$(gb "$LAB" 'git --icase-pathspecs commit -am x' sess-B)"
assert "GW-F3-9 — git --icase-pathspecs commit -am : deny" "$out" "$DENY"
out="$(gb "$LAB" 'git --no-replace-objects commit -am x' sess-B)"
assert "GW-F3-10 — git --no-replace-objects commit -am : deny" "$out" "$DENY"
out="$(gb "$LAB" 'git --no-lazy-fetch commit -am x' sess-B)"
assert "GW-F3-11 — git --no-lazy-fetch commit -am : deny" "$out" "$DENY"
out="$(gb "$LAB" 'git --no-advice commit -am x' sess-B)"
assert "GW-F3-12 — git --no-advice commit -am : deny" "$out" "$DENY"
out="$(gb "$LAB" 'git --bare commit -am x' sess-B)"
assert "GW-F3-13 — git --bare commit -am : deny" "$out" "$DENY"
out="$(gb "$LAB" 'git --no-pager -p --no-optional-locks commit -am x' sess-B)"
assert "GW-F3-14 — plusieurs globaux sans argument enchaînés : deny" "$out" "$DENY"
out="$(gb "$LAB" 'sudo exec git --no-pager commit -am x' sess-B)"
assert "GW-F3-15 — exec derrière un autre wrapper : deny" "$out" "$DENY"
out="$(gb "$LAB" 'git --no-pager commit -m x' sess-B)"
assert_empty "GW-F3-16 — sans -a, la modification non indexée n'est pas embarquée : stdout vide (discriminance)" "$out"
out="$(gb "$LAB" 'git --no-pager commit -am x' sess-A)"
assert_empty "GW-F3-17 — le détenteur : stdout vide (discriminance)" "$out"
out="$(gb "$LAB" "git --no-pager -C $WORK_DIR commit -am x" sess-B)"
assert_empty "GW-F3-18 — git --no-pager -C <dossier hors du lab> : C7 inchangé, stdout vide" "$out"
out="$(gb "$LAB" 'echo exec git commit -am x' sess-B)"
assert_empty "GW-F3-19 — exec en position d'ARGUMENT d'une autre commande : stdout vide (S3 intact)" "$out"
out="$(gb "$LAB" 'git --no-pager log -1' sess-B)"
assert_empty "GW-F3-20 — un global sans argument devant un verbe hors surface : stdout vide (aucun refus nouveau)" "$out"
LAB="$(mk_lab f3tree)"
dl "$LAB" sess-A acquire --ws=alpha --owner=m1 --step=s >/dev/null
out="$(gb "$LAB" 'git --no-pager reset --hard' sess-B)"
assert "GW-F3-21 — geste d'arbre derrière --no-pager, verrou pris depuis le même worktree : deny" "$out" "$DENY"

echo
echo "=== GW-ENVT — GIT_DIR / GIT_INDEX_FILE / GIT_WORK_TREE en préfixe d'affectation : cible INCERTAINE, comme --git-dir (correction R-5, P57-D-20 ; lab partitionné) ==="
LAB="$(mk_lab envt)"
dl "$LAB" sess-A acquire --ws=alpha --owner=m1 --step=s >/dev/null
out="$(gb "$LAB" 'git commit -m x' sess-B)"
assert_empty "GW-ENVT-0 — témoin : index vide, commit sans préfixe : permis" "$out"
out="$(gb "$LAB" 'GIT_DIR=.git git commit -m x' sess-B)"
assert "GW-ENVT-1 — GIT_DIR=.git git commit (index vide) : deny, cible incertaine" "$out" "$DENY"
out="$(gb "$LAB" 'GIT_INDEX_FILE=.git/index git commit -m x' sess-B)"
assert "GW-ENVT-2 — GIT_INDEX_FILE=… git commit (index vide) : deny" "$out" "$DENY"
out="$(gb "$LAB" 'GIT_WORK_TREE=. git commit -m x' sess-B)"
assert "GW-ENVT-3 — GIT_WORK_TREE=. git commit (index vide) : deny" "$out" "$DENY"
out="$(gb "$LAB" 'env GIT_DIR=.git git commit -m x' sess-B)"
assert "GW-ENVT-4 — env GIT_DIR=… git commit : deny" "$out" "$DENY"
out="$(gb "$LAB" 'FOO=1 GIT_INDEX_FILE=.git/index git commit -m x' sess-B)"
assert "GW-ENVT-5 — affectation étrangère devant : deny" "$out" "$DENY"
out="$(gb "$LAB" 'GIT_AUTHOR_NAME=a git commit -m x' sess-B)"
assert_empty "GW-ENVT-6 — une autre variable GIT_* ne déplace pas la cible : permis (aucune classe de refus nouvelle)" "$out"
out="$(gb "$LAB" 'GIT_DIR=.git git commit -m x' sess-A)"
assert_empty "GW-ENVT-7 — le détenteur : stdout vide (discriminance)" "$out"
out="$(gb "$LAB" 'GIT_DIR=.git git commit -m x' sess-B)"
out2="$(gb "$LAB" 'git --git-dir=.git commit -m x' sess-B)"
[ "$out" = "$out2" ]; assert_exit "GW-ENVT-8 — MÊME verdict et MÊME message que --git-dir= (cible incertaine existante)" "$?" 0
LAB="$(mk_lab envtree)"
WTE="$WORK_DIR/envtree-wt"
git -C "$LAB" worktree add -q -b wte "$WTE" >/dev/null 2>&1
lab_preflight "$WTE"
dl "$WTE" sess-A acquire --ws=omega --owner=m1 --step=s >/dev/null
out="$(gb "$LAB" 'git reset --hard' sess-B)"
assert_empty "GW-ENVT-9.1 — verrou pris depuis un autre worktree, geste d'arbre ordinaire : permis (témoin)" "$out"
out="$(gb "$LAB" 'git status && GIT_DIR=.git git reset --hard' sess-B)"
assert "GW-ENVT-9.2 — le même geste avec GIT_DIR= en préfixe : deny, SEULE la cible incertaine le distingue" "$out" "$DENY"

echo
echo "=== GW-C-POS — un pathspec POSITIONNEL de commit compte comme pathspec (doute = union ; correction R-3 c) ==="
LAB="$(mk_lab cpos)"
dl "$LAB" sess-A acquire --ws=alpha --owner=m1 --step=s >/dev/null
touch_file "$LAB" "$LAB/.planning/workstreams/alpha/STATE.md"
out="$(gb "$LAB" 'git commit -m x' sess-B)"
assert_empty "GW-C-POS-0 — témoin : sans pathspec, la modification non indexée n'est pas embarquée : permis" "$out"
out="$(gb "$LAB" 'git commit -m x .planning/workstreams/alpha/STATE.md' sess-B)"
assert "GW-C-POS-1 — chemin d'alpha en position d'argument : deny" "$out" "$DENY"
out="$(gb "$LAB" 'git commit -m x src/x.sh' sess-B)"
assert "GW-C-POS-2 — autre chemin en position d'argument (doute = union) : deny" "$out" "$DENY"

echo
echo "=== GW-C-PSB — --only, --include et --pathspec-from-file comptent comme pathspec : doute = union (réserve C3 de 57-VERIFICATION.md) ==="
LAB="$(mk_lab cpsb)"
dl "$LAB" sess-A acquire --ws=alpha --owner=m1 --step=s >/dev/null
touch_file "$LAB" "$LAB/.planning/workstreams/alpha/STATE.md"
out="$(gb "$LAB" 'git commit -m x' sess-B)"
assert_empty "GW-C-PSB-0 — témoin : sans option de pathspec, la modification non indexée n'est pas embarquée : stdout vide" "$out"
out="$(gb "$LAB" 'git commit --only -m x' sess-B)"
assert "GW-C-PSB-1 — git commit --only : deny" "$out" "$DENY"
out="$(gb "$LAB" 'git commit --include -m x' sess-B)"
assert "GW-C-PSB-2 — git commit --include : deny" "$out" "$DENY"
out="$(gb "$LAB" 'git commit --pathspec-from-file=liste.txt -m x' sess-B)"
assert "GW-C-PSB-3 — git commit --pathspec-from-file=<fichier> : deny" "$out" "$DENY"
out="$(gb "$LAB" 'git commit --pathspec-from-file liste.txt -m x' sess-B)"
assert "GW-C-PSB-4 — git commit --pathspec-from-file <fichier> (forme à deux jetons) : deny" "$out" "$DENY"

echo
echo "=== GW-C-INC — un chemin indexé qui est .planning/workstreams lui-même est « incertain » : refus sous tout verrou d'autrui (réserve C3) ==="
LAB="$(mk_lab cinc)"
git -C "$LAB" rm -r -q --cached .planning/workstreams >/dev/null 2>&1
GIT_T -C "$LAB" commit -q -m "retire du suivi" >/dev/null 2>&1
dl "$LAB" sess-A acquire --ws=omega --owner=m1 --step=s >/dev/null
out="$(gb "$LAB" 'git commit -m x' sess-B)"
assert_empty "GW-C-INC-0 — témoin : index vide, commit sans chemin : permis" "$out"
INC_BLOB="$(printf 'x\n' | git -C "$LAB" hash-object -w --stdin)"
git -C "$LAB" update-index --add --cacheinfo "100644,$INC_BLOB,.planning/workstreams" >/dev/null 2>&1
out="$(gb "$LAB" 'git commit -m x' sess-B)"
assert "GW-C-INC-1 — .planning/workstreams indexé, omega tenu par autrui : deny" "$out" "$DENY"
assert "GW-C-INC-2 — le refus cite le chemin incertain" "$out" ".planning/workstreams"
out="$(gb "$LAB" 'git commit -m x' sess-A)"
assert_empty "GW-C-INC-3 — le détenteur : stdout vide (discriminance)" "$out"

echo
echo "=== GW-C-CASE — la casse de .planning et de workstreams dans l'INDEX (comportement actuel du jugement de commit ; correction R-3 d) ==="
LAB="$(mk_lab ccase)"
git -C "$LAB" config core.ignorecase false   # sinon git ramène la casse du dossier sur un FS insensible à la casse
dl "$LAB" sess-A acquire --ws=alpha --owner=m1 --step=s >/dev/null
CASE_BLOB="$(printf 'x\n' | git -C "$LAB" hash-object -w --stdin)"
idx_add() { git -C "$1" update-index --add --cacheinfo "100644,$CASE_BLOB,$2" >/dev/null 2>&1; }   # <lab> <chemin d'index>
idx_add "$LAB" ".PLANNING/workstreams/omega/STATE.md"
out="$(gb "$LAB" 'git commit -m x' sess-B)"
assert_empty "GW-C-CASE-0 — témoin : seul omega (casse différente) est indexé, alpha seul est tenu : permis" "$out"
unstage "$LAB"
idx_add "$LAB" ".PLANNING/workstreams/alpha/STATE.md"
out="$(gb "$LAB" 'git commit -m x' sess-B)"
assert "GW-C-CASE-1 — .PLANNING/workstreams/alpha indexé : deny (casse de .planning ignorée)" "$out" "$DENY"
unstage "$LAB"
idx_add "$LAB" ".planning/WORKSTREAMS/alpha/STATE.md"
out="$(gb "$LAB" 'git commit -m x' sess-B)"
assert "GW-C-CASE-2 — .planning/WORKSTREAMS/alpha indexé : deny (casse de workstreams ignorée)" "$out" "$DENY"
unstage "$LAB"
idx_add "$LAB" ".planning/workstreams/ALPHA/STATE.md"
out="$(gb "$LAB" 'git commit -m x' sess-B)"
assert "GW-C-CASE-3 — .planning/workstreams/ALPHA indexé : deny (nom de compartiment sans casse)" "$out" "$DENY"
unstage "$LAB"

echo
echo "=== GW-C-GEN — une exception INATTENDUE du jugement de commit rend un refus nommé, et l'échappatoire reste honorée (correction R-3 e) ==="
LAB="$(mk_lab cgen)"
dl "$LAB" sess-A acquire --ws=alpha --owner=m1 --step=s >/dev/null
mk_bash_sur() { # <suffixe> <session> <cwd> : un chemin à substitut isolé (\ud800), que os.fsencode ne sait pas encoder
  python3 -c '
import json, sys
cmd = "git add a\ud800b && git commit -m x" + sys.argv[1]
print(json.dumps({"tool_name": "Bash", "tool_input": {"command": cmd}, "session_id": sys.argv[2], "cwd": sys.argv[3]}))' "$1" "$2" "$3"
}
out="$(run_guard_in "$LAB" "$(mk_bash_sur '' sess-B "$LAB")")"
assert "GW-C-GEN-1 — exception inattendue dans le jugement : deny" "$out" "$DENY"
assert "GW-C-GEN-2 — le refus nomme la cause (source illisible : exception interne)" "$out" "source illisible : exception interne"
assert "GW-C-GEN-3 — le refus nomme le verrou refusant (compartiment alpha)" "$out" "alpha"
out="$(run_guard_in "$LAB" "$(mk_bash_sur ' # vibeflow:allow-lock-override' sess-B "$LAB")")"
assert_empty "GW-C-GEN-4 — avec l'échappatoire, le geste passe : le refus n'est pas celui du crochet fail-closed" "$out"

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
echo "=== GW-C4 — lab PARTITIONNÉ : le segment .planning se compare sans tenir compte de la casse, préfiltre C4 et cartographie (P57-D-38, correction F-1) ==="
LAB="$(mk_lab c4case)"
dl "$LAB" sess-A acquire --ws=alpha --owner=m1 --step=s >/dev/null
out="$(run_guard_in "$LAB" "$(mk_write "$LAB/.planning/workstreams/alpha/f" x sess-B "$LAB")")"
assert "GW-C4-0 — témoin : .planning en minuscules sous le verrou alpha d'autrui : deny" "$out" "$DENY"
out="$(run_guard_in "$LAB" "$(mk_write "$LAB/.PLANNING/workstreams/alpha/f" x sess-B "$LAB")")"
assert "GW-C4-1 — .PLANNING/workstreams/alpha sous le verrou alpha d'autrui : deny (préfiltre C4)" "$out" "$DENY"
out="$(run_guard_in "$LAB" "$(mk_write "$LAB/.PLANNING/workstreams/omega/f" x sess-B "$LAB")")"
assert_empty "GW-C4-2 — .PLANNING/workstreams/omega, compartiment libre : permis (cartographie, pas un refus par défaut)" "$out"
out="$(run_guard_in "$LAB" "$(mk_write "$LAB/.PLANNING/PROJECT.md" x sess-B "$LAB")")"
assert_empty "GW-C4-3 — .PLANNING/PROJECT.md (racine) sans verrou de dépôt : permis" "$out"
out="$(run_guard_in "$LAB" "$(mk_write "$LAB/.PLANNING/workstreams/alpha/f" x sess-A "$LAB")")"
assert_empty "GW-C4-4 — le détenteur écrit sous .PLANNING/workstreams/alpha : permis (discriminance)" "$out"
FLAT="$(mk_flat c4flat)"
legacy_acquire "$FLAT" sess-A old >/dev/null
out="$(run_guard_in "$FLAT" "$(mk_write "$FLAT/.PLANNING/STATE.md" x sess-B "$FLAT")")"
assert_empty "GW-C4-5 — lab PLAT : .PLANNING reste hors du préfiltre C4 (comportement d'avant la phase, au bit près)" "$out"

echo
echo "=== GW-SUB — lab PARTITIONNÉ détecté depuis la racine git, plus depuis le cwd : un geste lancé d'un sous-dossier est jugé sous le verrou d'autrui (P57-D-39, correction F-2) ==="
LAB="$(mk_lab sub)"
mkdir -p "$LAB/plugin/sub" "$LAB/autre/.planning"
SUBD="$LAB/plugin/sub"
dl "$LAB" sess-A acquire --ws=alpha --owner=m1 --step=s >/dev/null
out="$(run_guard_in "$SUBD" "$(mk_write "$LAB/.planning/workstreams/alpha/f" x sess-B "$SUBD")")"
assert "GW-SUB-1 — Write dans alpha d'autrui depuis un sous-dossier : deny" "$out" "$DENY"
out="$(run_guard_in "$SUBD" "$(mk_write "$LAB/.planning/workstreams/omega/f" x sess-B "$SUBD")")"
assert_empty "GW-SUB-2 — Write dans omega (libre) depuis un sous-dossier : permis (discriminance)" "$out"
out="$(run_guard_in "$SUBD" "$(mk_write "$LAB/.planning/workstreams/alpha/f" x sess-A "$SUBD")")"
assert_empty "GW-SUB-3 — le détenteur depuis un sous-dossier : permis" "$out"
out="$(gb "$LAB" 'git reset --hard' sess-B "$SUBD")"
assert "GW-SUB-4 — geste d'arbre sous le verrou d'autrui depuis un sous-dossier : deny" "$out" "$DENY"
touch_file "$LAB" "$LAB/.planning/workstreams/alpha/STATE.md"; stage "$LAB" .planning/workstreams/alpha/STATE.md
out="$(gb "$LAB" 'git commit -m x' sess-B "$SUBD")"
assert "GW-SUB-5 — commit qui embarque alpha, lancé d'un sous-dossier : deny (préfixe du lab = la racine, pas le sous-dossier)" "$out" "$DENY"
unstage "$LAB"
touch_file "$LAB" "$LAB/.planning/workstreams/omega/STATE.md"; stage "$LAB" .planning/workstreams/omega/STATE.md
out="$(gb "$LAB" 'git commit -m x' sess-B "$SUBD")"
assert_empty "GW-SUB-6 — commit qui n'embarque qu'omega depuis un sous-dossier : permis" "$out"
unstage "$LAB"
out="$(run_guard_in "$LAB/autre" "$(mk_write "$LAB/.planning/workstreams/alpha/f" x sess-B "$LAB/autre")")"
assert_empty "GW-SUB-7 — cwd portant son PROPRE .planning (P57-D-29, hors périmètre) : jugé comme avant, permis" "$out"

if [ "$GW_MODE" = full ]; then
echo
echo "=== GW-AB — lab PLAT : la copie gelée du guard d'avant la phase et le guard courant rendent la MÊME transcription, octet pour octet (P57-D-03, P57-D-22) ==="
# Référence : copie gelée du guard d'avant la Phase 57 (dernier commit cff1e2af qui touchait le script), jamais
# modifiée. Les deux copies sont posées dans un dossier jetable À CÔTÉ d'une copie de vf-portable.sh (le locator du
# guard cherche d'abord $(dirname $0)/vf-portable.sh) : elles s'exécutent dans les mêmes conditions. Même matrice de
# payloads jouée par chacune sur une fixture reconstruite à neuf AU MÊME CHEMIN, dans cinq états de verrou (aucun,
# tenu, périmé, sans session_ids, sans meta), transcription (code, stdout, stderr) normalisée puis comparée par
# `cmp -s` : une assertion de sous-chaîne ne prouve pas le bit près (piège P10). Verrous posés par la copie gelée de
# driver-lock.sh de 57-04. Régimes : VF_DRIVER_LOCK posé, puis chemin par défaut .planning/DRIVER.lock.
FROZEN_GUARD="$HERE/fixtures/guard-driver-lock-pre-cff1e2a.sh"
FROZEN_DL="$HERE/fixtures/driver-lock-pre-e8771d9.sh"
GW_AB_REF=cff1e2af
GW_AB_PATH_IN_REF=plugin/conductor/scripts/guard-driver-lock.sh
GWAB="$WORK_DIR/gwab"; mkdir -p "$GWAB"
for who in frozen current; do mkdir -p "$GWAB/$who"; cp "$PORTABLE" "$GWAB/$who/vf-portable.sh"; done
cp "$FROZEN_GUARD" "$GWAB/frozen/guard-driver-lock.sh" 2>/dev/null; cp "$GUARD" "$GWAB/current/guard-driver-lock.sh"

# Matrice de payloads : une ligne « identifiant US charge-utile ». Construite UNE fois par python (jamais concaténée
# en bash) ; le lab, l'autre dépôt et leurs chemins sont constants d'un passage à l'autre.
cat > "$GWAB/matrix.py" <<'PYMATRIX'
import json, sys
lab, other = sys.argv[1], sys.argv[2]
def bash(cmd, sid, cwd=None):
    d = {"tool_name": "Bash", "tool_input": {"command": cmd}, "cwd": cwd or lab}
    if sid is not None:
        d["session_id"] = sid
    return d
def write(fp, content, sid, tool="Write"):
    ti = {"file_path": fp, "content": content} if tool == "Write" else {"file_path": fp, "old_string": "a", "new_string": content}
    return {"tool_name": tool, "tool_input": ti, "session_id": sid, "cwd": lab}
out = []
for sid in ("sess-B", "sess-A"):
    s = sid[-1]
    out += [
        ("commit." + s, bash("git commit -m x", sid)),
        ("commit-am." + s, bash("git commit -am x", sid)),
        ("amend." + s, bash("git commit --amend --no-edit", sid)),
        ("checkout." + s, bash("git checkout -b x", sid)),
        ("switch." + s, bash("git switch main", sid)),
        ("reset." + s, bash("git reset --hard", sid)),
        ("push." + s, bash("git push", sid)),
        ("tag." + s, bash("git tag v1", sid)),
        ("gh-pr." + s, bash("gh pr create", sid)),
        ("wt-add." + s, bash("git worktree add ../w -b w", sid)),
        ("wt-remove." + s, bash("git worktree remove ../w", sid)),
        ("rebase." + s, bash("git rebase main", sid)),
        ("rebase-abort." + s, bash("git rebase --abort", sid)),
        ("cd-other." + s, bash("cd " + other + " && git commit -m x", sid)),
        ("gitC-other." + s, bash("git -C " + other + " commit -m x", sid)),
        ("popd." + s, bash("popd && git commit -m x", sid)),
        ("chain." + s, bash("echo a; git add -A && git commit -m x", sid)),
        ("heredoc." + s, bash("cat > f <<EOF\nx\nEOF\ngit commit -m x", sid)),
        ("ls." + s, bash("ls -la", sid)),
        ("marker-commit." + s, bash("git commit -m x # vibeflow:allow-lock-override", sid)),
        ("w-planning." + s, write(lab + "/.planning/STATE.md", "x", sid)),
        ("w-planning-rel." + s, write(".planning/STATE.md", "x", sid)),
        ("w-planning-ws." + s, write(lab + "/.planning/workstreams/alpha/STATE.md", "x", sid)),
        ("e-planning." + s, write(lab + "/.planning/STATE.md", "y", sid, "Edit")),
        ("w-marker." + s, write(lab + "/.planning/STATE.md", "x vibeflow:allow-lock-override", sid)),
        ("w-outside." + s, write(lab + "/src/x.sh", "x", sid)),
        ("w-other-planning." + s, write(other + "/.planning/STATE.md", "x", sid)),
        ("w-nul." + s, write(lab + "/.planning/STATE.md\x00x", "x", sid)),
        ("w-nofp." + s, {"tool_name": "Write", "tool_input": {"content": "x"}, "session_id": sid, "cwd": lab}),
        ("read-tool." + s, {"tool_name": "Read", "tool_input": {"file_path": lab + "/.planning/STATE.md"}, "session_id": sid, "cwd": lab}),
        ("bash-empty." + s, bash("", sid)),
        ("ti-nondict." + s, {"tool_name": "Bash", "tool_input": "git commit", "session_id": sid, "cwd": lab}),
    ]
out += [
    ("commit.nosid", bash("git commit -m x", None)),
    ("w-planning.nosid", {"tool_name": "Write", "tool_input": {"file_path": lab + "/.planning/STATE.md", "content": "x"}, "cwd": lab}),
    ("commit.nocwd", {"tool_name": "Bash", "tool_input": {"command": "git commit -m x"}, "session_id": "sess-B"}),
    ("notool", {"session_id": "sess-B", "cwd": lab, "tool_input": {"command": "git commit -m x"}}),
]
raw = [("unparse", "ceci n est pas du json mais ca contient le mot commit"), ("nonobj-array", "[\"commit\"]"),
       ("nonobj-null", "null"), ("nonobj-str", "\"git commit\""), ("empty", "")]
with open(sys.argv[3], "w", encoding="utf-8") as f:
    for k, v in out:
        f.write(k + "\x1f" + json.dumps(v, ensure_ascii=True) + "\n")
    for k, v in raw:
        f.write(k + "\x1f" + v + "\n")
PYMATRIX
python3 "$GWAB/matrix.py" "$GWAB/lab" "$GWAB/other" "$GWAB/matrix.txt"
[ -s "$GWAB/matrix.txt" ]; assert_exit "GW-AB.matrice — $(wc -l < "$GWAB/matrix.txt" | tr -d ' ') payloads construits" "$?" 0

# Normalisation : l'âge « depuis N min » du motif de refus (varie d'une minute à l'autre entre deux passages).
gw_ab_norm() { sed -E -e 's/depuis [0-9]+ min/depuis N min/g'; }

# gw_ab_pass <guard> <VF_DRIVER_LOCK ou vide> <fichier de transcription normalisée>
gw_ab_pass() {
  local g="$1" lockv="$2" out="$3" lab="$GWAB/lab" other="$GWAB/other" raw="$GWAB/raw" lockpath m
  rm -rf "$lab" "$other"; mkdir -p "$lab/.planning" "$other/.planning"
  printf '# projet\n' > "$lab/.planning/PROJECT.md"
  printf -- '---\nstatus: active\n---\n' > "$lab/.planning/STATE.md"
  git -C "$lab" init -q -b main >/dev/null 2>&1 || git -C "$lab" init -q >/dev/null 2>&1
  git -C "$lab" add -A >/dev/null 2>&1
  git -C "$lab" -c user.email=t@t -c user.name=t -c commit.gpgsign=false commit -q -m init >/dev/null 2>&1
  lab_preflight "$lab"
  lockpath="${lockv:-.planning/DRIVER.lock}"
  m="$lab/$lockpath/meta"
  : > "$raw"
  gw_ab_play() { # <état>
    local id payload rc
    while IFS=$'\x1f' read -r id payload; do
      ( cd "$lab" && if [ -n "$lockv" ]; then export VF_DRIVER_LOCK="$lockv"; fi; printf '%s' "$payload" | "$BASH_BIN" "$g" ) >"$GWAB/so" 2>"$GWAB/se"; rc=$?
      { echo "### $1/$id rc=$rc"; echo "--- stdout"; cat "$GWAB/so"; echo "--- stderr"; cat "$GWAB/se"; } >> "$raw"
    done < "$GWAB/matrix.txt"
  }
  gw_ab_dl() { ( cd "$lab" && export CLAUDE_CODE_SESSION_ID=sess-A && if [ -n "$lockv" ]; then export VF_DRIVER_LOCK="$lockv"; fi; "$FROZEN_DL" "$@" ) >/dev/null 2>&1; }
  gw_ab_play aucun
  gw_ab_dl acquire --owner=m1 --step=s1
  [ -f "$m" ] || echo "### FIXTURE CASSÉE : le verrou n'a pas été posé" >> "$raw"
  gw_ab_play tenu
  sed 's/^heartbeat_epoch=.*/heartbeat_epoch=1000/' "$m" > "$m.tmp" && mv "$m.tmp" "$m"
  gw_ab_play perime
  sed -e "s/^heartbeat_epoch=.*/heartbeat_epoch=$(date +%s)/" -e '/^session_ids=/d' "$m" > "$m.tmp" && mv "$m.tmp" "$m"
  gw_ab_play sans-session-ids
  rm -f "$m"
  gw_ab_play sans-meta
  gw_ab_norm < "$raw" > "$out"
}

gw_ab_stdout() { # <transcription> <état/identifiant> : le bloc stdout d'un passage
  awk -v want="### $2 " 'index($0, want)==1 {on=1; next} /^### /{on=0} on && /^--- stdout$/{o=1; next} on && /^--- stderr$/{o=0} on && o {print}' "$1"
}

gw_ab_first_divergence() { # <A> <B> : première ligne divergente (awk : jamais `diff`, qui ne sert pas à comparer des ensembles ici)
  awk 'NR==FNR{a[FNR]=$0; na=FNR; next} {nb=FNR; if(!(FNR in a) || a[FNR]!=$0){print "ligne " FNR " : A=[" a[FNR] "] B=[" $0 "]"; found=1; exit}} END{if(!found && na!=nb) print "longueurs différentes : A=" na " B=" nb}' "$1" "$2"
}

gw_ab_ok=1
if [ -f "$FROZEN_GUARD" ]; then
  for mode in "VF_DRIVER_LOCK posé:.planning/alt/DRIVER.lock" "chemin par défaut:"; do
    label="${mode%%:*}"; lockv="${mode#*:}"
    gw_ab_pass "$GWAB/frozen/guard-driver-lock.sh" "$lockv" "$GWAB/ab-frozen.txt"
    gw_ab_pass "$GWAB/current/guard-driver-lock.sh" "$lockv" "$GWAB/ab-current.txt"
    if [ -s "$GWAB/ab-frozen.txt" ] && ! grep -q 'FIXTURE CASSÉE' "$GWAB/ab-frozen.txt" \
       && gw_ab_stdout "$GWAB/ab-frozen.txt" tenu/commit.B | grep -q '"permissionDecision": "deny"' \
       && gw_ab_stdout "$GWAB/ab-frozen.txt" tenu/w-planning.B | grep -q '"permissionDecision": "deny"' \
       && [ -z "$(gw_ab_stdout "$GWAB/ab-frozen.txt" tenu/commit.A)" ] \
       && [ -z "$(gw_ab_stdout "$GWAB/ab-frozen.txt" perime/commit.B)" ] \
       && grep -q '^### tenu/w-nul.B rc=' "$GWAB/ab-frozen.txt"; then
      assert_exit "GW-AB.témoin — la transcription de référence ($label) contient un refus sous verrou tenu, le détenteur et le verrou périmé laissés passer" 0 0
    else
      assert_exit "GW-AB.témoin — la transcription de référence ($label) est vide ou incomplète" 1 0
    fi
    if cmp -s "$GWAB/ab-frozen.txt" "$GWAB/ab-current.txt"; then
      assert_exit "GW-AB.$label — copie gelée et guard courant : transcriptions identiques ($(grep -c '^### ' "$GWAB/ab-frozen.txt") passages)" 0 0
    else
      assert_exit "GW-AB.$label — transcriptions DIFFÉRENTES" 1 0
      echo "     première divergence : $(gw_ab_first_divergence "$GWAB/ab-frozen.txt" "$GWAB/ab-current.txt")"
      gw_ab_ok=0
    fi
  done
else
  assert_exit "GW-AB — la copie gelée $FROZEN_GUARD est absente" 1 0
  gw_ab_ok=0
fi
if [ "$gw_ab_ok" = 1 ]; then echo "  A/B guard lab plat : IDENTIQUE"; else echo "  A/B guard lab plat : DIFFÉRENT"; fi

# Intégrité de la copie gelée (T-57-40, correction R-7). Empreinte ÉPINGLÉE dans la suite : le blob git de
# `git rev-parse $GW_AB_REF:$GW_AB_PATH_IN_REF`, dérivé de l'objet de référence puis gelé ici. Elle se vérifie SANS
# historique : un clone superficiel (le job `tests` de la CI fait un `actions/checkout` sans `fetch-depth`) ne
# l'ignore plus. Quand l'objet est présent, la copie est en plus comparée au blob du dépôt et l'épingle à la
# référence : un gel dérivé de la référence, jamais d'un vert muet.
GW_AB_BLOB=4d48e50c993520079052f9f2b4c5bc1a5619ba1b
gw_ab_pin_ok() { # <fichier> <blob attendu>
  [ "$(git hash-object --no-filters "$1" 2>/dev/null)" = "$2" ]
}
gw_ab_pin_ok "$FROZEN_GUARD" "$GW_AB_BLOB"; assert_exit "GW-AB-INTEGRITE.0 — la copie gelée porte l'empreinte épinglée (blob $GW_AB_BLOB), historique présent ou non" "$?" 0
cp "$FROZEN_GUARD" "$GWAB/alteree.sh"; printf '#' >> "$GWAB/alteree.sh"
gw_ab_pin_ok "$GWAB/alteree.sh" "$GW_AB_BLOB"; assert_exit "GW-AB-INTEGRITE.0b — témoin négatif : la même copie altérée d'un octet est REJETÉE par la vérification" "$?" 1
if git -C "$HERE" cat-file -e "$GW_AB_REF:$GW_AB_PATH_IN_REF" 2>/dev/null; then
  git -C "$HERE" show "$GW_AB_REF:$GW_AB_PATH_IN_REF" > "$GWAB/ref.sh" 2>/dev/null
  cmp -s "$FROZEN_GUARD" "$GWAB/ref.sh"; assert_exit "GW-AB-INTEGRITE.1 — la copie gelée est identique à git show $GW_AB_REF:$GW_AB_PATH_IN_REF" "$?" 0
  assert "GW-AB-INTEGRITE.3 — l'empreinte épinglée est celle de la référence (git rev-parse $GW_AB_REF:$GW_AB_PATH_IN_REF)" "$(git -C "$HERE" rev-parse "$GW_AB_REF:$GW_AB_PATH_IN_REF" 2>/dev/null)" "$GW_AB_BLOB"
else
  echo "  NOTE-INTEGRITE (objet absent) — $GW_AB_REF non disponible localement (clone superficiel) : comparaison à la référence non faite ici, l'empreinte épinglée est contrôlée par GW-AB-INTEGRITE.0"
fi
fi   # GW_MODE = full (A/B)

if [ "$GW_MODE" = full ]; then
echo
echo "=== MUTANTS GW-M-a à GW-M-w, puis GW-M-pathspec_blind à GW-M-target_noarg — chaque comportement neuf du guard rougit sous sa mutation (QUAL-01, P57-D-28) ==="
# Chaque mutant = une substitution `sed` sur UNE ligne-ancre (compte = 1) d'une COPIE du guard, posée à côté d'une
# copie de vf-portable.sh (sinon le locator sortirait en code 17 pour la mauvaise raison). Le programme python
# embarqué de la copie est compilé (bash -n ne voit pas dedans). La matrice (les cas GW-* hors A/B) est rejouée en
# sous-processus contre la copie ; l'ensemble des ASSERTIONS dont le verdict bascule (identifiant, nombre d'échecs)
# est comparé EXACTEMENT à l'attendu : un cas basculé hors de l'ensemble, ou manquant, fait échouer.
MUT_TOTAL=30; MUT_KILLED=0; t0=$SECONDS
# a : en plus du cas nommé, GW-C-REL-tenu=2 (VERSION, docs/ADR.md) : sans -z, le « \n » reste collé au nom, qui ne correspond plus
#     à la liste exacte des fichiers de forme de release (la prédiction du plan, NONASCII seul, ignorait cet effet de bord)
# a : GW-C-INC-1/2 (corrections F-3, R-5, C3) : sans -z, « .planning/workstreams\n » ne se lit plus comme le chemin incertain
MUT_A="GW-C-INC-1=1 GW-C-INC-2=1 GW-C-NONASCII-1=1 GW-C-REL-tenu=2"
MUT_B="GW-C-REN-1=1 GW-C-REN-2=1"
# c : les refus de verrou illisible (R-2) passent aussi par le crochet fail-closed : GW-UNREAD rougit avec lui
MUT_C="GW-CRASH.2=1 GW-CRASH.3=1 GW-CRASH.4=1 GW-CRASH-PRE-a.2=1 GW-CRASH-PRE-b.2=1 GW-CRASH-PRE-b.3=1 GW-UNREAD-1.2=1 GW-UNREAD-1.3=1 GW-UNREAD-1.4=1 GW-UNREAD-1.5=1 GW-UNREAD-2.1=1 GW-UNREAD-2.2=1"
MUT_D="GW-CRASH-PRE-a.2=1 GW-CRASH-PRE-b.2=1 GW-CRASH-PRE-b.3=1"
MUT_E="GW-T-EXEMPT-1=1"
# f : GW-ENVT-9.1 (témoin de GW-ENVT-9.2, même geste d'arbre depuis un autre worktree)
MUT_F="GW-ENVT-9.1=1 GW-T-OTHERWT=6 GW-T-OTHERWT-bis=1 GW-UNC-4.1=1"
# g : tous les cas « le détenteur passe » rougissent (le cas nommé par le plan, GW-TRACE-3, en fait partie)
# g : GW-C-INC-3, GW-ENVT-7, GW-F3-17 (détenteur, discriminance des cas ajoutés)
MUT_G="GW-C-ADD-6=1 GW-C-CORRUPT-3=1 GW-C-IDX-3=1 GW-C-INC-3=1 GW-C-NOGITBIN-3=1 GW-C-REL-detenteur=3 GW-C4-4=1 GW-D-TAG-detenteur=1 GW-ENVT-7=1 GW-F3-17=1 GW-LOC-1.3=1 GW-LOC-2.3=1 GW-SUB-3=1 GW-T-C-2=1 GW-T-SAME-detenteur=1 GW-TRACE-3.2=1 GW-TRACE-4.4=1 GW-W-CASE-2=1 GW-W-LEG-4=1 GW-W-UNMAP-2=1"
# h : tout verrou d'autrui bloque : les cas « le voisin / la racine reste libre » rougissent (GW-TRACE-2 est le cas nommé)
MUT_H="GW-C4-2=1 GW-C4-3=1 GW-MARK-W-4=1 GW-Q-PASS=1 GW-SUB-2=1 GW-TRACE-2.2=1 GW-TRACE-4.1=1 GW-W-LEG-3=1"
MUT_I="GW-C-REL-tenu=2"
# j : GW-F3-0 à 15 (cas -am, F-3) dépendent aussi de la source -a
MUT_J="GW-C-ALL-1=1 GW-C-ALL-2=1 GW-F3-0=1 GW-F3-1=1 GW-F3-2=1 GW-F3-3=1 GW-F3-4=1 GW-F3-5=1 GW-F3-6=1 GW-F3-7=1 GW-F3-8=1 GW-F3-9=1 GW-F3-10=1 GW-F3-11=1 GW-F3-12=1 GW-F3-13=1 GW-F3-14=1 GW-F3-15=1"
MUT_K="GW-C-ADD-1=1"
MUT_L="GW-W-LEG-1=1 GW-W-LEG-2=1"
# m à r (correction R-3 de la revue Phase 57) : ensembles mesurés puis relus un par un ; chacun contient le cas qui
# discrimine le comportement, rien d'autre (GW-T-C-1b est le cas voisin de GW-T-C-1 qui isole la cible incertaine)
MUT_M="GW-TTL-1=1 GW-TTL-2=1 GW-TTL-3=1"
# n : GW-ENVT-8 compare le message de GW-ENVT-1 à celui de --git-dir=
MUT_N="GW-ENVT-8=1 GW-T-C-1b=1 GW-UNC-1=1 GW-UNC-2=1 GW-UNC-3=1"
MUT_O="GW-C-POS-1=1 GW-C-POS-2=1"
MUT_P="GW-C-CASE-1=1"
MUT_Q="GW-C-GEN-2=1 GW-C-GEN-3=1 GW-C-GEN-4=1"
MUT_R="GW-C-CASE-2=1"
# s à w (corrections F-1 et F-2 de l'audit Phase 57, P57-D-38 et P57-D-39) : s = casse de .planning du préfiltre C4 ;
# t = casse de .planning dans map_path ; u = partition détectée depuis le cwd au lieu de la racine git ; v = même
# détection, sonde bash pure ; w = préfixe du lab pris sur le cwd au lieu de la racine du lab (commit d'un sous-dossier).
MUT_S="GW-C4-1=1"
MUT_T="GW-C4-2=1 GW-C4-3=1"
MUT_U="GW-SUB-1=1 GW-SUB-4=1 GW-SUB-5=1"
MUT_V="GW-SUB-1=1 GW-SUB-4=1 GW-SUB-5=1"
MUT_W="GW-SUB-5=1"
# pathspec_blind à target_noarg (corrections F-3, R-5 et réserve C3 de 57-VERIFICATION.md) : ensembles mesurés puis relus
# un par un. pathspec_blind = --only/--include/--pathspec-from-file ne comptent plus comme pathspec ; incertain_none = un
# chemin indexé « .planning/workstreams » ne bloque plus ; toplevel_none = l'absence de racine git n'est plus nommée
# (l'exception interne la remplace dans le motif) ; envt_none = GIT_DIR=/GIT_INDEX_FILE=/GIT_WORK_TREE= ne rendent plus la
# cible incertaine ; noarg_blind = plus aucun global sans argument n'est sauté ; exec_blind = exec n'est plus un wrapper ;
# target_noarg = la cible d'un geste ne saute plus les globaux sans argument (git --no-pager -C <hors lab> est refusé).
MUT_PSB="GW-C-PSB-1=1 GW-C-PSB-2=1 GW-C-PSB-3=1 GW-C-PSB-4=1"
MUT_INC="GW-C-INC-1=1 GW-C-INC-2=1"
MUT_TOP="GW-C-NOGITBIN-4=1"
MUT_ENVT="GW-ENVT-1=1 GW-ENVT-2=1 GW-ENVT-3=1 GW-ENVT-4=1 GW-ENVT-5=1 GW-ENVT-8=1 GW-ENVT-9.2=1"
MUT_NOARG="GW-F3-1=1 GW-F3-2=1 GW-F3-3=1 GW-F3-4=1 GW-F3-5=1 GW-F3-7=1 GW-F3-8=1 GW-F3-9=1 GW-F3-10=1 GW-F3-11=1 GW-F3-12=1 GW-F3-13=1 GW-F3-14=1 GW-F3-15=1 GW-F3-21=1"
MUT_EXEC="GW-F3-15=1 GW-F3-6=1"
MUT_TARGET="GW-F3-18=1"
gw_extract_py() { # <guard> <fichier python de sortie> : le programme embarqué, tel que python le reçoit
  awk 'f && /^'"'"' 2>\/dev\/null \|\| exit 0$/ {exit} f {print} /^printf .%s. "\$INPUT" \| vf_python -c .$/ {f=1}' "$1" > "$2"
}
gw_py_compiles() { # <fichier python>
  python3 -I -c 'import sys; compile(open(sys.argv[1], encoding="utf-8").read(), "guard-embarque", "exec")' "$1" 2>/dev/null
}
mut_ids() { # <journal> → « identifiant=nombre d'échecs », trié, une par ligne
  LC_ALL=C sed -n 's/^  ❌ FAIL — \([^ ]*\) .*/\1/p' "$1" | LC_ALL=C sort | LC_ALL=C uniq -c | LC_ALL=C awk '{print $2 "=" $1}' | LC_ALL=C sort
}
mut_trace() { # <journal> <identifiant> → première assertion violée, attendu/obtenu (octets : LC_ALL=C, lignes tronquées)
  LC_ALL=C awk -v f="$2" '
    /^  ❌ FAIL — /{ t=$0; sub(/^  ❌ FAIL — /,"",t); k=t; sub(/ .*$/,"",k)
                    if (!done && k==f) { print "      rouge " substr(t,1,170); p=1; done=1; next } p=0 }
    p && /^     /{ print "        " substr($0,1,170); next }
    { p=0 }' "$1"
}
mut_run() { # <guard> <journal> → code de sortie du sous-processus
  GW_MODE=matrice GW_GUARD="$1" "$BASH_BIN" "$SUITE" > "$2" 2>&1 < /dev/null
}
MUT_IDS=""
mutant() { # <id> <ancre BRE> <expression sed s> <attendu> [<ancre 2> <expression 2>]
  # Prépare le mutant puis lance sa matrice EN ARRIÈRE-PLAN ; le verdict est rendu par mutant_eval, dans l'ordre,
  # après `wait`. Chaque sous-processus a son propre WORK_DIR.
  local id="$1" anchor="$2" expr="$3" expected="$4" anchor2="${5:-}" expr2="${6:-}" dir="$WORK_DIR/gw-mut-$1" n
  mkdir -p "$dir"; MUT_IDS="$MUT_IDS $id"
  printf '%s\n' $expected | LC_ALL=C sort -u > "$dir/attendu.txt"
  cp "$GUARD" "$dir/guard-driver-lock.sh"; cp "$PORTABLE" "$dir/vf-portable.sh"
  cp "$dir/guard-driver-lock.sh" "$dir/copie-temoin.sh"
  n="$(grep -c -e "$anchor" "$dir/guard-driver-lock.sh")"
  if [ "$n" != "1" ]; then echo "ancre non unique ($n occurrences de [$anchor])" > "$dir/prepko"; return; fi
  sed -i.bak -e "/$anchor/$expr" "$dir/guard-driver-lock.sh"; rm -f "$dir/guard-driver-lock.sh.bak"
  if [ -n "$anchor2" ]; then
    n="$(grep -c -e "$anchor2" "$dir/guard-driver-lock.sh")"
    if [ "$n" != "1" ]; then echo "ancre 2 non unique ($n occurrences de [$anchor2])" > "$dir/prepko"; return; fi
    sed -i.bak -e "/$anchor2/$expr2" "$dir/guard-driver-lock.sh"; rm -f "$dir/guard-driver-lock.sh.bak"
  fi
  if cmp -s "$dir/guard-driver-lock.sh" "$dir/copie-temoin.sh"; then echo "mutant NON OPPOSABLE : la substitution n'a rien changé" > "$dir/prepko"; return; fi
  if ! bash -n "$dir/guard-driver-lock.sh" 2>/dev/null; then echo "le mutant n'est pas un script valide (il rougirait pour la mauvaise raison)" > "$dir/prepko"; return; fi
  gw_extract_py "$dir/guard-driver-lock.sh" "$dir/embarque.py"
  if ! gw_py_compiles "$dir/embarque.py"; then echo "le programme python embarqué du mutant ne compile pas (il rougirait pour la mauvaise raison)" > "$dir/prepko"; return; fi
  chmod +x "$dir/guard-driver-lock.sh"
  ( mut_run "$dir/guard-driver-lock.sh" "$dir/matrice.log"; echo $? > "$dir/rc" ) &
}
mutant_eval() { # <id>
  local id="$1" dir="$WORK_DIR/gw-mut-$1" rc got
  if [ -f "$dir/prepko" ]; then assert_exit "GW-M-$id — $(cat "$dir/prepko")" 1 0; return; fi
  rc="$(cat "$dir/rc" 2>/dev/null || echo absent)"
  if [ "$rc" != 0 ] && [ "$rc" != 1 ]; then assert_exit "GW-M-$id — la matrice a planté (exit $rc), pas un échec de cas" 1 0; return; fi
  grep -q '^=== Bilan : ' "$dir/matrice.log" || { assert_exit "GW-M-$id — la matrice n'a pas atteint son bilan" 1 0; return; }
  mut_ids "$dir/matrice.log" > "$dir/obtenu.txt"
  got="$(tr '\n' ' ' < "$dir/obtenu.txt")"
  if [ ! -s "$dir/attendu.txt" ]; then
    assert_exit "GW-M-$id — ensemble attendu vide (un mutant sans cas attendu ne prouve rien)" 1 0
    echo "     obtenu:  {$got}"
  elif cmp -s "$dir/attendu.txt" "$dir/obtenu.txt"; then
    assert_exit "GW-M-$id — mutant tué : bascule exactement {$(tr '\n' ' ' < "$dir/attendu.txt")}" 0 0
    while IFS= read -r one; do mut_trace "$dir/matrice.log" "${one%=*}"; done < "$dir/obtenu.txt"
    MUT_KILLED=$((MUT_KILLED+1))
  else
    assert_exit "GW-M-$id — ensemble basculé INATTENDU" 1 0
    echo "     attendu: {$(tr '\n' ' ' < "$dir/attendu.txt")}"
    echo "     obtenu:  {$got}"
  fi
}

# Témoin préalable : la copie NON mutée (guard + vf-portable.sh côte à côte) ne bascule AUCUN cas et son programme
# embarqué compile.
mkdir -p "$WORK_DIR/gw-mut-temoin"; cp "$GUARD" "$WORK_DIR/gw-mut-temoin/guard-driver-lock.sh"; cp "$PORTABLE" "$WORK_DIR/gw-mut-temoin/vf-portable.sh"
chmod +x "$WORK_DIR/gw-mut-temoin/guard-driver-lock.sh"
gw_extract_py "$WORK_DIR/gw-mut-temoin/guard-driver-lock.sh" "$WORK_DIR/gw-mut-temoin/embarque.py"
gw_py_compiles "$WORK_DIR/gw-mut-temoin/embarque.py"; assert_exit "GW-M-témoin.1 — le programme python embarqué du guard non muté compile ($(wc -l < "$WORK_DIR/gw-mut-temoin/embarque.py" | tr -d ' ') lignes extraites)" "$?" 0
mut_run "$WORK_DIR/gw-mut-temoin/guard-driver-lock.sh" "$WORK_DIR/gw-mut-temoin/matrice.log"; rc=$?
tn="$(mut_ids "$WORK_DIR/gw-mut-temoin/matrice.log" | wc -l | tr -d ' ')"
assert_exit "GW-M-témoin.2 — la copie non mutée rend zéro assertion en échec (exit $rc, $tn en échec, ${SECONDS}s écoulées)" "$((rc + tn))" 0

# a : `-z` retiré de la source « diff --cached » -> la sortie n'est plus découpée sur NUL, un nom non ASCII sort cité
mutant a 'srcs = \[("diff --cached"' 's@"--name-only", "-z"\])@"--name-only"])@' "$MUT_A"
# b : `--no-renames` retiré -> un renommage ne montre plus que sa destination, la source d'un autre compartiment disparaît
mutant b 'srcs = \[("diff --cached"' 's@"--cached", "--no-renames", @"--cached", @' "$MUT_B"
# c : crochet d'exception fail-closed neutralisé (rend le silence) -> toute exception ré-ouvre par le repli bash
mutant c '^    sys.excepthook = fail_closed_hook$' 's@fail_closed_hook$@lambda *a: None@' "$MUT_C"
# d : crochet posé seulement à l'entrée de decide_partitioned, après le dispatch d'outil -> les exceptions du dispatch passent
mutant d '^    sys.excepthook = fail_closed_hook$' 's@sys.excepthook = fail_closed_hook$@pass@' "$MUT_D" '57-08)\."""$' 's@"""$@"""; sys.excepthook = fail_closed_hook@'
# e : exemption `git worktree add` retirée -> la porte de sortie prescrite par le verrou est refusée
mutant e 'continue  # exemption nomm.*e : porte de sortie prescrite' 's@continue  # exemption nomm.*$@return True@' "$MUT_E"
# f : condition de worktree retirée -> un geste d'arbre est refusé depuis un AUTRE worktree que celui du verrou
mutant f 'if not wt or top is None or same_checkout(wt, top):' 's@if not wt or top is None or same_checkout(wt, top):@if True:@' "$MUT_F"
# g : session courante traitée comme autrui -> le détenteur est refusé comme un tiers
mutant g '^    if sid and sid in session_ids:$' 's@in session_ids:$@in session_ids and False:@' "$MUT_G"
# h : cartographie par compartiment retirée -> tout verrou d'autrui bloque tout chemin
mutant h 'kind, seg = map_path(abs_path, lab)' 's@map_path(abs_path, lab)@("incertain", "")@' "$MUT_H"
# i : RELEASE_FORM_FILES vidée -> VERSION et docs/ADR.md ne sont plus des gestes de dépôt
mutant i 'if pb in RELEASE_FORM_FILES:' 's@RELEASE_FORM_FILES:@():@' "$MUT_I"
# j : source `-a` retirée -> `git commit -a` n'embarque plus les modifications non indexées
mutant j 'if g\["a_flag"\] or g\["pathspec"\] or wide:' 's@g\["a_flag"\] or @@' "$MUT_J"
# k : chemins d'ajout ignorés -> un `git add <littéral> && git commit` n'est plus jugé sur ce qu'il ajoute
mutant k '^    paths.extend(lit)$' 's@paths.extend(lit)@pass@' "$MUT_K"
# l : ancien verrou non lu -> .planning/DRIVER.lock d'autrui n'est plus vu en lab partitionné
mutant l 'if os.path.lexists(legacy):' 's@lexists(legacy):@lexists(legacy) and False:@' "$MUT_L"
# m (R-3 a) : test de péremption TTL retiré -> un verrou périmé d'autrui est de nouveau un verrou
mutant m '^    if age > ttl:$' 's@if age > ttl:@if False:@' "$MUT_M"
# n (R-3 b) : uncertain_global neutralisée -> -C, --git-dir, --work-tree ne rendent plus la cible incertaine
mutant n 'return t == "-C" or' 's@return t == "-C" or .*@return False@' "$MUT_N"
# o (R-3 c) : le jeton POSITIONNEL d'un commit ne compte plus comme pathspec (la ligne `pathspec = True` de la branche else)
mutant o 'elif ch in "io":' '{n;n;n;s@pathspec = True@pass@;}' "$MUT_O"
# p (R-3 d) : casse de .planning ignorée -> comparée à l'identique dans map_repo_path
mutant p 'if parts\[0\].lower() == b".planning":' 's@parts\[0\].lower()@parts[0]@' "$MUT_P"
# q (R-3 e) : l'`except Exception` générique du jugement de commit retiré (il n'attrape plus rien)
mutant q 'except Unreadable as e:' '{n;n;n;n;s@except Exception:@except ZeroDivisionError:@;}' "$MUT_Q"
# r (R-3 d) : casse de `workstreams` ignorée -> comparée à l'identique dans map_repo_path
mutant r 'parts\[1\].lower() == b"workstreams"' 's@parts\[1\].lower()@parts[1]@' "$MUT_R"
mutant s 're.I if PARTITIONED else 0' 's@re.I if PARTITIONED else 0@0@' "$MUT_S"
mutant t 'rp\[len(pp) - 1\].casefold()' 's@rp\[len(pp) - 1\].casefold() == pp\[-1\].casefold()@False@' "$MUT_T"
mutant u 'top = toplevel_of(base) or top_by_marker(base)' 's@toplevel_of(base) or top_by_marker(base)@None@' "$MUT_U"
mutant v 'VF_GUARD_SUBLAB=1; fi' 's@VF_GUARD_SUBLAB=1; fi@VF_GUARD_SUBLAB=0; fi@' "$MUT_V"
mutant w 'cwd if lab is None else lab' 's@cwd if lab is None else lab@cwd@' "$MUT_W"
# pathspec_blind (C3) : les trois options qui désignent un pathspec ne comptent plus
mutant pathspec_blind 'elif nm in ("--include", "--only", "--pathspec-from-file"):' 's@("--include", "--only", "--pathspec-from-file")@("--zzz",)@' "$MUT_PSB"
# incertain_none (C3) : un chemin « incertain » embarqué par le commit ne bloque plus
mutant incertain_none 'elif kind == "incertain":' '{n;s@hs = list(held)@hs = []@;}' "$MUT_INC"
# toplevel_none (C3) : l'absence de racine git ne lève plus Unreadable (l'exception interne la remplace dans le motif)
mutant toplevel_none 'raise Unreadable("rev-parse --show-toplevel")' 's@raise Unreadable("rev-parse --show-toplevel")@pass@' "$MUT_TOP"
# envt_none (R-5) : l'affectation GIT_DIR=/GIT_INDEX_FILE=/GIT_WORK_TREE= ne rend plus la cible incertaine
mutant envt_none 'unc = unc or env_target_uncertain(toks\[:idx\])' 's@unc = unc or env_target_uncertain(toks\[:idx\])@unc = unc@' "$MUT_ENVT"
# noarg_blind (F-3) : l'ensemble des globaux sans argument est vide
mutant noarg_blind '^NOARG_GIT_GLOBALS = {' 's@NOARG_GIT_GLOBALS = {@NOARG_GIT_GLOBALS = set(); NOARG_UNUSED = {@' "$MUT_NOARG"
# exec_blind (F-3) : exec n'est plus un wrapper
mutant exec_blind 'os.path.basename(t) == "exec"' 's@(PARTITIONED and os.path.basename(t) == "exec")@False@' "$MUT_EXEC"
# target_noarg (F-3) : la cible d'un geste ne saute plus les globaux sans argument
mutant target_noarg 'elif noarg_global(t):' 's@elif noarg_global(t):@elif False:@' "$MUT_TARGET"

wait
for id in $MUT_IDS; do mutant_eval "$id"; done
echo "  durée des mutants : $((SECONDS-t0))s"
if [ "$MUT_KILLED" -eq "$MUT_TOTAL" ]; then
  echo "== mutants : 30/30 tués =="
else
  echo "== mutants : $MUT_KILLED/30 tués =="
  FAIL=$((FAIL+1))
fi
fi   # GW_MODE = full (mutants)

echo
echo "=== Bilan : $PASS PASS · $FAIL FAIL ==="
echo "== resultat : $PASS ok, $FAIL ko =="
[ "$PASS" -gt 0 ] || { echo "❌ FAIL — zéro assertion exécutée"; exit 1; }
[ "$FAIL" -eq 0 ]
