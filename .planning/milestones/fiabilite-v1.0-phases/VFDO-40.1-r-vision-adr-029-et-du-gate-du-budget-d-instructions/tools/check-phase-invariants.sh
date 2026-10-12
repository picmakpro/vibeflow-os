#!/usr/bin/env bash
# check-phase-invariants.sh — invariants de cloture I1-I4 (+ garde M sur les merges), imputes a
# TOUT commit PROPRE A LA BRANCHE (git rev-list HEAD --not <base derivee>), jamais filtre par
# sujet de commit. Rouge garanti sur un diff vide (I1/I2 exigent au moins un commit propre).
#
# Usage: check-phase-invariants.sh [--main-ref <ref>] [--min-agents N] [--gate <script>] [--root <dir>]
# Defauts : ref de phase-base.sh (auto-resolue), min-agents=3,
#           gate=plugin/conductor/scripts/check-instruction-budget.sh, root=toplevel git.
#
# Chemins gardes :
#   - .planning/instruction-budget-baselines.tsv                     (I1)
#   - plugin/*/agents/*.md et plugin/*/AGENT.md                      (I2)
#   - VERSION, plugin/.claude-plugin/, plugin/.codex-plugin/, .claude-plugin/  (I4)
# M (merges propres) : union des trois familles ci-dessus.
#
# Exit codes: 0 = tous les invariants tiennent ; 1 = au moins un invariant rouge ;
#             2 = pas un depot git, aucune ref main resolue, ou gate introuvable.
set -uo pipefail

# Traitement octet-sur : l'awk de macOS (towc) plante sur les caracteres multi-octets (≤, accents)
# hors locale C ("towc: multibyte conversion failure"), ce qui masquait la cause reelle derriere un
# message d'outillage illisible. Toute lecture de ligne (git diff, awk) se fait donc sous LC_ALL=C.
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PHASE_BASE="$SCRIPT_DIR/phase-base.sh"

MAIN_REF=""
MIN_AGENTS=3
GATE_ARG=""
ROOT=""
OLD_CEILING=250

while [ "$#" -gt 0 ]; do
  case "$1" in
    --main-ref)
      [ "$#" -ge 2 ] || { echo "[check-phase-invariants] --main-ref necessite une valeur" >&2; exit 2; }
      MAIN_REF="$2"; shift 2 ;;
    --min-agents)
      [ "$#" -ge 2 ] || { echo "[check-phase-invariants] --min-agents necessite une valeur" >&2; exit 2; }
      MIN_AGENTS="$2"; shift 2 ;;
    --gate)
      [ "$#" -ge 2 ] || { echo "[check-phase-invariants] --gate necessite une valeur" >&2; exit 2; }
      GATE_ARG="$2"; shift 2 ;;
    --root)
      [ "$#" -ge 2 ] || { echo "[check-phase-invariants] --root necessite une valeur" >&2; exit 2; }
      ROOT="$2"; shift 2 ;;
    --old-ceiling)
      [ "$#" -ge 2 ] || { echo "[check-phase-invariants] --old-ceiling necessite une valeur" >&2; exit 2; }
      OLD_CEILING="$2"; shift 2 ;;
    -h|--help) grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
    *) echo "[check-phase-invariants] argument inconnu : $1" >&2; exit 2 ;;
  esac
done

case "$OLD_CEILING" in
  ''|*[!0-9]*) echo "[check-phase-invariants] --old-ceiling doit etre un entier positif : $OLD_CEILING" >&2; exit 2 ;;
esac

if [ -z "$ROOT" ]; then
  ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
fi
[ -n "$ROOT" ] || { echo "[check-phase-invariants] impossible de determiner le toplevel git" >&2; exit 2; }

git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  echo "[check-phase-invariants] --root n'est pas un depot git : $ROOT" >&2
  exit 2
}

if [ -n "$GATE_ARG" ]; then
  case "$GATE_ARG" in
    /*) GATE="$GATE_ARG" ;;
    *) GATE="$ROOT/$GATE_ARG" ;;
  esac
else
  GATE="$ROOT/plugin/conductor/scripts/check-instruction-budget.sh"
fi
[ -f "$GATE" ] || { echo "[check-phase-invariants] gate introuvable : $GATE" >&2; exit 2; }

TMPD="$(mktemp -d)" || { echo "[check-phase-invariants] mktemp -d a echoue" >&2; exit 2; }
trap 'rm -rf "$TMPD"' EXIT

if [ -n "$MAIN_REF" ]; then
  BASE="$(bash "$PHASE_BASE" --root "$ROOT" --main-ref "$MAIN_REF" 2>"$TMPD/pb.err")"
else
  BASE="$(bash "$PHASE_BASE" --root "$ROOT" 2>"$TMPD/pb.err")"
fi
PB_RC=$?
if [ "$PB_RC" -ne 0 ] || [ -z "$BASE" ]; then
  cat "$TMPD/pb.err" >&2
  echo "[check-phase-invariants] base de branche introuvable (phase-base.sh rc=$PB_RC)" >&2
  exit 2
fi

NONMERGES="$TMPD/nonmerges"
MERGES="$TMPD/merges"
git -C "$ROOT" rev-list --no-merges HEAD --not "$BASE" > "$NONMERGES" 2>"$TMPD/rl1.err"
RL1_RC=$?
git -C "$ROOT" rev-list --merges HEAD --not "$BASE" > "$MERGES" 2>"$TMPD/rl2.err"
RL2_RC=$?
if [ "$RL1_RC" -ne 0 ] || [ "$RL2_RC" -ne 0 ]; then
  cat "$TMPD/rl1.err" >&2
  cat "$TMPD/rl2.err" >&2
  echo "[check-phase-invariants] git rev-list a echoue (non-merges rc=$RL1_RC, merges rc=$RL2_RC) sur la base '$BASE'" >&2
  exit 2
fi

# --- classification des chemins, en awk (jamais grep) --------------------------------------------
IS_GUARDED_AWK='
function is_baseline(p) { return (p == ".planning/instruction-budget-baselines.tsv") }
function is_agent(p) {
  if (p ~ /^plugin\/[^\/]+\/agents\/[^\/]+\.md$/) return 1
  if (p ~ /^plugin\/[^\/]+\/AGENT\.md$/) return 1
  return 0
}
function is_version_source(p) {
  if (p == "VERSION") return 1
  if (p ~ /^plugin\/\.claude-plugin\//) return 1
  if (p ~ /^plugin\/\.codex-plugin\//) return 1
  if (p ~ /^\.claude-plugin\//) return 1
  return 0
}
function is_guarded(p) { return (is_baseline(p) || is_agent(p) || is_version_source(p)) }
'

ECARTS=0
trace() { # <invariant> <ref> <detail> -> trace 3-champs
  printf 'ECART %s | %s | %s\n' "$1" "$2" "$3"
  ECARTS=$((ECARTS + 1))
}

# --- M : merges propres, resolutions manuelles sur chemin garde --------------------------------
M_OK=1
while IFS= read -r mc; do
  [ -n "$mc" ] || continue
  MPATHS="$TMPD/mpaths-$mc"
  git -C "$ROOT" diff-tree --cc --name-only "$mc" > "$MPATHS" 2>"$TMPD/dtcc.err"
  BAD="$TMPD/mbad-$mc"
  awk "$IS_GUARDED_AWK"'{ if (is_guarded($0)) print }' "$MPATHS" > "$BAD"
  while IFS= read -r bp; do
    [ -n "$bp" ] || continue
    M_OK=0
    trace M "$mc" "resolution de merge sur chemin garde : $bp"
  done < "$BAD"
done < "$MERGES"

# --- Fichier des chemins touches par chaque commit propre non-merge, pre-calcule une fois ------
declare -a NM_COMMITS=()
while IFS= read -r c; do
  [ -n "$c" ] || continue
  NM_COMMITS+=("$c")
done < "$NONMERGES"

touched_for() { # <commit> -> ecrit la liste des chemins touches dans $1
  git -C "$ROOT" diff-tree --no-commit-id --name-only -r "$1" 2>/dev/null
}

# --- I1 : baseline touchee au moins une fois, jamais sur ses lignes de donnees -------------------
I1_OK=1
I1_TOUCHED=0
BASELINE_REL=".planning/instruction-budget-baselines.tsv"
for c in "${NM_COMMITS[@]:-}"; do
  [ -n "$c" ] || continue
  TP="$TMPD/touched-$c"
  touched_for "$c" > "$TP"
  MATCH="$(awk "$IS_GUARDED_AWK"'is_baseline($0){print; exit}' "$TP")"
  [ -n "$MATCH" ] || continue
  I1_TOUCHED=1
  OLD="$TMPD/bl-old-$c"
  NEW="$TMPD/bl-new-$c"
  git -C "$ROOT" show "$c^:$BASELINE_REL" > "$OLD" 2>/dev/null
  git -C "$ROOT" show "$c:$BASELINE_REL" > "$NEW" 2>/dev/null
  OLDF="$TMPD/bl-old-clean-$c"
  NEWF="$TMPD/bl-new-clean-$c"
  awk 'NF==0{next} /^#/{next} {print}' "$OLD" > "$OLDF"
  awk 'NF==0{next} /^#/{next} {print}' "$NEW" > "$NEWF"
  if ! cmp -s "$OLDF" "$NEWF"; then
    I1_OK=0
    trace I1 "$c" "lignes de donnees de la baseline modifiees"
  fi
done
if [ "$I1_TOUCHED" -eq 0 ]; then
  I1_OK=0
  trace I1 - "aucun commit propre ne touche la baseline"
fi

# --- I2 : chaque ligne d'agent modifiee est un remplacement de valeur pur (ancien plafond -> 300).
# swap() ne remplace QUE les nombres (frontiere de nombre) dont la VALEUR egale l'ancien plafond
# (parametre --old-ceiling, defaut 250) ; tout autre nombre isole (un compteur "2 approbations",
# le "029" d'un identifiant "ADR-029"...) doit rester identique cote ligne retiree. Une ligne n'est
# un remplacement pur que si au moins une telle substitution a eu lieu (NO_REPLACEMENT sinon).
cat > "$TMPD/pair.awk" <<'AWKEOF'
function swap(s, old,    i,n,ch,start,len,prevch,nxtch,boundary_ok,tok,out) {
  out = ""
  i = 1
  n = length(s)
  REPL = 0
  while (i <= n) {
    ch = substr(s, i, 1)
    if (ch ~ /[0-9]/) {
      start = i
      while (i <= n && substr(s, i, 1) ~ /[0-9]/) i++
      len = i - start
      tok = substr(s, start, len)
      prevch = (start > 1) ? substr(s, start - 1, 1) : ""
      nxtch = (i <= n) ? substr(s, i, 1) : ""
      boundary_ok = 1
      if (prevch ~ /[0-9.]/) boundary_ok = 0
      if (nxtch ~ /[0-9]/) boundary_ok = 0
      if (boundary_ok && (tok + 0) == old) {
        out = out "300"
        REPL++
      } else {
        out = out tok
      }
    } else {
      out = out ch
      i++
    }
  }
  return out
}
BEGIN { nr = 0; na = 0; old_ceiling = (old_ceiling == "" ? 250 : old_ceiling + 0) }
/^diff --git/ { next }
/^--- / { next }
/^\+\+\+ / { next }
/^@@/ { next }
/^-/ { nr++; removed[nr] = swap(substr($0, 2), old_ceiling); repl[nr] = REPL; next }
/^\+/ { na++; added[na] = substr($0, 2); next }
END {
  if (nr != na) { print "COUNT_MISMATCH " nr " " na; exit }
  bad = 0
  for (k = 1; k <= nr; k++) {
    if (removed[k] != added[k]) { print "LINE_MISMATCH " k; bad = 1 }
    else if (repl[k] < 1) { print "NO_REPLACEMENT " k; bad = 1 }
  }
  if (!bad) print "PASS"
}
AWKEOF

I2_OK=1
AGENT_FILES_RAW="$TMPD/agent-files-raw"
: > "$AGENT_FILES_RAW"
for c in "${NM_COMMITS[@]:-}"; do
  [ -n "$c" ] || continue
  TP="$TMPD/touched-$c"
  [ -f "$TP" ] || touched_for "$c" > "$TP"
  AGT="$TMPD/agents-$c"
  awk "$IS_GUARDED_AWK"'is_agent($0){print}' "$TP" > "$AGT"
  while IFS= read -r ap; do
    [ -n "$ap" ] || continue
    DIFFF="$TMPD/diff-$c-$(printf '%s' "$ap" | tr '/' '_')"
    git -C "$ROOT" diff -U0 "$c^" "$c" -- "$ap" > "$DIFFF" 2>/dev/null
    AWKERR="$TMPD/pair-err-$c-$(printf '%s' "$ap" | tr '/' '_')"
    RES="$(awk -v old_ceiling="$OLD_CEILING" -f "$TMPD/pair.awk" "$DIFFF" 2>"$AWKERR")"
    AWK_RC=$?
    if [ "$AWK_RC" -ne 0 ]; then
      cat "$AWKERR" >&2
      echo "[check-phase-invariants] awk a echoue (rc=$AWK_RC) sur $ap (commit $c) : erreur d'outillage, jamais un verdict metier" >&2
      exit 2
    fi
    case "$RES" in
      PASS) printf '%s\n' "$ap" >> "$AGENT_FILES_RAW" ;;
      "")   I2_OK=0; trace I2 "$c" "$ap : aucune ligne de diff exploitable" ;;
      *)    I2_OK=0; trace I2 "$c" "$ap : $RES" ;;
    esac
  done < "$AGT"
done
AGENT_FILES_OK="$TMPD/agent-files-ok"
LC_ALL=C sort -u "$AGENT_FILES_RAW" -o "$AGENT_FILES_OK"
N_AGENT_FILES=$(awk 'END{print NR}' "$AGENT_FILES_OK" 2>/dev/null || echo 0)
[ -n "$N_AGENT_FILES" ] || N_AGENT_FILES=0
if [ "$N_AGENT_FILES" -lt "$MIN_AGENTS" ]; then
  I2_OK=0
  trace I2 - "fichiers distincts verifies=$N_AGENT_FILES < min-agents=$MIN_AGENTS"
fi

# --- I3 : le gate ne doit jamais monter, et les fichiers de l'ensemble I2 collent exactement ----
I3_OK=1
GATE_OUT="$TMPD/gate-out"
bash "$GATE" --path "$ROOT" > "$GATE_OUT" 2>"$TMPD/gate.err" || true
REPORT_LINES="$TMPD/report-lines"
awk -F' \\| ' '/^plugin\// {print}' "$GATE_OUT" > "$REPORT_LINES"
REPORT_N=$(awk 'END{print NR}' "$REPORT_LINES" 2>/dev/null || echo 0)
[ -n "$REPORT_N" ] || REPORT_N=0

BASELINE_FILE="$ROOT/$BASELINE_REL"
BASELINE_N=$(awk 'NF==0{next} /^#/{next} {c++} END{print c+0}' "$BASELINE_FILE" 2>/dev/null || echo 0)
[ -n "$BASELINE_N" ] || BASELINE_N=0

if [ "$BASELINE_N" -eq 0 ] || [ "$REPORT_N" -ne "$BASELINE_N" ]; then
  I3_OK=0
  trace I3 - "lignes de rapport=$REPORT_N != lignes de baseline=$BASELINE_N"
fi

while IFS= read -r line; do
  [ -n "$line" ] || continue
  f="$(printf '%s' "$line" | awk -F' \\| ' '{print $1}')"
  lg="$(printf '%s' "$line" | awk -F' \\| ' '{print $2}')"
  bl="$(printf '%s' "$line" | awk -F' \\| ' '{print $3}')"
  ins="$(printf '%s' "$line" | awk -F' \\| ' '{print $4}')"
  bli="$(printf '%s' "$line" | awk -F' \\| ' '{print $5}')"
  vd="$(printf '%s' "$line" | awk -F' \\| ' '{print $6}')"

  case "$lg$bl$ins$bli" in
    *[!0-9]*) trace I3 "$f" "champs non numeriques ($line)"; I3_OK=0; continue ;;
  esac

  over=0
  [ "$lg" -gt "$bl" ] && over=1
  [ "$ins" -gt "$bli" ] && over=1
  case "$vd" in
    *DEPASSEMENT*) over=1 ;;
  esac
  if [ "$over" -eq 1 ]; then
    I3_OK=0
    trace I3 "$f" "hausse au-dela de la baseline ($line)"
  fi

  IS_TOUCHED="$(awk -v want="$f" '$0==want{print "1"; exit}' "$AGENT_FILES_OK" 2>/dev/null)"
  if [ "$IS_TOUCHED" = "1" ]; then
    if [ "$lg" -ne "$bl" ] || [ "$ins" -ne "$bli" ]; then
      I3_OK=0
      trace I3 "$f" "fichier touche par la branche non aligne exactement sur la baseline ($line)"
    fi
  fi
done < "$REPORT_LINES"

# --- I4 : aucune source de version racine touchee par un commit propre --------------------------
I4_OK=1
for c in "${NM_COMMITS[@]:-}"; do
  [ -n "$c" ] || continue
  TP="$TMPD/touched-$c"
  [ -f "$TP" ] || touched_for "$c" > "$TP"
  VS="$(awk "$IS_GUARDED_AWK"'is_version_source($0){print; exit}' "$TP")"
  if [ -n "$VS" ]; then
    I4_OK=0
    trace I4 "$c" "source de version racine touchee : $VS"
  fi
done

m_label="ok"; [ "$M_OK" -eq 1 ] || m_label="ko"
i1_label="ok"; [ "$I1_OK" -eq 1 ] || i1_label="ko"
i2_label="ok"; [ "$I2_OK" -eq 1 ] || i2_label="ko"
i3_label="ok"; [ "$I3_OK" -eq 1 ] || i3_label="ko"
i4_label="ok"; [ "$I4_OK" -eq 1 ] || i4_label="ko"

echo "INVARIANTS : M=$m_label I1=$i1_label I2=$i2_label (fichiers=$N_AGENT_FILES) I3=$i3_label I4=$i4_label"

if [ "$M_OK" -eq 1 ] && [ "$I1_OK" -eq 1 ] && [ "$I2_OK" -eq 1 ] && [ "$I3_OK" -eq 1 ] && [ "$I4_OK" -eq 1 ]; then
  exit 0
fi
exit 1
