#!/usr/bin/env bash
# test-driver-lock-consumers-ws.sh — Suite NEUVE des consommateurs conductor du verrou de driver
# PAR COMPARTIMENT (Phase 57, plan 57-06 ; 57-09 la complète avec le claim de branche).
#
# Jamais un ajout à test-check-guard-health.sh ni à test-dag.sh : ces deux suites sont le témoin de
# non-régression du lab PLAT (P57-D-03), elles ne bougent pas. Toute preuve neuve vit ici.
#
# TRACER (tâche 1) — un compartiment au progrès figé est vu par le watchdog, de bout en bout, avec le
# VRAI driver-lock.sh sur un clone jetable : CW-TRACE-1 (signal stall) · CW-TRACE-2 (sain) ·
# CW-TRACE-3 (abandon) · CW-HEALTH-MULTI (un seul signal pour la famille, abandon prioritaire).
#
# Toute invocation se fait depuis un sous-shell qui `cd` dans une fixture jetable, jamais depuis le vrai
# dépôt (piège P2) : le dossier commun du clone vient de `git rev-parse` sur le cwd. Les antidatages
# visent le meta résolu par `status --ws` (lien du verrou), jamais un chemin deviné.
#
# Modes : `full` (défaut) joue la matrice puis les mutants ; `matrice` est le sous-processus d'un mutant
# (CW_CGH / CW_DAG désignent la copie mutée à côté de ses voisins), sans mutants (pas de récursion).
#
# Exit 0 si tout passe, 1 sinon, 2 si la fixture est cassée (préflight).

set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS="$(cd "$HERE/.." && pwd)"
SUITE="$HERE/$(basename "$0")"
CGH="${CW_CGH:-$SCRIPTS/check-guard-health.sh}"
DAGSH="${CW_DAG:-$SCRIPTS/dag.sh}"
DL="$SCRIPTS/driver-lock.sh"
POLICY="$(cd "$SCRIPTS/../../planning-core/scripts" && pwd)/workstream-policy.sh"
CW_MODE="${CW_MODE:-full}"

# DÉSARMEMENT en tête (P57-D-22) : un VF_DRIVER_LOCK hérité forcerait le mode « verrou unique » et la
# suite ne mesurerait plus rien ; GIT_* : une suite jouée depuis un hook git hériterait de son dépôt.
unset VF_DRIVER_LOCK VF_DRIVER_CHILDREN VF_DRIVER_TTL VF_DRIVER_SESSION_MAX VF_DRIVER_TEST_DIE_AFTER_MUTEX \
      VF_STALL_WINDOW GSD_WORKSTREAM VF_WORKSTREAM CLAUDE_CODE_SESSION_ID GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE

WORK_DIR="$(mktemp -d)"
WORK_DIR="$(cd "$WORK_DIR" && pwd -P)"   # macOS : /var → /private/var, comparé canonicalisé
trap 'rm -rf "$WORK_DIR"' EXIT

PASS=0; FAIL=0
ok() { echo "  ✓ $1"; PASS=$((PASS+1)); }
ko() { echo "  ✗ $1 — $2"; FAIL=$((FAIL+1)); }

# Un cas = plusieurs vérifications, un seul verdict (identifiant stable, repris par les mutants).
CASE_ID=""; CASE_BAD=""
cbegin() { CASE_ID="$1"; CASE_BAD=""; }
cexp() { # <étiquette> <obtenu> <sous-chaîne attendue>
  case "$2" in *"$3"*) ;; *) CASE_BAD="$CASE_BAD [$1 : attendu «$3» obtenu «$(printf '%s' "$2" | tr -s '\n ' '  ')»]" ;; esac
}
cexp_not() { # <étiquette> <obtenu> <sous-chaîne interdite>
  case "$2" in *"$3"*) CASE_BAD="$CASE_BAD [$1 : interdit «$3» obtenu «$2»]" ;; esac
}
cexp_rc() { # <étiquette> <rc obtenu> <rc attendu>
  [ "$2" = "$3" ] || CASE_BAD="$CASE_BAD [$1 : attendu exit $3 obtenu exit $2]"
}
cend() { if [ -z "$CASE_BAD" ]; then ok "$CASE_ID"; else ko "$CASE_ID" "$CASE_BAD"; fi; }

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
  preflight "$d"
  printf '%s' "$d"
}

# Dossier commun du clone d'une fixture, canonicalisé.
fixture_common_dir() { # <lab>
  local gc
  gc="$(cd "$1" && git rev-parse --git-common-dir 2>/dev/null)" || return 1
  case "$gc" in /*) ;; *) gc="$1/$gc" ;; esac
  (cd "$gc" 2>/dev/null && pwd -P)
}

# PRÉFLIGHT anti-pollution (T-57-03, piège P2) : le dossier commun DOIT être sous $WORK_DIR, sinon une
# écriture irait dans le vrai .git du dépôt. Arrêt AVANT toute écriture, exit 2.
preflight() { # <lab>
  local gc; gc="$(fixture_common_dir "$1")" || gc=""
  case "$gc" in
    "$WORK_DIR"/*) return 0 ;;
    *) echo "PRÉFLIGHT FIXTURE CASSÉ — dossier commun '$gc' hors de '$WORK_DIR' : arrêt avant toute écriture" >&2
       exit 2 ;;
  esac
}

# driver-lock.sh réel, depuis la fixture, sous une session simulée.
dl() { # <lab> <session> <args...>
  local lab="$1" sid="$2"; shift 2
  ( cd "$lab" && CLAUDE_CODE_SESSION_ID="$sid" "$DL" "$@" </dev/null )
}

# Chemin du verrou d'un compartiment, lu sur `status --ws` AVANT acquisition (entrée absente : elle porte
# `lock`). Jamais deviné.
lock_path_of() { # <lab> <ws>
  dl "$1" probe status --ws="$2" 2>/dev/null | sed -n 's/.*"lock": "\([^"]*\)".*/\1/p'
}
lock_path_of_depot() { # <lab>
  dl "$1" probe status 2>/dev/null | sed -n 's/.*"lock": "\([^"]*\)".*/\1/p'
}
lock_meta_path() { # <lock>
  if [ -L "$1" ]; then echo "$(dirname "$1")/$(readlink "$1")/meta"; else echo "$1/meta"; fi
}
backdate() { # <lock> <clé> <secondes> — recule UNE horloge du meta, jamais l'autre
  local meta now old
  meta="$(lock_meta_path "$1")"; [ -f "$meta" ] || return 1
  now="$(date +%s)"; old=$(( now - $3 ))
  sed -i.bak "s/^$2=.*/$2=$old/" "$meta" && rm -f "${meta}.bak"
}

# Watchdog réel depuis la fixture : positionne CGH_OUT (stdout) et CGH_RC (jamais dans une substitution).
CGH_RC=0; CGH_OUT=""
cgh() { # <lab> <health> [args...]
  local lab="$1" health="$2"; shift 2
  CGH_OUT="$(cd "$lab" && "$CGH" --dir="$health" "$@" 2>"$WORK_DIR/cgh.err" </dev/null)"; CGH_RC=$?
}

# dag.sh réel depuis la fixture : positionne DAG_OUT (stdout) et DAG_RC ; stderr dans $WORK_DIR/dag.err.
DAG_RC=0; DAG_OUT=""
dag() { # <lab> <args...>
  local lab="$1"; shift
  DAG_OUT="$(cd "$lab" && "$DAGSH" "$@" 2>"$WORK_DIR/dag.err" </dev/null)"; DAG_RC=$?
}
# progress_epoch d'un verrou lu par `status` (mêmes arguments que le verbe : --ws=… ou rien).
progress_of() { # <lab> [args...]
  local lab="$1"; shift
  dl "$lab" probe status "$@" 2>/dev/null | sed -n 's/.*"progress_epoch": \([0-9]*\).*/\1/p'
}

matrice() {
  local LAB L1 L2 out n F e0 e1 d0 d1 ISO

  echo "=== CW-TRACE — le watchdog voit un compartiment, de bout en bout, sur clone jetable ==="
  LAB="$(mk_lab trace)"
  L1="$(lock_path_of "$LAB" alpha)"
  dl "$LAB" sess-A acquire --ws=alpha --owner=m1 --step=s-alpha >/dev/null
  backdate "$L1" progress_epoch 1000
  cbegin CW-TRACE-1
  cgh "$LAB" "$WORK_DIR/h-trace1" --hook; out="$CGH_OUT"
  cexp_rc "exit" "$CGH_RC" 0
  cexp "ligne stall" "$out" "stall detecte"
  cexp "sujet nommé" "$out" "ws=alpha"
  cexp "owner" "$out" "owner=m1"
  n="$(printf '%s\n' "$out" | grep -c .)"; cexp_rc "une seule ligne" "$n" 1
  cend

  dl "$LAB" sess-A release --ws=alpha --owner=m1 >/dev/null
  cbegin CW-TRACE-2
  cgh "$LAB" "$WORK_DIR/h-trace2"; out="$CGH_OUT"
  cexp_rc "exit SAIN" "$CGH_RC" 3
  cexp "stdout vide" "[$out]" "[]"
  cend

  dl "$LAB" sess-A acquire --ws=alpha --owner=m1 --step=s-alpha >/dev/null
  backdate "$L1" heartbeat_epoch 2000
  cbegin CW-TRACE-3
  cgh "$LAB" "$WORK_DIR/h-trace3" --hook; out="$CGH_OUT"
  cexp_rc "exit" "$CGH_RC" 0
  cexp "ligne abandon" "$out" "abandon detecte"
  cexp "sujet nommé" "$out" "ws=alpha"
  cexp_not "jamais confondu avec un stall" "$out" "stall detecte"
  cend
  dl "$LAB" sess-A release --ws=alpha --owner=m1 >/dev/null 2>&1

  echo "=== CW-HEALTH-MULTI — plusieurs verrous en signal : une seule ligne, abandon prioritaire ==="
  LAB="$(mk_lab multi)"
  L1="$(lock_path_of "$LAB" alpha)"; L2="$(lock_path_of "$LAB" omega)"
  dl "$LAB" sess-A acquire --ws=alpha --owner=m1 --step=s-alpha >/dev/null
  dl "$LAB" sess-B acquire --ws=omega --owner=m2 --step=s-omega >/dev/null
  backdate "$L1" progress_epoch 1000
  backdate "$L2" heartbeat_epoch 2000
  cbegin CW-HEALTH-MULTI
  cgh "$LAB" "$WORK_DIR/h-multi" --hook; out="$CGH_OUT"
  cexp_rc "exit" "$CGH_RC" 0
  n="$(printf '%s\n' "$out" | grep -c .)"; cexp_rc "une seule ligne pour la famille" "$n" 1
  cexp "abandon prioritaire" "$out" "abandon detecte"
  cexp "sujet de l'abandon" "$out" "ws=omega"
  cexp "suffixe" "$out" "(+1 autre(s) verrou(s) en signal — driver-lock.sh status --all)"
  cexp_not "le stall n'est pas nommé" "$out" "ws=alpha"
  cend

  echo "=== CW-Q — les quatre issues du watchdog partitionné ==="
  LAB="$(mk_lab q)"
  L1="$(lock_path_of "$LAB" alpha)"
  dl "$LAB" sess-A acquire --ws=alpha --owner=m1 --step=s-alpha >/dev/null
  backdate "$L1" progress_epoch 1000
  cbegin CW-Q-SIGNAL
  cgh "$LAB" "$WORK_DIR/h-q1"; out="$CGH_OUT"
  cexp_rc "exit signal" "$CGH_RC" 0
  cexp "ligne" "$out" "[mission-watchdog] stall detecte"
  cexp "sujet" "$out" "ws=alpha"
  cend
  # Verrou présent ET sain (les deux horloges fraîches) : jamais un signal.
  dl "$LAB" sess-A release --ws=alpha --owner=m1 >/dev/null 2>&1
  dl "$LAB" sess-A acquire --ws=alpha --owner=m1 --step=s-alpha >/dev/null
  cbegin CW-Q-SAIN
  cgh "$LAB" "$WORK_DIR/h-q2"; out="$CGH_OUT"
  cexp_rc "exit SAIN" "$CGH_RC" 3
  cexp "stdout vide" "[$out]" "[]"
  cend
  dl "$LAB" sess-A release --ws=alpha --owner=m1 >/dev/null 2>&1

  # Partition illisible (dossier des compartiments remplacé par un lien) : status --all refuse, le watchdog
  # est INDÉTERMINÉ et BRUYANT, jamais SAIN.
  LAB="$(mk_lab qb)"
  mv "$LAB/.planning/workstreams" "$WORK_DIR/qb-reel"
  ln -s "$WORK_DIR/qb-reel" "$LAB/.planning/workstreams"
  cbegin CW-Q-BRUYANT
  cgh "$LAB" "$WORK_DIR/h-qb"; out="$CGH_OUT"
  cexp_rc "exit INDÉTERMINÉ" "$CGH_RC" 4
  cexp "stdout vide" "[$out]" "[]"
  [ -f "$WORK_DIR/h-qb/check-guard-health.sh.marker" ] || CASE_BAD="$CASE_BAD [marqueur de santé absent]"
  [ -s "$WORK_DIR/cgh.err" ] || CASE_BAD="$CASE_BAD [stderr vide : indéterminé silencieux]"
  cend

  # JSON de sibling non conforme (`locks` n'est pas un tableau) : silence total, jamais une ligne ni un marqueur.
  ISO="$WORK_DIR/q-silence/conductor/scripts"; mkdir -p "$ISO"
  cp "$CGH" "$ISO/check-guard-health.sh"; chmod +x "$ISO/check-guard-health.sh"
  printf '#!/usr/bin/env bash\necho '"'"'{"present": true, "locks": "oops"}'"'"'\nexit 0\n' > "$ISO/driver-lock.sh"
  chmod +x "$ISO/driver-lock.sh"
  cbegin CW-Q-SILENCE
  out="$("$ISO/check-guard-health.sh" --hook --dir="$WORK_DIR/h-qs" 2>/dev/null </dev/null)"; e0=$?
  cexp_rc "exit hook" "$e0" 0
  cexp "stdout vide" "[$out]" "[]"
  out="$("$ISO/check-guard-health.sh" --dir="$WORK_DIR/h-qs" 2>/dev/null </dev/null)"; e0=$?
  cexp_rc "exit SAIN" "$e0" 3
  [ ! -e "$WORK_DIR/h-qs" ] || CASE_BAD="$CASE_BAD [dossier de santé créé à tort]"
  cend

  echo "=== CW-DAG — le DAG est lié à son compartiment ==="
  LAB="$(mk_lab dag)"
  F="$WORK_DIR/dag-ws.json"
  L1="$(lock_path_of "$LAB" alpha)"; L2="$(lock_path_of_depot "$LAB")"
  dl "$LAB" sess-A acquire --ws=alpha --owner=m1 --step=s-alpha >/dev/null
  dl "$LAB" sess-D acquire --owner=md --step=s-depot >/dev/null
  backdate "$L1" progress_epoch 500
  backdate "$L2" progress_epoch 500
  dag "$LAB" init --file="$F" --ws=alpha
  dag "$LAB" add --file="$F" --id=a --step=1
  e0="$(progress_of "$LAB" --ws=alpha)"; d0="$(progress_of "$LAB")"
  dag "$LAB" mark --file="$F" --id=a --status=running
  e1="$(progress_of "$LAB" --ws=alpha)"; d1="$(progress_of "$LAB")"
  cbegin CW-DAG-WS
  cexp "ws écrit par init" "$(cat "$F")" '"ws": "alpha"'
  cexp_rc "mark" "$DAG_RC" 0
  [ -n "$e0" ] && [ -n "$e1" ] && [ "$e1" -gt "$e0" ] 2>/dev/null || CASE_BAD="$CASE_BAD [progress_epoch de alpha n'a pas avancé : $e0 -> $e1]"
  [ -n "$d0" ] && [ "$d1" = "$d0" ] || CASE_BAD="$CASE_BAD [progress_epoch du dépôt a bougé : $d0 -> $d1]"
  cend
  dag "$LAB" add --file="$F" --id=b --step=2 --deps=a
  dag "$LAB" mark --file="$F" --id=a --status=done
  dag "$LAB" reopen --file="$F" --id=a
  cbegin CW-DAG-KEEP
  cexp_rc "reopen" "$DAG_RC" 0
  cexp "ws conservé après add, mark et reopen" "$(cat "$F")" '"ws": "alpha"'
  cexp "noeuds conservés" "$(cat "$F")" '"id": "b"'
  cend
  dl "$LAB" sess-A release --ws=alpha --owner=m1 >/dev/null 2>&1
  dl "$LAB" sess-D release --owner=md >/dev/null 2>&1

  LAB="$(mk_lab dagn)"
  F="$WORK_DIR/dag-nows.json"
  L2="$(lock_path_of_depot "$LAB")"
  dl "$LAB" sess-D acquire --owner=md --step=s-depot >/dev/null
  backdate "$L2" progress_epoch 500
  dag "$LAB" init --file="$F"
  cbegin CW-DAG-NOWS
  printf '{\n  "nodes": []\n}\n' > "$WORK_DIR/dag-nows.attendu"
  cmp -s "$F" "$WORK_DIR/dag-nows.attendu" || CASE_BAD="$CASE_BAD [init sans --ws : octets différents d'aujourd'hui]"
  cexp_not "aucune clé ws" "$(cat "$F")" '"ws"'
  dag "$LAB" add --file="$F" --id=a --step=1
  d0="$(progress_of "$LAB")"
  dag "$LAB" mark --file="$F" --id=a --status=running
  d1="$(progress_of "$LAB")"
  [ -n "$d0" ] && [ -n "$d1" ] && [ "$d1" -gt "$d0" ] 2>/dev/null || CASE_BAD="$CASE_BAD [mark sans ws : le verrou du dépôt n'a pas avancé : $d0 -> $d1]"
  cexp_not "aucune clé ws après mark" "$(cat "$F")" '"ws"'
  cend
  dl "$LAB" sess-D release --owner=md >/dev/null 2>&1

  cbegin CW-DAG-OPT
  F="$WORK_DIR/dag-opt.json"
  dag "$LAB" init --file="$F"
  cp "$F" "$WORK_DIR/dag-opt.avant"
  dag "$LAB" add --file="$F" --id=x --ws=alpha
  cexp_rc "add --ws" "$DAG_RC" 1
  cexp "message d'usage nommé" "$(cat "$WORK_DIR/dag.err")" "n'est admis que par init"
  cmp -s "$F" "$WORK_DIR/dag-opt.avant" || CASE_BAD="$CASE_BAD [le fichier a changé malgré le refus]"
  dag "$LAB" mark --file="$F" --id=x --status=done --ws=alpha
  cexp_rc "mark --ws" "$DAG_RC" 1
  cend
}

if [ "$CW_MODE" = "full" ]; then
  echo "== test-driver-lock-consumers-ws =="
fi
matrice

echo
echo "== Résultat : $PASS OK · $FAIL KO =="
[ "$PASS" -gt 0 ] || { echo "✗ zéro assertion exécutée"; exit 1; }
[ "$FAIL" -eq 0 ]
