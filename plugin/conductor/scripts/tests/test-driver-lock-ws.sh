#!/usr/bin/env bash
# test-driver-lock-ws.sh — Suite NEUVE du verrou de driver PAR COMPARTIMENT (Phase 57, plan 57-01).
#
# Jamais un ajout à test-driver-lock.sh ni à test-guard-driver-lock.sh : ces deux suites sont le
# témoin de non-régression du lab PLAT (P57-D-03), elles ne bougent pas. Toute preuve neuve vit ici.
#
# TRACER (tâche 1) — un compartiment se verrouille au niveau du clone, de bout en bout :
#   WS-TRACE-1 acquire --ws → JSON de portée · WS-TRACE-2 lien dans le dossier commun du clone, rien
#   dans .planning/ · WS-TRACE-3 status puis release · WS-TRACE-4 préflight anti-pollution du vrai .git
#
# Toute invocation du script se fait depuis un sous-shell qui `cd` dans une fixture jetable, jamais
# depuis le vrai dépôt (piège P2) : le dossier commun du clone vient de `git rev-parse` sur le cwd.
#
# Exit 0 si tout passe, 1 sinon, 2 si la fixture est cassée (préflight).

set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$(cd "$HERE/.." && pwd)/driver-lock.sh"
POLICY="$(cd "$HERE/../../../planning-core/scripts" && pwd)/workstream-policy.sh"

# DÉSARMEMENT en tête (P57-D-22) : un VF_DRIVER_LOCK hérité forcerait le mode « verrou unique » et
# la suite ne mesurerait plus rien ; les autres variables déplaceraient la cible ou le TTL. GIT_* :
# une suite jouée depuis un hook git hériterait du dépôt du hook, pas de la fixture.
unset VF_DRIVER_LOCK VF_DRIVER_CHILDREN VF_DRIVER_TTL VF_DRIVER_SESSION_MAX VF_DRIVER_TEST_DIE_AFTER_MUTEX \
      GSD_WORKSTREAM VF_WORKSTREAM CLAUDE_CODE_SESSION_ID GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE

WORK_DIR="$(mktemp -d)"
WORK_DIR="$(cd "$WORK_DIR" && pwd -P)"   # macOS : /var → /private/var, comparé canonicalisé
trap 'rm -rf "$WORK_DIR"' EXIT

PASS=0; FAIL=0
assert()     { if [[ "$2" == *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: $3"; echo "     obtenu:  $2"; FAIL=$((FAIL+1)); fi; }
assert_not() { if [[ "$2" != *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     interdit: $3"; echo "     obtenu:   $2"; FAIL=$((FAIL+1)); fi; }
assert_exit(){ if [ "$2" -eq "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1 (exit $2 ≠ $3)"; FAIL=$((FAIL+1)); fi; }

# Validité JSON par un parse RÉEL, jamais par grep seul.
json_ok() { printf '%s' "$1" | python3 -c 'import json,sys; json.load(sys.stdin)' 2>/dev/null; }

# Laboratoire PARTITIONNÉ jetable : dépôt git, deux compartiments (alpha = 1er, omega = dernier par
# ordre alphabétique — piège P1, les DEUX bouts sont exercés). Imprime le chemin du lab.
mk_lab() { # <nom>
  local d="$WORK_DIR/$1"
  mkdir -p "$d/.planning/workstreams/alpha" "$d/.planning/workstreams/omega"
  printf '# projet\n' > "$d/.planning/PROJECT.md"
  printf -- '---\nstatus: active\n---\n' > "$d/.planning/workstreams/alpha/STATE.md"
  printf -- '---\nstatus: active\n---\n' > "$d/.planning/workstreams/omega/STATE.md"
  git -C "$d" init -q -b main >/dev/null 2>&1 || git -C "$d" init -q >/dev/null 2>&1
  git -C "$d" add -A >/dev/null 2>&1
  git -C "$d" -c user.email=t@t -c user.name=t -c commit.gpgsign=false commit -q -m init >/dev/null 2>&1
  preflight "$d"
  printf '%s' "$d"
}

# Laboratoire PLAT jetable : un STATE.md racine, aucun dossier de compartiments.
mk_flat() { # <nom>
  local d="$WORK_DIR/$1"
  mkdir -p "$d/.planning"
  printf '# projet\n' > "$d/.planning/PROJECT.md"
  printf -- '---\nstatus: active\n---\n' > "$d/.planning/STATE.md"
  git -C "$d" init -q -b main >/dev/null 2>&1 || git -C "$d" init -q >/dev/null 2>&1
  git -C "$d" add -A >/dev/null 2>&1
  git -C "$d" -c user.email=t@t -c user.name=t -c commit.gpgsign=false commit -q -m init >/dev/null 2>&1
  preflight "$d"
  printf '%s' "$d"
}

# Dossier commun du clone d'une fixture, canonicalisé (git rendu relatif au cwd, puis pwd -P).
fixture_common_dir() { # <lab>
  local gc
  gc="$(cd "$1" && git rev-parse --git-common-dir 2>/dev/null)" || return 1
  case "$gc" in /*) ;; *) gc="$1/$gc" ;; esac
  (cd "$gc" 2>/dev/null && pwd -P)
}

# PRÉFLIGHT anti-pollution (T-57-03, piège P2) : le dossier commun de la fixture DOIT être sous
# $WORK_DIR canonicalisé, sinon une écriture irait dans le vrai .git du dépôt. Arrêt AVANT toute
# écriture du script, exit 2.
preflight() { # <lab>
  local gc; gc="$(fixture_common_dir "$1")" || gc=""
  case "$gc" in
    "$WORK_DIR"/*) return 0 ;;
    *) echo "PRÉFLIGHT FIXTURE CASSÉ — dossier commun '$gc' hors de '$WORK_DIR' : arrêt avant toute écriture" >&2
       exit 2 ;;
  esac
}

# Invocation du script DEPUIS la fixture, sous une session simulée. Jamais depuis le vrai dépôt.
dl() { # <lab> <session> <args...>
  local lab="$1" sid="$2"; shift 2
  ( cd "$lab" && CLAUDE_CODE_SESSION_ID="$sid" "$SCRIPT" "$@" )
}

echo "=== WS-TRACE — verrou d'un compartiment, de bout en bout, sur clone jetable ==="
LAB="$(mk_lab trace)"
GC="$(fixture_common_dir "$LAB")"
assert "WS-TRACE-4 — préflight : le dossier commun de la fixture est sous le répertoire de travail" "$GC" "$WORK_DIR/"

out="$(dl "$LAB" sess-A acquire --ws=alpha --owner=m1 --step=s)"; rc=$?
assert_exit "WS-TRACE-1.1 — acquire --ws=alpha exit 0" "$rc" 0
json_ok "$out"; assert_exit "WS-TRACE-1.2 — JSON valide (parse python)" "$?" 0
assert "WS-TRACE-1.3 — acquired true" "$out" '"acquired": true'
assert "WS-TRACE-1.4 — scope compartiment" "$out" '"scope": "compartiment"'
assert "WS-TRACE-1.5 — ws alpha" "$out" '"ws": "alpha"'
assert "WS-TRACE-1.6 — location git-common-dir" "$out" '"location": "git-common-dir"'

[ -L "$GC/vf-driver/ws/alpha/DRIVER.lock" ]; assert_exit "WS-TRACE-2.1 — lien <dossier commun>/vf-driver/ws/alpha/DRIVER.lock" "$?" 0
leftover="$(ls -d "$LAB"/.planning/DRIVER.lock* 2>/dev/null)"
assert "WS-TRACE-2.2 — aucun .planning/DRIVER.lock* créé dans le clone" "[$leftover]" "[]"

out="$(dl "$LAB" sess-A status --ws=alpha)"; rc=$?
assert_exit "WS-TRACE-3.1 — status --ws=alpha exit 0" "$rc" 0
json_ok "$out"; assert_exit "WS-TRACE-3.2 — JSON de status valide" "$?" 0
assert "WS-TRACE-3.3 — present true" "$out" '"present": true'
assert "WS-TRACE-3.4 — owner m1" "$out" '"owner": "m1"'
assert "WS-TRACE-3.5 — portée du status" "$out" '"scope": "compartiment", "ws": "alpha", "location": "git-common-dir"'
out="$(dl "$LAB" sess-A release --ws=alpha --owner=m1)"; rc=$?
assert_exit "WS-TRACE-3.6 — release --ws=alpha exit 0" "$rc" 0
assert "WS-TRACE-3.7 — released true" "$out" '"released": true'
json_ok "$out"; assert_exit "WS-TRACE-3.8 — JSON de release valide" "$?" 0
out="$(dl "$LAB" sess-A status --ws=alpha)"
assert "WS-TRACE-3.9 — status après release : present false" "$out" '"present": false'

echo
echo "=== Bilan : $PASS PASS · $FAIL FAIL ==="
[ "$PASS" -gt 0 ] || { echo "❌ FAIL — zéro assertion exécutée"; exit 1; }
[ "$FAIL" -eq 0 ]
