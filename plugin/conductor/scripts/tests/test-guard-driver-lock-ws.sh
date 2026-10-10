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

echo
echo "=== Bilan : $PASS PASS · $FAIL FAIL ==="
echo "== resultat : $PASS ok, $FAIL ko =="
[ "$PASS" -gt 0 ] || { echo "❌ FAIL — zéro assertion exécutée"; exit 1; }
[ "$FAIL" -eq 0 ]
