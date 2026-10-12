#!/usr/bin/env bash
# test-check-mission-exit-ws.sh — Suite NEUVE du gate de sortie de mission PAR COMPARTIMENT (Phase 57, plan 57-07).
#
# Jamais un ajout à test-check-mission-exit.sh : cette suite est le témoin de non-régression du lab
# PLAT (P57-D-03), elle ne bouge pas. Toute preuve neuve vit ici.
#
# TRACER (tâche 1) — E1 juge le verrou du compartiment désigné par --ws, de bout en bout :
#   EW-TRACE-1 verrou du compartiment tenu → ligne E1 de manque (owner=) · EW-TRACE-2 relâché → aucune
#   ligne E1 · EW-TRACE-3 le driver-lock.sh frère reçoit VF_DRIVER_LOCK VIDE · EW-TRACE-0 préflight.
# Tâche 2 : EW-NOWS (partitionné sans --ws = INDÉTERMINÉ, jamais 3) · EW-CHILD (enfant consigné) · EW-GEN
# (identité d'E7 = génération du verrou du compartiment, « ? » si illisible) · EW-SNAP (--budget-snapshot sans
# --ws = exit 4, motif nommé, aucun fichier) · EW-E4 (--ws surcharge GSD_WORKSTREAM) · EW-DEPOT (verrou de dépôt
# dit sur stderr, jamais un manque) · EW-FLAT (lab plat inchangé) · EW-Q-* (les trois issues d'E1) · EW-USAGE.
# Réserve C2 : EW-BWS (--ws transmis à check-method-budget.sh, snapshot et E7 ; budget enregistreur, puis budget réel).
#
# Les assertions portent sur les lignes E1 (stdout) et les diagnostics E1 (stderr), jamais sur le
# verdict global, que les autres contrôles (E2-E7) influencent sur une fixture minimale — sauf EW-NOWS /
# EW-SNAP, dont le verdict (4, jamais 3) EST le contrat.
#
# MUTANTS EW-M-a à EW-M-g : chaque copie mutée du gate vit dans un dossier jetable qui reproduit la
# DISPOSITION du plugin (dev-orchestrator/scripts, planning-core/scripts, conductor/scripts), parce que le
# gate source la politique par ../../planning-core/scripts (E4, repli SILENCIEUX si elle manque) et résout le
# budget par ../../conductor/scripts (exit 4 s'il manque, ce qui ressemblerait à EW-SNAP). EW-LAYOUT joue le
# témoin non muté dans cette disposition AVANT tout mutant : EW-E4 et EW-GEN doivent y être verts.
#
# HOME et CLAUDE_PLUGIN_ROOT sont SCRUBBÉS pour chaque invocation (run_gate), comme dans la suite du
# lab plat : sans ce scrub la cascade des scripts frères résoudrait vers l'installation réelle.
#
# Mode de la suite. `full` (défaut) : tout, mutants compris. `matrice` : sous-processus d'un mutant, qui rejoue
# les cas contre GATE_SCRIPT (copie mutée) et consigne les cas rouges dans EW_KO_FILE ; ni mutants ni LAYOUT.
#
# Exit 0 si tout passe, 1 sinon, 2 si la fixture ou la disposition du mutant est cassée.

set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$(cd "$HERE/.." && pwd)/check-mission-exit.sh"
SUITE="$HERE/$(basename "$0")"
PLUGIN="$(cd "$HERE/../../.." && pwd)"
DL_REAL="$PLUGIN/conductor/scripts/driver-lock.sh"
DAG_REAL="$PLUGIN/conductor/scripts/dag.sh"
POLICY_REAL="$PLUGIN/planning-core/scripts/workstream-policy.sh"
BUDGET_REAL="$PLUGIN/conductor/scripts/check-method-budget.sh"
DIVERGENCE_REAL="$PLUGIN/conductor/scripts/check-divergence.sh"
EW_MODE="${EW_MODE:-full}"
EW_KO_FILE="${EW_KO_FILE:-}"

# Cas dont le verdict DOIT basculer sous chaque mutant (mesurés puis relus un par un : le cas nommé par le
# plan en fait partie). Un cas = le libellé sans suffixe de sous-assertion (EW-TRACE-1.1 → EW-TRACE-1).
# EW-NOWS-2 (verdict global 4) ne bascule pas sous EW-M-b : E4, E5 et E6 sont indéterminés faute d'arguments,
# le 4 global tient sans E1 — c'est EW-NOWS-1 et EW-Q-INDET-1 qui portent la preuve d'E1.
MUT_A="EW-CHILD-1 EW-Q-INDET-2 EW-Q-INDET-3 EW-Q-MANQUE-1 EW-TRACE-1 EW-TRACE-3"
MUT_B="EW-NOWS-1 EW-Q-INDET-1"
MUT_C="EW-GEN-2 EW-GEN-3 EW-GEN-5"
MUT_D="EW-E4-1 EW-E4-2"
MUT_E="EW-SNAP-1 EW-SNAP-2 EW-SNAP-4"
MUT_F="EW-BWS-1"
MUT_G="EW-BWS-2 EW-BWS-3"

# DÉSARMEMENT en tête (P57-D-22) : un VF_DRIVER_LOCK hérité forcerait le mode « verrou unique » ;
# les autres variables déplaceraient la cible. GIT_* : une suite jouée depuis un hook git hériterait
# du dépôt du hook, pas de la fixture.
unset VF_DRIVER_LOCK VF_DRIVER_CHILDREN VF_DRIVER_TTL VF_DRIVER_SESSION_MAX VF_DRIVER_TEST_DIE_AFTER_MUTEX \
      GSD_WORKSTREAM VF_WORKSTREAM CLAUDE_CODE_SESSION_ID GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE

PASS=0; FAIL=0
ok() { echo "  ✓ $1"; PASS=$((PASS+1)); }
ko() {
  echo "  ✗ $1 — $2"; FAIL=$((FAIL+1))
  if [ -n "$EW_KO_FILE" ]; then
    local id="${1%% *}"; printf '%s\n' "${id%.[0-9]*}" >> "$EW_KO_FILE"
  fi
}

TMP="$(mktemp -d)"
TMP="$(cd "$TMP" && pwd -P)"   # macOS : /var → /private/var, comparé canonicalisé
trap 'rm -rf "$TMP"' EXIT

EMPTY_HOME="$TMP/empty-home"
mkdir -p "$EMPTY_HOME"

# Assertions : contient / ne contient pas / égalité d'entiers.
has()    { if [[ "$2" == *"$3"* ]]; then ok "$1"; else ko "$1" "attendu « $3 », obtenu « $2 »"; fi; }
hasnt()  { if [[ "$2" != *"$3"* ]]; then ok "$1"; else ko "$1" "interdit « $3 », obtenu « $2 »"; fi; }
eq_rc()  { if [ "$2" -eq "$3" ]; then ok "$1"; else ko "$1" "exit $2 ≠ $3"; fi; }
eq_str() { if [ "$2" = "$3" ]; then ok "$1"; else ko "$1" "attendu « $3 », obtenu « $2 »"; fi; }

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
git_init_commit() { # <dir>
  git -C "$1" init -q -b main >/dev/null 2>&1 || git -C "$1" init -q >/dev/null 2>&1
  git -C "$1" add -A >/dev/null 2>&1
  git -C "$1" -c user.email=t@t -c user.name=t -c commit.gpgsign=false commit -q -m init >/dev/null 2>&1
}
mk_lab() { # <nom> — imprime le chemin du lab partitionné
  local d="$TMP/$1"
  mkdir -p "$d/.planning/workstreams/alpha" "$d/.planning/workstreams/omega"
  printf '# projet\n' > "$d/.planning/PROJECT.md"
  printf -- '---\nstatus: active\n---\n' > "$d/.planning/workstreams/alpha/STATE.md"
  printf -- '---\nstatus: active\n---\n' > "$d/.planning/workstreams/omega/STATE.md"
  git_init_commit "$d"
  preflight "$d"
  install_scripts "$d"
  printf '%s' "$d"
}
mk_flat() { # <nom> — imprime le chemin du lab PLAT
  local d="$TMP/$1"
  mkdir -p "$d/.planning"
  printf '# projet\n' > "$d/.planning/PROJECT.md"
  printf -- '---\nstatus: active\n---\n' > "$d/.planning/STATE.md"
  git_init_commit "$d"
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
  G_OUT="$(run_gate "$@" 2>"$ef" </dev/null)"; G_RC=$?
  G_ERR="$(cat "$ef")"
}
e1_lines() { printf '%s\n' "$G_OUT" | { grep -F '[E1]' || true; }; }
e1_state() { # sain | manque | indet — lu sur les lignes E1 de stdout (manque) puis de stderr (indéterminé)
  if [ -n "$(e1_lines)" ]; then printf manque
  elif [[ "$G_ERR" == *"[E1]"* ]]; then printf indet
  else printf sain; fi
}
snap_path() { printf '%s/vf-mission-budget.snap' "$(fixture_common_dir "$1")"; }

# --------------------------------------------------------------------------------------------------
case_trace() {
  echo "=== EW-TRACE — E1 lit le verrou du compartiment désigné, de bout en bout, sur clone jetable ==="
  local LAB GC rc SEEN LABF
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
  # La ligne de la lecture du compartiment SEULE : la lecture du verrou de dépôt, qui suit, vide aussi la variable.
  SEEN="$(grep -F 'status --ws=alpha' "$LABF/.claude/scripts/seen.txt" 2>/dev/null)"
  has "EW-TRACE-3.1 — lab partitionné : VF_DRIVER_LOCK reçu VIDE malgré un export hérité" "$SEEN" "val=[]"
  hasnt "EW-TRACE-3.2 — le chemin hérité n'atteint pas le driver-lock.sh frère" "$SEEN" "hérité"
  has "EW-TRACE-3.3 — la lecture est status --ws=alpha" "$SEEN" "status --ws=alpha"
}

case_nows() {
  echo "=== EW-NOWS — lab partitionné sans --ws : INDÉTERMINÉ, jamais un vert ==="
  local LAB
  LAB="$(mk_lab nows)"
  g --root "$LAB"
  has "EW-NOWS-1 — stderr nomme --ws <sujet> requis" "$G_ERR" "--ws <sujet> requis"
  eq_rc "EW-NOWS-2 — verdict global INDÉTERMINÉ (4), jamais SAIN (3) ni un manque (0)" "$G_RC" 4
  eq_rc "EW-NOWS-3 — aucune ligne E1 de manque sur stdout" "$(e1_lines | wc -c | tr -d ' ')" 0
}

case_child() {
  echo "=== EW-CHILD — enfant consigné running sous le compartiment, verrou relâché ==="
  local LAB rc
  LAB="$(mk_lab child)"
  dl "$LAB" acquire --ws=alpha --owner=m1 --step=s >/dev/null
  dl "$LAB" register --ws=alpha --agent=a1 --role=vf-coder --node=n1 --depth=2 --owner=m1 >/dev/null; rc=$?
  eq_rc "EW-CHILD-0 — register --ws=alpha exit 0" "$rc" 0
  dl "$LAB" release --ws=alpha --owner=m1 >/dev/null
  g --root "$LAB" --ws alpha
  has "EW-CHILD-1 — manque E1 : 1 agent consigné encore running, mission terminée pas inerte" "$(e1_lines)" "[E1] verrou relâché mais 1 agent(s) consigné(s) encore running"
}

case_gen() {
  echo "=== EW-GEN — l'identité d'E7 est la génération du verrou du compartiment désigné ==="
  local LAB GEN SNAP rc LABQ
  LAB="$(mk_lab gen)"
  SNAP="$(snap_path "$LAB")"; rm -f "$SNAP"
  dl "$LAB" acquire --ws=alpha --owner=m1 --step=s >/dev/null
  GEN="$(dl "$LAB" status --ws=alpha | jq -r '.generation // empty')"
  [ -n "$GEN" ] || ko "EW-GEN-0 — génération lue sur status --ws=alpha" "vide (fixture cassée)"
  g --root "$LAB" --ws alpha --budget-snapshot
  eq_rc "EW-GEN-1 — --budget-snapshot --ws alpha exit 0" "$G_RC" 0
  has "EW-GEN-2 — le snapshot porte #gen= égal à la génération rendue par status --ws=alpha" "$(sed -n 's/^#gen=//p' "$SNAP" 2>/dev/null)" "$GEN"
  eq_str "EW-GEN-3 — #gen n'est ni - ni ? (verrou du compartiment tenu)" "$([ "$(sed -n 's/^#gen=//p' "$SNAP" 2>/dev/null)" = "$GEN" ] && echo egal)" "egal"

  dl "$LAB" release --ws=alpha --owner=m1 >/dev/null
  g --root "$LAB" --ws alpha --budget-snapshot
  eq_str "EW-GEN-4 — verrou relâché : #gen=-" "$(sed -n 's/^#gen=//p' "$SNAP" 2>/dev/null)" "-"

  # Lecture impossible : driver-lock.sh frère en échec → « ? », jamais « - ».
  LABQ="$(mk_lab genq)"
  printf '#!/usr/bin/env bash\nexit 1\n' > "$LABQ/.claude/scripts/driver-lock.sh"; chmod +x "$LABQ/.claude/scripts/driver-lock.sh"
  SNAP="$(snap_path "$LABQ")"; rm -f "$SNAP"
  g --root "$LABQ" --ws alpha --budget-snapshot; rc=$G_RC
  eq_str "EW-GEN-5 — lecture impossible : #gen=? (jamais -)" "$(sed -n 's/^#gen=//p' "$SNAP" 2>/dev/null)" "?"
}

case_snap() {
  echo "=== EW-SNAP — --budget-snapshot sans --ws en lab partitionné : exit 4, motif nommé, rien d'écrit ==="
  local LAB SNAP
  LAB="$(mk_lab snap)"
  SNAP="$(snap_path "$LAB")"; rm -f "$SNAP"
  g --root "$LAB" --budget-snapshot
  eq_rc "EW-SNAP-1 — exit 4" "$G_RC" 4
  has "EW-SNAP-2 — stderr nomme --ws <sujet> requis (le motif, pas seulement le code)" "$G_ERR" "--ws <sujet> requis"
  hasnt "EW-SNAP-3 — ce n'est pas l'absence du script de budget" "$G_ERR" "introuvable"
  if [ -e "$SNAP" ]; then ko "EW-SNAP-4 — aucun snapshot écrit" "fichier présent : $SNAP"; else ok "EW-SNAP-4 — aucun snapshot écrit"; fi
}

case_budgetws() {
  echo "=== EW-BWS — --ws est transmis au script de budget, dans --budget-snapshot ET dans E7 (réserve C2 de la Phase 57) ==="
  local LAB M GATE ARGS
  LAB="$(mk_lab bws)"
  # Disposition miroir avec un script de budget ENREGISTREUR : il consigne ses arguments et rend 0 sans rien dire.
  M="$TMP/layout-bws-$$-$RANDOM"
  mkdir -p "$M/dev-orchestrator/scripts" "$M/planning-core/scripts" "$M/conductor/scripts"
  cp "${GATE_SCRIPT:-$SCRIPT}" "$M/dev-orchestrator/scripts/check-mission-exit.sh"
  cp "$POLICY_REAL" "$M/planning-core/scripts/workstream-policy.sh"
  cp "$DIVERGENCE_REAL" "$M/conductor/scripts/"
  printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$*" >> "$(dirname "$0")/budget-args.txt"\nexit 0\n' > "$M/conductor/scripts/check-method-budget.sh"
  GATE="$M/dev-orchestrator/scripts/check-mission-exit.sh"
  ARGS="$M/conductor/scripts/budget-args.txt"
  dl "$LAB" acquire --ws=alpha --owner=m1 --step=s >/dev/null
  # Sans GSD_WORKSTREAM ni VF_WORKSTREAM (désarmés en tête de suite) : seul --ws peut désigner le compartiment.
  GATE_SCRIPT="$GATE" g --root "$LAB" --ws alpha --budget-snapshot
  eq_rc "EW-BWS-0 — --budget-snapshot --ws alpha exit 0" "$G_RC" 0
  has "EW-BWS-1 — l'appel du snapshot transmet --ws alpha au budget" "$(grep -F -e '--dry-run' "$ARGS" 2>/dev/null)" "--ws alpha"
  : > "$ARGS"
  GATE_SCRIPT="$GATE" g --root "$LAB" --ws alpha
  has "EW-BWS-2 — l'appel d'E7 transmet --ws alpha au budget" "$(grep -F -e '--strict' "$ARGS" 2>/dev/null)" "--ws alpha"
  # Budget RÉEL : sans GSD_WORKSTREAM, E7 ne rend plus « ARCHIVAGE NON TENTÉ ».
  g --root "$LAB" --ws alpha --budget-snapshot
  g --root "$LAB" --ws alpha
  hasnt "EW-BWS-3 — budget réel : E7 n'est pas « ARCHIVAGE NON TENTÉ » sans GSD_WORKSTREAM" "$G_OUT$G_ERR" "ARCHIVAGE NON TENTÉ"
  # Sans --ws (lab plat), aucun --ws n'est ajouté.
  local FLAT
  FLAT="$(mk_flat bwsflat)"
  : > "$ARGS"
  GATE_SCRIPT="$GATE" g --root "$FLAT" --budget-snapshot
  hasnt "EW-BWS-4 — lab plat sans --ws : le budget ne reçoit aucun --ws" "$(cat "$ARGS" 2>/dev/null)" "--ws"
}

case_e4() {
  echo "=== EW-E4 — --ws surcharge GSD_WORKSTREAM pour la résolution d'E4 ==="
  local LAB
  LAB="$(mk_lab e4)"
  GSD_WORKSTREAM=omega g --root "$LAB" --ws alpha --step 57
  has "EW-E4-1 — E4 juge alpha (sa feuille de route absente est nommée)" "$G_ERR" "workstreams/alpha/ROADMAP.md"
  hasnt "EW-E4-2 — E4 ne juge pas omega malgré l'export" "$G_ERR" "omega"
}

case_depot() {
  echo "=== EW-DEPOT — un verrou de dépôt tenu est dit sur stderr, jamais un manque d'E1 ==="
  local LAB rc
  LAB="$(mk_lab depot)"
  dl "$LAB" acquire --depot --owner=autre --step=s >/dev/null; rc=$?
  eq_rc "EW-DEPOT-0 — acquire --depot exit 0" "$rc" 0
  g --root "$LAB" --ws alpha
  has "EW-DEPOT-1 — stderr dit le verrou de dépôt tenu" "$G_ERR" "verrou de dépôt tenu"
  has "EW-DEPOT-2 — avec son owner" "$G_ERR" "owner=autre"
  eq_rc "EW-DEPOT-3 — aucune ligne E1 de manque sur stdout" "$(e1_lines | wc -c | tr -d ' ')" 0
}

case_flat() {
  echo "=== EW-FLAT — lab plat : --ws accepté et sans effet ==="
  local LAB A B rc
  LAB="$(mk_flat flat)"
  ( cd "$LAB" && CLAUDE_CODE_SESSION_ID=sess-A "$LAB/.claude/scripts/driver-lock.sh" acquire --owner=m1 --step=s >/dev/null ); rc=$?
  eq_rc "EW-FLAT-0 — acquire (lab plat) exit 0" "$rc" 0
  g --root "$LAB"; A="$(e1_lines)"
  g --root "$LAB" --ws alpha; B="$(e1_lines)"
  has "EW-FLAT-1 — le verrou du lab plat est vu sans --ws" "$A" "owner=m1"
  eq_str "EW-FLAT-2 — lignes E1 identiques avec et sans --ws" "$B" "$A"
}

case_q() {
  echo "=== EW-Q — les trois issues d'E1 partitionné : sain, manque, indéterminé ==="
  local LAB LABL LABO
  LAB="$(mk_lab q)"
  g --root "$LAB" --ws alpha
  eq_str "EW-Q-SAIN-1 — aucun verrou : E1 sain (ni stdout ni stderr)" "$(e1_state)" "sain"
  dl "$LAB" acquire --ws=alpha --owner=m1 --step=s >/dev/null
  g --root "$LAB" --ws alpha
  eq_str "EW-Q-MANQUE-1 — verrou du compartiment tenu : manque (stdout)" "$(e1_state)" "manque"
  dl "$LAB" release --ws=alpha --owner=m1 >/dev/null
  # Sans --ws : indéterminé.
  g --root "$LAB"
  eq_str "EW-Q-INDET-1 — sans --ws : indéterminé (stderr)" "$(e1_state)" "indet"
  # Désignation invalide : refus de driver-lock.sh, jamais sain.
  g --root "$LAB" --ws '../x'
  eq_str "EW-Q-INDET-2 — sujet invalide : indéterminé" "$(e1_state)" "indet"
  # Dossier des compartiments en lien symbolique : status --ws refuse, indéterminé.
  LABL="$(mk_lab qlien)"
  mv "$LABL/.planning/workstreams" "$LABL/.planning/ws-reel"
  ln -s ws-reel "$LABL/.planning/workstreams"
  g --root "$LABL" --ws alpha
  eq_str "EW-Q-INDET-3 — workstreams en lien : status --ws refuse, indéterminé" "$(e1_state)" "indet"
  # driver-lock.sh d'avant la phase : --ws inconnu, rc 1 → indéterminé (T-57-23).
  LABO="$(mk_lab qold)"
  printf '#!/usr/bin/env bash\necho "Unknown arg: $*" >&2\nexit 1\n' > "$LABO/.claude/scripts/driver-lock.sh"; chmod +x "$LABO/.claude/scripts/driver-lock.sh"
  g --root "$LABO" --ws alpha
  eq_str "EW-Q-INDET-4 — driver-lock.sh d'avant la phase : indéterminé, jamais sain" "$(e1_state)" "indet"
}

case_src() {
  echo "=== EW-SRC — dépôt SOURCE du plugin : le module voisin prime sur \$HOME/.claude/scripts (réserve C1 de la Phase 57) ==="
  local SRC OLDH GATE DL rc GEN SNAP OUT ERR LOG ABS LAB NB INST LOGH LOGN
  # Disposition du dépôt source : <racine>/plugin/{dev-orchestrator,planning-core,conductor}/scripts, racine partitionnée.
  SRC="$TMP/src-$$-$RANDOM"
  mkdir -p "$SRC/plugin/dev-orchestrator/scripts" "$SRC/plugin/planning-core/scripts" "$SRC/plugin/conductor/scripts" \
           "$SRC/.planning/workstreams/alpha" "$SRC/.planning/workstreams/omega"
  cp "${GATE_SCRIPT:-$SCRIPT}" "$SRC/plugin/dev-orchestrator/scripts/check-mission-exit.sh"
  cp "$POLICY_REAL" "$SRC/plugin/planning-core/scripts/workstream-policy.sh"
  cp "$DAG_REAL" "$DL_REAL" "$BUDGET_REAL" "$DIVERGENCE_REAL" "$SRC/plugin/conductor/scripts/"
  printf '# projet\n' > "$SRC/.planning/PROJECT.md"
  printf -- '---\nstatus: active\n---\n' > "$SRC/.planning/workstreams/alpha/STATE.md"
  printf -- '---\nstatus: active\n---\n' > "$SRC/.planning/workstreams/omega/STATE.md"
  git_init_commit "$SRC"; preflight "$SRC"
  GATE="$SRC/plugin/dev-orchestrator/scripts/check-mission-exit.sh"
  DL="$SRC/plugin/conductor/scripts/driver-lock.sh"
  # $HOME de l'utilisateur : scripts d'AVANT la phase 57 (dag.sh présent, driver-lock.sh sans --ws : rc 1).
  OLDH="$TMP/oldhome-$$-$RANDOM"; mkdir -p "$OLDH/.claude/scripts"
  cp "$DAG_REAL" "$OLDH/.claude/scripts/"
  printf '#!/usr/bin/env bash\necho "Unknown arg: $*" >&2\nexit 1\n' > "$OLDH/.claude/scripts/driver-lock.sh"; chmod +x "$OLDH/.claude/scripts/driver-lock.sh"
  ( cd "$SRC" && CLAUDE_CODE_SESSION_ID=sess-A bash "$DL" acquire --ws=alpha --owner=m1 --step=s >/dev/null ); rc=$?
  eq_rc "EW-SRC-0 — acquire --ws=alpha par le driver du module voisin exit 0" "$rc" 0
  GEN="$( cd "$SRC" && bash "$DL" status --ws=alpha | jq -r '.generation // empty' )"
  [ -n "$GEN" ] || ko "EW-SRC-0b — génération lue sur le driver voisin" "vide (fixture cassée)"
  OUT="$( HOME="$OLDH"; export HOME; unset CLAUDE_PLUGIN_ROOT 2>/dev/null; bash "$GATE" --root "$SRC" --ws alpha 2>"$TMP/src.err" </dev/null )"
  ERR="$(cat "$TMP/src.err")"
  has "EW-SRC-1 — E1 jugé par le driver voisin : verrou tenu vu (owner=m1), pas un indéterminé" "$(printf '%s\n' "$OUT" | { grep -F '[E1]' || true; })" "owner=m1"
  hasnt "EW-SRC-2 — E1 n'est pas indéterminé faute d'un driver-lock.sh d'avant la phase" "$ERR" "[E1]"
  SNAP="$(snap_path "$SRC")"; rm -f "$SNAP"
  ( HOME="$OLDH"; export HOME; unset CLAUDE_PLUGIN_ROOT 2>/dev/null; bash "$GATE" --root "$SRC" --ws alpha --budget-snapshot >/dev/null 2>&1 </dev/null )
  eq_str "EW-SRC-3 — l'identité d'E7 est la génération du verrou rendue par le driver voisin (pas ?)" "$(sed -n 's/^#gen=//p' "$SNAP" 2>/dev/null)" "$GEN"

  # Témoins : l'ordre de résolution ne change pas hors du dépôt source. Deux faux driver-lock.sh enregistreurs.
  # (a) Lab INSTALLÉ : racine sans plugin/, module voisin du gate présent, $HOME porte un driver -> $HOME retenu comme avant.
  LAB="$(mk_lab srcwit)"; rm -f "$LAB/.claude/scripts/driver-lock.sh" "$LAB/.claude/scripts/dag.sh"
  INST="$TMP/instwit-$$-$RANDOM"; mkdir -p "$INST/dev-orchestrator/scripts" "$INST/planning-core/scripts" "$INST/conductor/scripts"
  cp "${GATE_SCRIPT:-$SCRIPT}" "$INST/dev-orchestrator/scripts/check-mission-exit.sh"
  cp "$POLICY_REAL" "$INST/planning-core/scripts/workstream-policy.sh"
  cp "$DAG_REAL" "$BUDGET_REAL" "$DIVERGENCE_REAL" "$INST/conductor/scripts/"
  LOGH="$TMP/log-home-$$"; LOGN="$TMP/log-neighbor-$$"; : > "$LOGH"; : > "$LOGN"
  printf '#!/usr/bin/env bash\necho "home $*" >> "%s"\necho %s\n' "$LOGH" "'{\"present\": false, \"children_running\": 0}'" > "$OLDH/.claude/scripts/driver-lock.sh"
  printf '#!/usr/bin/env bash\necho "neighbor $*" >> "%s"\necho %s\n' "$LOGN" "'{\"present\": false, \"children_running\": 0}'" > "$INST/conductor/scripts/driver-lock.sh"
  chmod +x "$OLDH/.claude/scripts/driver-lock.sh" "$INST/conductor/scripts/driver-lock.sh"
  ( HOME="$OLDH"; export HOME; unset CLAUDE_PLUGIN_ROOT 2>/dev/null; bash "$INST/dev-orchestrator/scripts/check-mission-exit.sh" --root "$LAB" --ws alpha >/dev/null 2>&1 </dev/null )
  has "EW-SRC-W1 — lab installé : le driver de \$HOME est retenu (ordre inchangé)" "$(cat "$LOGH")" "home status --ws=alpha"
  eq_str "EW-SRC-W2 — lab installé : le module voisin n'est pas consulté" "$(cat "$LOGN")" ""
  # (b) Racine à la forme du dépôt source, mais le module voisin DU GATE est ailleurs : $HOME reste devant.
  mkdir -p "$LAB/plugin/conductor/scripts"; cp "$DAG_REAL" "$LAB/plugin/conductor/scripts/"
  printf '#!/usr/bin/env bash\necho "neighbor $*" >> "%s"\necho %s\n' "$LOGN" "'{\"present\": false, \"children_running\": 0}'" > "$LAB/plugin/conductor/scripts/driver-lock.sh"
  chmod +x "$LAB/plugin/conductor/scripts/driver-lock.sh"; : > "$LOGH"; : > "$LOGN"
  ( HOME="$OLDH"; export HOME; unset CLAUDE_PLUGIN_ROOT 2>/dev/null; bash "$INST/dev-orchestrator/scripts/check-mission-exit.sh" --root "$LAB" --ws alpha >/dev/null 2>&1 </dev/null )
  has "EW-SRC-W3 — racine plugin/ sans que le gate en soit le voisin : \$HOME retenu" "$(cat "$LOGH")" "home status --ws=alpha"
  eq_str "EW-SRC-W4 — le plugin/ de la racine n'est pas consulté" "$(cat "$LOGN")" ""
}

case_usage() {
  echo "=== EW-USAGE — --ws sans valeur est une erreur d'usage ==="
  local rc
  ( HOME="$EMPTY_HOME"; unset CLAUDE_PLUGIN_ROOT 2>/dev/null; bash "${GATE_SCRIPT:-$SCRIPT}" --ws >/dev/null 2>&1 </dev/null ); rc=$?
  eq_rc "EW-USAGE-1 — --ws sans valeur : exit 64" "$rc" 64
}

run_cases() {
  case_trace; case_nows; case_child; case_gen; case_snap; case_e4; case_budgetws; case_depot; case_flat; case_q; case_src; case_usage
}

# ---------------------------------------------------------------------------------------------- matrice
if [ "$EW_MODE" = "matrice" ]; then
  run_cases
  [ "$FAIL" -eq 0 ] || exit 1
  exit 0
fi

run_cases

# --------------------------------------------------------------------------------------------- mutants
# Disposition miroir du plugin pour une copie du gate (mutée ou non) : le gate source la politique et résout le
# budget relativement à lui-même.
MUT_N=0
mk_layout() { # <nom> — imprime la racine de la disposition
  local m="$TMP/layout-$1"
  mkdir -p "$m/dev-orchestrator/scripts" "$m/planning-core/scripts" "$m/conductor/scripts"
  cp "$SCRIPT" "$m/dev-orchestrator/scripts/check-mission-exit.sh"
  cp "$POLICY_REAL" "$m/planning-core/scripts/workstream-policy.sh"
  cp "$BUDGET_REAL" "$DIVERGENCE_REAL" "$m/conductor/scripts/"
  printf '%s' "$m"
}

echo "=== EW-LAYOUT — le témoin non muté, dans la disposition du plugin, rend EW-E4 et EW-GEN verts ==="
WIT="$(mk_layout witness)"
F0=$FAIL
GATE_SCRIPT="$WIT/dev-orchestrator/scripts/check-mission-exit.sh" case_e4
GATE_SCRIPT="$WIT/dev-orchestrator/scripts/check-mission-exit.sh" case_gen
if [ "$FAIL" -ne "$F0" ]; then
  echo "DISPOSITION DU MUTANT INCOMPLÈTE — le témoin non muté rend EW-E4 ou EW-GEN rouge dans la disposition miroir : un mutant ne prouverait rien" >&2
  exit 2
fi
ok "EW-LAYOUT — témoin non muté vert sur EW-E4 et EW-GEN dans la disposition du plugin"

py_replace() { # <fichier> <ancre> <remplacement> — l'ancre doit être UNIQUE et le remplacement différent
  python3 -I - "$1" "$2" "$3" <<'PY'
import sys
p, old, new = sys.argv[1], sys.argv[2], sys.argv[3]
s = open(p, encoding="utf-8").read()
if s.count(old) != 1 or old == new:
    sys.exit(3)
open(p, "w", encoding="utf-8").write(s.replace(old, new))
PY
}

MUT_OK=0; MUT_TOTAL=0
mutant() { # <id> <cas nommé par le plan> <cas attendus (ensemble exact, ordre C)> <ancre> <remplacement>
  local id="$1" named="$2" expected="$3" old="$4" new="$5" m gate kof sub got
  MUT_TOTAL=$((MUT_TOTAL+1))
  m="$(mk_layout "$id")"; gate="$m/dev-orchestrator/scripts/check-mission-exit.sh"
  if ! py_replace "$gate" "$old" "$new"; then ko "EW-M-$id" "ancre absente ou non unique, ou remplacement identique"; return; fi
  if ! bash -n "$gate" 2>/dev/null; then ko "EW-M-$id" "le mutant ne passe pas bash -n"; return; fi
  if cmp -s "$gate" "$SCRIPT"; then ko "EW-M-$id" "mutant identique à l'original (non opposable)"; return; fi
  kof="$TMP/ko-$id.txt"; : > "$kof"
  sub="$(EW_MODE=matrice EW_KO_FILE="$kof" GATE_SCRIPT="$gate" bash "$SUITE" 2>&1 </dev/null)" || true
  got="$(LC_ALL=C sort -u "$kof" | tr '\n' ' ' | sed 's/ $//')"
  if [ "$got" = "$expected" ]; then
    ok "EW-M-$id tué — rouge $named : basculé {$got}"
    printf '%s\n' "$sub" | { grep -F "✗ $named" || true; } | head -2 | sed 's/^ *✗ /    rouge /'
    MUT_OK=$((MUT_OK+1))
  else
    ko "EW-M-$id" "ensemble basculé attendu {$expected}, obtenu {$got}"
  fi
}

echo "=== Mutants EW-M-a à EW-M-g (copies dans la disposition du plugin) ==="
mutant a EW-TRACE-1 "$MUT_A" 'VF_DRIVER_LOCK= "$E1_S_DIR/driver-lock.sh" status --ws="$WS"' 'VF_DRIVER_LOCK="$ROOT/.planning/DRIVER.lock" "$E1_S_DIR/driver-lock.sh" status --ws="$WS"'
mutant b EW-NOWS-1 "$MUT_B" 'E1_STATUS="indet"
  E1_MSG="[E1] lab partitionné' 'E1_STATUS="sain"
  E1_MSG="[E1] lab partitionné'
mutant c EW-GEN-2 "$MUT_C" 'if is_partitioned; then # CURGEN' 'if false; then # CURGEN'
mutant d EW-E4-1 "$MUT_D" 'vf_ws_resolve "$E4_PLANNING_DIR" "$WS"' 'vf_ws_resolve "$E4_PLANNING_DIR"'
mutant e EW-SNAP-1 "$MUT_E" 'if is_partitioned && [ -z "$WS" ]; then # SNAPWS' 'if false; then # SNAPWS'
mutant f EW-BWS-1 "$MUT_F" ' --dry-run --ws "$WS" 2>/dev/null)"; SNAP_RC=$?' ' --dry-run 2>/dev/null)"; SNAP_RC=$?'
mutant g EW-BWS-2 "$MUT_G" ' --strict --auto --ws "$WS" 2>/dev/null)"; E7_RC=$?' ' --strict --auto 2>/dev/null)"; E7_RC=$?'

echo
if [ "$MUT_OK" -eq 7 ] && [ "$MUT_TOTAL" -eq 7 ]; then echo "== mutants : 7/7 tués =="; else echo "== mutants : $MUT_OK/7 tués — ÉCHEC =="; fi
echo "== résultat : $PASS ok, $FAIL ko =="
[ "$MUT_OK" -eq 7 ] || exit 1
[ "$FAIL" -eq 0 ] || exit 1
[ "$PASS" -gt 0 ] || exit 1
exit 0
