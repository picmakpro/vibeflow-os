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
# Borne de parallélisme des mutants : GW_MUT_PAR (entier >= 1, défaut 4, même variable que test-guard-driver-lock-ws.sh) =
# nombre maximal de matrices de mutants simultanées ; sans borne, elles saturaient un runner CI 4 vCPU. Ni la liste des
# mutants, ni les attendus, ni le verdict, ni l'ordre d'évaluation ne changent ; le pic mesuré est affiché.
#
# Exit 0 si tout passe, 1 sinon, 2 si la fixture est cassée (préflight).

set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS="$(cd "$HERE/.." && pwd)"
SUITE="$HERE/$(basename "$0")"
CGH="${CW_CGH:-$SCRIPTS/check-guard-health.sh}"
DAGSH="${CW_DAG:-$SCRIPTS/dag.sh}"
DL="$SCRIPTS/driver-lock.sh"
CBC="${CW_CBC:-$SCRIPTS/check-branch-claim.sh}"
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
cexp_eq() { # <étiquette> <obtenu> <attendu> (nombres)
  [ "$2" = "$3" ] || CASE_BAD="$CASE_BAD [$1 : attendu $3 obtenu $2]"
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
  # Commit init ANTIDATÉ de 2000 s (> fenêtre de stall de 900 s) : check-guard-health.sh compte le dernier
  # commit de la branche comme progression (arbitrage Samuel, AskUserQuestion session principale,
  # 2026-10-13, Q1) ; un commit frais ferait disparaître les stalls que les cas fabriquent.
  local when=$(( $(date +%s) - 2000 ))
  GIT_COMMITTER_DATE="$when +0000" GIT_AUTHOR_DATE="$when +0000" \
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

# Claim de branche réel : positionne CBC_OUT (stdout), CBC_ERR (stderr) et CBC_RC (jamais dans une substitution).
CBC_RC=0; CBC_OUT=""; CBC_ERR=""
cbc() { # <cwd> <args...>
  local cwd="$1"; shift
  CBC_OUT="$(cd "$cwd" && "$CBC" "$@" 2>"$WORK_DIR/cbc.err" </dev/null)"; CBC_RC=$?
  CBC_ERR="$(cat "$WORK_DIR/cbc.err")"
}
# Clone partitionné + worktree lié sur la branche `b` ; verrou du compartiment alpha pris DEPUIS le worktree
# (le meta porte branch=b et le worktree lié) ; le checkout principal passe ensuite sur `b`.
mk_claim_lab() { # <nom> → positionne CLAIM_LAB (principal) et CLAIM_WT (lié)
  CLAIM_LAB="$(mk_lab "$1")"
  CLAIM_WT="$WORK_DIR/$1-wt"
  git -C "$CLAIM_LAB" worktree add -q -b b "$CLAIM_WT" >/dev/null 2>&1
  CLAIM_WT="$(cd "$CLAIM_WT" && pwd -P)"
  CLAIM_L1="$(lock_path_of "$CLAIM_WT" alpha)"   # lu AVANT l'acquisition (l'entrée présente ne porte plus `lock`)
  dl "$CLAIM_WT" sess-A acquire --ws=alpha --owner=m1 --step=s-alpha >/dev/null
  git -C "$CLAIM_LAB" checkout -q --ignore-other-worktrees b >/dev/null 2>&1
}

# Commit vide RECENT (maintenant - <secs>) dans un clone ou un worktree de fixture : le lab de mk_lab est antidate.
fresh_commit() { # <dir> <secs>
  local when=$(( $(date +%s) - $2 ))
  GIT_COMMITTER_DATE="$when +0000" GIT_AUTHOR_DATE="$when +0000" \
    git -C "$1" -c user.email=t@t -c user.name=t -c commit.gpgsign=false -c core.hooksPath=/dev/null commit -q --allow-empty -m fresh >/dev/null 2>&1
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
  n="$(printf '%s\n' "$out" | grep -c .)"; cexp_eq "une seule ligne" "$n" 1
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
  n="$(printf '%s\n' "$out" | grep -c .)"; cexp_eq "une seule ligne pour la famille" "$n" 1
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

  echo "=== CW-Q-COMMIT — un commit recent ecarte le stall de CHAQUE entree de la famille (age effectif par entree) ==="
  # Un seul verrou fige ne distingue pas le mutant « age brut dans le tri des entrees » (l'entree retenue est
  # recalculee ensuite) : il faut un abandon (jamais ecarte par un commit) a cote d'un verrou fige — l'age brut
  # compterait ce dernier comme un second signal et ajouterait le suffixe « (+1 autre(s) verrou(s)) ».
  LAB="$(mk_lab qc)"
  L1="$(lock_path_of "$LAB" alpha)"; L2="$(lock_path_of "$LAB" omega)"
  dl "$LAB" sess-A acquire --ws=alpha --owner=m1 --step=s-alpha >/dev/null
  dl "$LAB" sess-B acquire --ws=omega --owner=m2 --step=s-omega >/dev/null
  backdate "$L2" progress_epoch 1000
  fresh_commit "$LAB" 60
  cbegin CW-Q-COMMIT-SAIN
  cgh "$LAB" "$WORK_DIR/h-qc1"; out="$CGH_OUT"
  cexp_rc "exit SAIN" "$CGH_RC" 3
  cexp "stdout vide" "[$out]" "[]"
  cend
  backdate "$L1" heartbeat_epoch 2000
  cbegin CW-Q-COMMIT-ABANDON
  cgh "$LAB" "$WORK_DIR/h-qc2" --hook; out="$CGH_OUT"
  cexp_rc "exit" "$CGH_RC" 0
  cexp "abandon malgre le commit" "$out" "abandon detecte"
  cexp "sujet de l'abandon" "$out" "ws=alpha"
  cexp_not "le verrou fige, ecarte par le commit, n'est pas un second signal" "$out" "autre(s) verrou(s)"
  n="$(printf '%s\n' "$out" | grep -c .)"; cexp_eq "une seule ligne" "$n" 1
  cend
  dl "$LAB" sess-A release --ws=alpha --owner=m1 >/dev/null 2>&1
  dl "$LAB" sess-B release --ws=omega --owner=m2 >/dev/null 2>&1

  echo "=== CW-Q-WT — le commit recent d'un AUTRE worktree du clone ecarte le stall d'un compartiment ==="
  LAB="$(mk_lab qwt)"
  L1="$(lock_path_of "$LAB" alpha)"
  git -C "$LAB" worktree add -q -b qwt "$WORK_DIR/qwt-wt" >/dev/null 2>&1
  fresh_commit "$WORK_DIR/qwt-wt" 60
  dl "$LAB" sess-A acquire --ws=alpha --owner=m1 --step=s-alpha >/dev/null
  backdate "$L1" progress_epoch 1000
  cbegin CW-Q-WT
  cgh "$LAB" "$WORK_DIR/h-qwt"; out="$CGH_OUT"
  cexp_rc "exit SAIN" "$CGH_RC" 3
  cexp "stdout vide" "[$out]" "[]"
  cend
  # Temoin : sans commit recent nulle part, le meme verrou fige reste un stall.
  LAB="$(mk_lab qwt2)"
  L1="$(lock_path_of "$LAB" alpha)"
  git -C "$LAB" worktree add -q -b qwt2 "$WORK_DIR/qwt2-wt" >/dev/null 2>&1
  dl "$LAB" sess-A acquire --ws=alpha --owner=m1 --step=s-alpha >/dev/null
  backdate "$L1" progress_epoch 1000
  cbegin CW-Q-WT-TEMOIN
  cgh "$LAB" "$WORK_DIR/h-qwt2"; out="$CGH_OUT"
  cexp_rc "exit" "$CGH_RC" 0
  cexp "stall maintenu" "$out" "stall detecte"
  cend

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

  echo "=== CW-CLAIM — le claim de branche voit les verrous du clone ==="
  mk_claim_lab claimwt
  cbegin CW-CLAIM-WT
  cbc "$CLAIM_LAB" --hook; out="$CBC_OUT"
  cexp_rc "exit signal (hook)" "$CBC_RC" 0
  cexp "ligne" "$out" "[branch-claim]"
  cexp "compartiment nommé" "$out" "compartiment alpha"
  n="$(printf '%s\n' "$out" | grep -c .)"; cexp_eq "une seule ligne" "$n" 1
  cbc "$CLAIM_LAB"
  cexp_rc "exit signal (CLI)" "$CBC_RC" 0
  cexp "diagnostic sur stderr" "$CBC_ERR" "revendiquee par un lock actif"
  cend

  # Même verrou, interrogé DEPUIS le worktree qui le tient : même arbre, rien à signaler.
  cbegin CW-CLAIM-SAME
  cbc "$CLAIM_WT"
  cexp_rc "exit SAIN" "$CBC_RC" 3
  cexp "message" "$CBC_ERR" "SAIN"
  cexp "verrou examiné et compté" "$CBC_ERR" "1 lock(s) de driver examine(s)"
  cbc "$CLAIM_WT" --hook
  cexp_rc "exit hook" "$CBC_RC" 0
  cexp "stdout vide" "[$CBC_OUT]" "[]"
  cend

  # Aucun verrou, ni du clone ni du checkout : le message d'avant, octet pour octet.
  LAB="$(mk_lab claimnone)"
  cbegin CW-CLAIM-NONE
  cbc "$LAB"
  cexp_rc "exit SAIN" "$CBC_RC" 3
  cexp "message d'avant" "$CBC_ERR" "SAIN — aucun lock de driver actif (.planning/DRIVER.lock absent)."
  cend

  # Meta illisible : INDÉTERMINÉ, jamais SAIN ; un signal d'un AUTRE verrou l'emporte.
  LAB="$(mk_lab claimmeta)"
  L2="$(lock_path_of "$LAB" omega)"
  dl "$LAB" sess-B acquire --ws=omega --owner=m2 --step=s-omega >/dev/null
  rm -f "$(lock_meta_path "$L2")"
  cbegin CW-CLAIM-META
  cbc "$LAB"
  cexp_rc "exit INDÉTERMINÉ" "$CBC_RC" 4
  cexp "message" "$CBC_ERR" "INDETERMINE"
  cexp "meta nommé" "$CBC_ERR" "meta est illisible"
  cbc "$LAB" --hook
  cexp_rc "exit hook (silence harness)" "$CBC_RC" 0
  cexp "stdout vide" "[$CBC_OUT]" "[]"
  git -C "$LAB" worktree add -q -b b "$WORK_DIR/claimmeta-wt" >/dev/null 2>&1
  dl "$WORK_DIR/claimmeta-wt" sess-A acquire --ws=alpha --owner=m1 --step=s-alpha >/dev/null
  git -C "$LAB" checkout -q --ignore-other-worktrees b >/dev/null 2>&1
  cbc "$LAB" --hook
  cexp_rc "exit signal malgré l'indéterminé" "$CBC_RC" 0
  cexp "signal nommé" "$CBC_OUT" "compartiment alpha"
  cend

  # --lock / VF_DRIVER_LOCK : UN seul verrou examiné, ceux du clone sont ignorés (P57-D-22).
  L1="$CLAIM_L1"
  cbegin CW-CLAIM-LOCKOPT
  cbc "$CLAIM_LAB" --lock="$WORK_DIR/aucun-verrou"
  cexp_rc "--lock absent" "$CBC_RC" 3
  cexp "message du seul verrou désigné" "$CBC_ERR" "aucun lock de driver actif ($WORK_DIR/aucun-verrou absent)"
  VF_DRIVER_LOCK="$WORK_DIR/aucun-verrou" cbc "$CLAIM_LAB"
  cexp_rc "VF_DRIVER_LOCK absent" "$CBC_RC" 3
  cexp "message env" "$CBC_ERR" "aucun lock de driver actif ($WORK_DIR/aucun-verrou absent)"
  cbc "$CLAIM_LAB" --lock="$L1"
  cexp_rc "--lock désignant le verrou signalant" "$CBC_RC" 0
  cexp_not "pas de compartiment nommé en verrou unique" "$CBC_ERR" "compartiment"
  cend

  # Les trois issues du claim partitionné.
  cbegin CW-Q-CLAIM-SIGNAL
  cbc "$CLAIM_LAB" --hook
  cexp_rc "exit" "$CBC_RC" 0
  cexp "ligne" "$CBC_OUT" "[branch-claim]"
  cend
  cbegin CW-Q-CLAIM-SAIN
  cbc "$CLAIM_WT"
  cexp_rc "exit" "$CBC_RC" 3
  cexp "diagnostic" "$CBC_ERR" "SAIN"
  cend
  cbegin CW-Q-CLAIM-INDET
  LAB="$WORK_DIR/claimmeta"
  git -C "$LAB" checkout -q --ignore-other-worktrees main >/dev/null 2>&1
  cbc "$LAB"
  cexp_rc "exit" "$CBC_RC" 4
  cexp "diagnostic" "$CBC_ERR" "INDETERMINE"
  cend
}

if [ "$CW_MODE" = "full" ]; then
  echo "== test-driver-lock-consumers-ws =="
fi
matrice

if [ "$CW_MODE" = "full" ]; then
echo
echo "== mutants =="
# Chaque mutant = une substitution `sed` sur UNE ligne-ancre (compte = 1) d'une COPIE du script, posée à côté de
# ses voisins réels (driver-lock.sh, workstream-policy.sh, et check-guard-health.sh pour dag.sh : sinon la copie
# rougirait pour la mauvaise raison). La matrice (tous les cas ci-dessus) est rejouée en sous-processus contre la
# copie ; l'ensemble des cas dont le verdict bascule est comparé EXACTEMENT à l'attendu. Matrices en parallèle.
MUT_KILLED=0; MUT_TOTAL=9; MUT_IDS=""; t0=$SECONDS
GW_MUT_PAR="${GW_MUT_PAR:-4}"
case "$GW_MUT_PAR" in ''|*[!0-9]*|0) echo "GW_MUT_PAR invalide ($GW_MUT_PAR) : entier >= 1 attendu" >&2; exit 2 ;; esac
MUT_PEAK=0
mut_running() { # nombre de matrices en cours (jobs de ce shell)
  jobs -rp > "$WORK_DIR/.jobs-en-cours"; wc -l < "$WORK_DIR/.jobs-en-cours" | tr -d ' '
}
mut_throttle() { # attend qu'un emplacement se libère (bash 3.2 : pas de `wait -n`, comptage + attente courte)
  while [ "$(mut_running)" -ge "$GW_MUT_PAR" ]; do sleep 0.2; done
}
mut_fail_ids() { LC_ALL=C sed -n 's/^  ✗ \(CW-[A-Za-z0-9-]*\) .*/\1/p' "$1" | LC_ALL=C sort -u; }
mut_dir() { # <dossier> <cgh|dag|cbc> → pose les voisins réels dans le dossier d'une copie (cbc n'en source aucun)
  mkdir -p "$1"; cp "$DL" "$1/driver-lock.sh"; cp "$POLICY" "$1/workstream-policy.sh"
  [ "$2" = dag ] && cp "$SCRIPTS/check-guard-health.sh" "$1/check-guard-health.sh"
  chmod +x "$1"/*.sh
}
mut_run() { # <kind> <dossier> <journal>
  if [ "$1" = cgh ]; then CW_MODE=matrice CW_CGH="$2/check-guard-health.sh" bash "$SUITE" > "$3" 2>&1
  elif [ "$1" = cbc ]; then CW_MODE=matrice CW_CBC="$2/check-branch-claim.sh" bash "$SUITE" > "$3" 2>&1
  else CW_MODE=matrice CW_DAG="$2/dag.sh" bash "$SUITE" > "$3" 2>&1; fi
}
mutant() { # <id> <cgh|dag> <ancre BRE> <expression sed> <attendu : cas séparés par des espaces>
  local id="$1" kind="$2" anchor="$3" expr="$4" expected="$5" dir="$WORK_DIR/mut-$1" f n
  case "$kind" in cgh) f="check-guard-health.sh" ;; cbc) f="check-branch-claim.sh" ;; *) f="dag.sh" ;; esac
  MUT_IDS="$MUT_IDS $id"
  mut_dir "$dir" "$kind"
  printf '%s\n' $expected | LC_ALL=C sort -u > "$dir/attendu.txt"
  cp "$SCRIPTS/$f" "$dir/$f"; chmod +x "$dir/$f"; cp "$dir/$f" "$dir/copie-temoin.sh"
  n="$(grep -c -e "$anchor" "$dir/$f")"
  if [ "$n" != "1" ]; then echo "ancre non unique ($n occurrences de [$anchor])" > "$dir/prepko"; return; fi
  sed -i.bak -e "/$anchor/$expr" "$dir/$f"; rm -f "$dir/$f.bak"
  if cmp -s "$dir/$f" "$dir/copie-temoin.sh"; then echo "mutant NON OPPOSABLE : la substitution n'a rien changé" > "$dir/prepko"; return; fi
  if ! bash -n "$dir/$f" 2>/dev/null; then echo "le mutant n'est pas un script valide (il rougirait pour la mauvaise raison)" > "$dir/prepko"; return; fi
  mut_throttle
  ( mut_run "$kind" "$dir" "$dir/matrice.log"; echo $? > "$dir/rc" ) &
  local cur; cur="$(mut_running)"; [ "$cur" -gt "$MUT_PEAK" ] && MUT_PEAK="$cur"
}
mutant_eval() { # <id>
  local id="$1" dir="$WORK_DIR/mut-$1" rc got fam
  if [ -f "$dir/prepko" ]; then ko "CW-M-$id" "$(cat "$dir/prepko")"; return; fi
  rc="$(cat "$dir/rc" 2>/dev/null || echo absent)"
  if [ "$rc" != 0 ] && [ "$rc" != 1 ]; then ko "CW-M-$id" "la matrice a planté (exit $rc), pas un échec de cas"; return; fi
  grep -q '^== Résultat : ' "$dir/matrice.log" || { ko "CW-M-$id" "la matrice n'a pas atteint son bilan"; return; }
  mut_fail_ids "$dir/matrice.log" > "$dir/obtenu.txt"
  got="$(tr '\n' ' ' < "$dir/obtenu.txt")"
  if cmp -s "$dir/attendu.txt" "$dir/obtenu.txt"; then
    ok "CW-M-$id — mutant tué : bascule exactement {$(tr '\n' ' ' < "$dir/attendu.txt")}"
    while IFS= read -r fam; do
      LC_ALL=C sed -n "s/^  ✗ $fam — /      rouge $fam : /p" "$dir/matrice.log" | head -1
    done < "$dir/obtenu.txt"
    MUT_KILLED=$((MUT_KILLED+1))
  else
    ko "CW-M-$id" "ensemble basculé INATTENDU : attendu {$(tr '\n' ' ' < "$dir/attendu.txt")} obtenu {$got}"
  fi
}

# Témoin préalable : les copies NON mutées (avec leurs voisins) ne basculent AUCUN cas.
mut_dir "$WORK_DIR/mut-temoin-cgh" cgh; cp "$SCRIPTS/check-guard-health.sh" "$WORK_DIR/mut-temoin-cgh/check-guard-health.sh"
mut_dir "$WORK_DIR/mut-temoin-dag" dag; cp "$SCRIPTS/dag.sh" "$WORK_DIR/mut-temoin-dag/dag.sh"
( mut_run cgh "$WORK_DIR/mut-temoin-cgh" "$WORK_DIR/mut-temoin-cgh/matrice.log" ) &
mut_dir "$WORK_DIR/mut-temoin-cbc" cbc; cp "$SCRIPTS/check-branch-claim.sh" "$WORK_DIR/mut-temoin-cbc/check-branch-claim.sh"
( mut_run dag "$WORK_DIR/mut-temoin-dag" "$WORK_DIR/mut-temoin-dag/matrice.log" ) &
( mut_run cbc "$WORK_DIR/mut-temoin-cbc" "$WORK_DIR/mut-temoin-cbc/matrice.log" ) &

mutant a cgh 'DRIVER_LOCK_SH" status --all 2>' 's/status --all/status/' "CW-HEALTH-MULTI CW-Q-COMMIT-ABANDON CW-Q-SIGNAL CW-Q-WT-TEMOIN CW-TRACE-1 CW-TRACE-3"
mutant b cgh 'if best is None or rank > best_rank:' 's/rank > best_rank/rank < best_rank/' "CW-HEALTH-MULTI"
mutant f dag '"mark-progress", f"--owner={owner}"' 's/\] + ws_args,/],/' "CW-DAG-WS"
mutant g dag 'init_dag\["ws"\] = ws_arg' 's/init_dag\["ws"\] = ws_arg/pass/' "CW-DAG-KEEP CW-DAG-WS"
# Claim de branche (57-09) : examen des verrous du clone retiré / comparaison d'arbre retirée / indéterminé agrégé comme sain.
mutant c cbc 'if \[ -n "\$COMMON" \]; then' 's/if \[ -n "\$COMMON" \]; then/if false; then/' "CW-CLAIM-META CW-CLAIM-SAME CW-CLAIM-WT CW-Q-CLAIM-INDET CW-Q-CLAIM-SIGNAL"
mutant d cbc 'if \[ "\$(norm_path "\$claim_worktree")" = ' 's/if \[ "\$(norm_path "\$claim_worktree")" = .*; then$/if false; then/' "CW-CLAIM-SAME CW-Q-CLAIM-SAIN"
mutant e cbc '\[ -z "\$INDET_MSG" \] || indetermine' 's/\[ -z "\$INDET_MSG" \] || indetermine "\$INDET_MSG"/:/' "CW-CLAIM-META CW-Q-CLAIM-INDET"

# Age de progression effectif (REGLE DE PROGRESSION) : h = age brut dans le tri des entrees de `locks` ; i = lecture
# limitee au HEAD du repertoire courant (les autres worktrees du clone ne comptent plus).
mutant h cgh 'pa = eff(e.get("progress_age_seconds"))' 's/pa = eff(e.get("progress_age_seconds"))/pa = e.get("progress_age_seconds")/' "CW-Q-COMMIT-ABANDON"
mutant i cgh 'cgh_git worktree list --porcelain -z' 's/worktree list --porcelain -z/worktree list --nonexistent-flag/' "CW-Q-WT"

wait
for t in cgh dag cbc; do
  nko="$(mut_fail_ids "$WORK_DIR/mut-temoin-$t/matrice.log" | wc -l | tr -d ' ')"
  if grep -q '^== Résultat : ' "$WORK_DIR/mut-temoin-$t/matrice.log" && [ "$nko" = 0 ]; then ok "CW-M-témoin-$t — la copie non mutée ne bascule aucun cas"
  else ko "CW-M-témoin-$t" "la copie non mutée rend $nko cas en échec (ou n'a pas atteint son bilan)"; fi
done
for id in $MUT_IDS; do mutant_eval "$id"; done
echo "  durée des mutants : $((SECONDS-t0))s · pic de concurrence : $MUT_PEAK matrice(s) simultanée(s) (borne GW_MUT_PAR=$GW_MUT_PAR)"
if [ "$MUT_KILLED" -eq "$MUT_TOTAL" ]; then
  echo "== mutants : $MUT_TOTAL/$MUT_TOTAL tués =="
else
  echo "== mutants : $MUT_KILLED/$MUT_TOTAL tués =="
  FAIL=$((FAIL+1))
fi
fi   # CW_MODE = full (mutants)

echo
echo "== Résultat : $PASS OK · $FAIL KO =="
[ "$PASS" -gt 0 ] || { echo "✗ zéro assertion exécutée"; exit 1; }
[ "$FAIL" -eq 0 ]
