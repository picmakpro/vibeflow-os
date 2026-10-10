#!/usr/bin/env bash
# test-check-mission-exit-ws.sh — Suite NEUVE du gate de sortie de mission PAR COMPARTIMENT (Phase 57, plan 57-07).
#
# Jamais un ajout à test-check-mission-exit.sh : cette suite est le témoin de non-régression du lab
# PLAT (P57-D-03), elle ne bouge pas. Toute preuve neuve vit ici.
#
# TRACER (tâche 1) — E1 juge le verrou du compartiment désigné par --ws, de bout en bout :
#   EW-TRACE-1 verrou du compartiment tenu → ligne E1 de manque (owner=) · EW-TRACE-2 relâché → aucune
#   ligne E1 · EW-TRACE-3 le driver-lock.sh frère reçoit VF_DRIVER_LOCK VIDE · EW-TRACE-0 préflight.
#
# Les assertions portent sur les lignes E1 (stdout) et les diagnostics E1 (stderr), jamais sur le
# verdict global, que les autres contrôles (E2-E7) influencent sur une fixture minimale.
#
# HOME et CLAUDE_PLUGIN_ROOT sont SCRUBBÉS pour chaque invocation (run_gate), comme dans la suite du
# lab plat : sans ce scrub la cascade des scripts frères résoudrait vers l'installation réelle.
#
# Exit 0 si tout passe, 1 sinon, 2 si la fixture est cassée (préflight).

set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$(cd "$HERE/.." && pwd)/check-mission-exit.sh"
PLUGIN="$(cd "$HERE/../../.." && pwd)"
DL_REAL="$PLUGIN/conductor/scripts/driver-lock.sh"
DAG_REAL="$PLUGIN/conductor/scripts/dag.sh"
POLICY_REAL="$PLUGIN/planning-core/scripts/workstream-policy.sh"
BUDGET_REAL="$PLUGIN/conductor/scripts/check-method-budget.sh"

# DÉSARMEMENT en tête (P57-D-22) : un VF_DRIVER_LOCK hérité forcerait le mode « verrou unique » ;
# les autres variables déplaceraient la cible. GIT_* : une suite jouée depuis un hook git hériterait
# du dépôt du hook, pas de la fixture.
unset VF_DRIVER_LOCK VF_DRIVER_CHILDREN VF_DRIVER_TTL VF_DRIVER_SESSION_MAX VF_DRIVER_TEST_DIE_AFTER_MUTEX \
      GSD_WORKSTREAM VF_WORKSTREAM CLAUDE_CODE_SESSION_ID GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE

PASS=0; FAIL=0
ok() { echo "  ✓ $1"; PASS=$((PASS+1)); }
ko() { echo "  ✗ $1 — $2"; FAIL=$((FAIL+1)); }

TMP="$(mktemp -d)"
TMP="$(cd "$TMP" && pwd -P)"   # macOS : /var → /private/var, comparé canonicalisé
trap 'rm -rf "$TMP"' EXIT

EMPTY_HOME="$TMP/empty-home"
mkdir -p "$EMPTY_HOME"

# Assertions : contient / ne contient pas / égalité d'entiers.
has()    { if [[ "$2" == *"$3"* ]]; then ok "$1"; else ko "$1" "attendu « $3 », obtenu « $2 »"; fi; }
hasnt()  { if [[ "$2" != *"$3"* ]]; then ok "$1"; else ko "$1" "interdit « $3 », obtenu « $2 »"; fi; }
eq_rc()  { if [ "$2" -eq "$3" ]; then ok "$1"; else ko "$1" "exit $2 ≠ $3"; fi; }

# Laboratoire PARTITIONNÉ jetable : dépôt git, deux compartiments (alpha = 1er, omega = dernier par
# ordre alphabétique — les DEUX bouts sont exercés). Scripts installés à plat dans .claude/scripts/
# (copies RÉELLES de dag.sh, driver-lock.sh, workstream-policy.sh).
fixture_common_dir() { # <lab>
  local gc
  gc="$(cd "$1" && git rev-parse --git-common-dir 2>/dev/null)" || return 1
  case "$gc" in /*) ;; *) gc="$1/$gc" ;; esac
  (cd "$gc" 2>/dev/null && pwd -P)
}
# PRÉFLIGHT anti-pollution : le dossier commun de la fixture DOIT être sous $TMP canonicalisé, sinon
# une écriture (verrou, snapshot) irait dans le vrai .git du dépôt. Arrêt AVANT toute écriture, exit 2.
preflight() { # <lab>
  local gc; gc="$(fixture_common_dir "$1")" || gc=""
  case "$gc" in
    "$TMP"/*) return 0 ;;
    *) echo "PRÉFLIGHT FIXTURE CASSÉ — dossier commun '$gc' hors de '$TMP' : arrêt avant toute écriture" >&2
       exit 2 ;;
  esac
}
install_scripts() { # <lab> — scripts réels à plat
  mkdir -p "$1/.claude/scripts"
  cp "$DAG_REAL" "$DL_REAL" "$POLICY_REAL" "$1/.claude/scripts/"
}
mk_lab() { # <nom> — imprime le chemin du lab
  local d="$TMP/$1"
  mkdir -p "$d/.planning/workstreams/alpha" "$d/.planning/workstreams/omega"
  printf '# projet\n' > "$d/.planning/PROJECT.md"
  printf -- '---\nstatus: active\n---\n' > "$d/.planning/workstreams/alpha/STATE.md"
  printf -- '---\nstatus: active\n---\n' > "$d/.planning/workstreams/omega/STATE.md"
  git -C "$d" init -q -b main >/dev/null 2>&1 || git -C "$d" init -q >/dev/null 2>&1
  git -C "$d" add -A >/dev/null 2>&1
  git -C "$d" -c user.email=t@t -c user.name=t -c commit.gpgsign=false commit -q -m init >/dev/null 2>&1
  preflight "$d"
  install_scripts "$d"
  printf '%s' "$d"
}

dl() { # <lab> <args...> — driver-lock.sh réel DEPUIS la fixture, jamais depuis le vrai dépôt
  local lab="$1"; shift
  ( cd "$lab" && CLAUDE_CODE_SESSION_ID=sess-A "$lab/.claude/scripts/driver-lock.sh" "$@" )
}

run_gate() { # <args...> — gate sous test, environnement confiné ; GATE_SCRIPT substitue une copie mutée
  ( HOME="$EMPTY_HOME"; export HOME; unset CLAUDE_PLUGIN_ROOT 2>/dev/null; bash "${GATE_SCRIPT:-$SCRIPT}" "$@" )
}
G_OUT=""; G_ERR=""; G_RC=0
g() { # <args...> — capture stdout, stderr et rc séparément
  local ef="$TMP/g.err"
  G_OUT="$(run_gate "$@" 2>"$ef")"; G_RC=$?
  G_ERR="$(cat "$ef")"
}
e1_lines() { printf '%s\n' "$G_OUT" | { grep -F '[E1]' || true; }; }

echo "=== EW-TRACE — E1 lit le verrou du compartiment désigné, de bout en bout, sur clone jetable ==="
LAB="$(mk_lab trace)"
GC="$(fixture_common_dir "$LAB")"
has "EW-TRACE-0 — préflight : le dossier commun de la fixture est sous le répertoire de travail" "$GC" "$TMP/"

dl "$LAB" acquire --ws=alpha --owner=m1 --step=s >/dev/null; rc=$?
eq_rc "EW-TRACE-1.0 — acquire --ws=alpha exit 0" "$rc" 0
g --root "$LAB" --ws alpha
has "EW-TRACE-1.1 — verrou du compartiment tenu : ligne E1 de manque sur stdout" "$(e1_lines)" "[E1] verrou de driver présent"
has "EW-TRACE-1.2 — la ligne E1 nomme l'owner" "$(e1_lines)" "owner=m1"

dl "$LAB" release --ws=alpha --owner=m1 >/dev/null; rc=$?
eq_rc "EW-TRACE-2.0 — release --ws=alpha exit 0" "$rc" 0
g --root "$LAB" --ws alpha
eq_rc "EW-TRACE-2.1 — verrou relâché : aucune ligne E1 sur stdout (E1 sain)" "$(e1_lines | wc -c | tr -d ' ')" 0
hasnt "EW-TRACE-2.2 — le gate a réellement jugé (pas d'erreur d'usage, anti-vert-à-vide)" "$G_ERR" "argument inconnu"
if [ "$G_RC" -ne 64 ]; then ok "EW-TRACE-2.3 — verdict global hors usage (rc $G_RC ≠ 64)"; else ko "EW-TRACE-2.3" "exit 64 : le gate n'a pas jugé"; fi

# Faux driver-lock.sh : consigne l'état de VF_DRIVER_LOCK reçu, rend un JSON sain.
LABF="$(mk_lab fakedl)"
cat > "$LABF/.claude/scripts/driver-lock.sh" <<'EOF'
#!/usr/bin/env bash
printf 'set=%s val=[%s] args=%s\n' "${VF_DRIVER_LOCK+yes}" "${VF_DRIVER_LOCK-}" "$*" >> "$(dirname "$0")/seen.txt"
echo '{"present": false, "children_running": 0}'
EOF
chmod +x "$LABF/.claude/scripts/driver-lock.sh"
VF_DRIVER_LOCK=/nonexistent/hérité.lock g --root "$LABF" --ws alpha
SEEN="$(cat "$LABF/.claude/scripts/seen.txt" 2>/dev/null)"
has "EW-TRACE-3.1 — lab partitionné : VF_DRIVER_LOCK reçu VIDE malgré un export hérité" "$SEEN" "val=[]"
hasnt "EW-TRACE-3.2 — le chemin hérité n'atteint pas le driver-lock.sh frère" "$SEEN" "hérité"
has "EW-TRACE-3.3 — la lecture est status --ws=alpha" "$SEEN" "status --ws=alpha"

echo
echo "== résultat : $PASS ok, $FAIL ko =="
[ "$FAIL" -eq 0 ] || exit 1
[ "$PASS" -gt 0 ] || exit 1
exit 0
