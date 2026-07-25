#!/usr/bin/env bash
# guard-planning-updated.sh — Hook Stop : bloque (au plus UNE fois par session) si des livrables
# ont changé PENDANT LA SESSION sans aucune mise à jour du .planning/.
#
# v2 (ADR-050 amendée 2026-07-20 — fix faux positifs) : Stop se déclenche à CHAQUE fin de tour
# assistant, et la v1 ne regardait que `git status --porcelain` → deux faux positifs
# systématiques :
#   1. STATE.md mis à jour PUIS COMMITTÉ pendant la session (flow GSD / dev-orchestrator)
#      → invisible du porcelain → bloqué à tort, à chaque tour.
#   2. Dirt PRÉEXISTANT au démarrage (livrable déjà sale avant la session) → attribué à tort
#      à la session.
# La v2 s'appuie sur la BASELINE écrite au SessionStart par planning-session-snapshot.sh
# (epoch + HEAD de départ + porcelain hashé) et raisonne en « changé pendant CETTE session ».
#
# Signaux « planning mis à jour » (LARGES — un seul suffit pour autoriser) :
#   a. fichier .planning/** committé pendant la session (git log --since=début, HEAD_départ..HEAD)
#   b. fichier .planning/** actuellement sale (porcelain)
#   c. fichier .planning/** avec mtime >= début de session (couvre .planning gitignoré, GSD, scripts)
# Attribution « livrable changé » (STRICTE — preuve que c'est CETTE session requise) :
#   a. livrable committé pendant la session (fenêtre --since : les commits tiers rapatriés
#      par un pull/merge ont une committer date antérieure → exclus)
#   b. livrable sale ABSENT de la baseline, ou dont le statut / le contenu (hash blob) a changé
#
# GARDE-FOUS ANTI-PIÈGE (obligatoires) :
#   - anti-boucle `stop_hook_active` + marqueur <session>.blocked → au pire UN blocage par
#     session, même après un nouveau message utilisateur (stop_hook_active retombe à false).
#   - baseline absente / illisible / périmée (>48h) → fail-open (jamais de blocage à l'aveugle).
#   - échappatoire `.session-noop` (racine ou dans un .planning/, one-shot) ;
#     toggle VF_PLANNING_STOP = block | warn | off (override — prime sur le profil).
#   - > 400 entrées porcelain → attribution working-tree abandonnée (fail-open partiel).
# MODE PAR DÉFAUT PROPORTIONNÉ AU PROFIL (audit 2026-07-25, gouvernance proportionnée) :
#   sans VF_PLANNING_STOP, le profil de rigueur du lab décide — lu dans la clé "profile" de
#   <.planning>/config.json (source canonique posée par vf-planning, cf. PROFILES.md) :
#   "leger" → warn (advisory) · "standard"/"complet" → block · config absente ou profil
#   illisible → block (fallback sûr). Plusieurs .planning : un seul profil non-léger → block.
# Fail-open partout : toute condition non réunie ou toute erreur → exit 0 (autorise l'arrêt).
set -uo pipefail

INPUT="$(cat 2>/dev/null || true)"

# --- Anti-boucle : ne jamais re-bloquer une continuation déclenchée par un Stop précédent ---
case "$INPUT" in
  *'"stop_hook_active": true'*|*'"stop_hook_active":true'*) exit 0 ;;
esac

MODE="${VF_PLANNING_STOP:-}"
[ "$MODE" = "off" ] && exit 0

# --- Doit être un repo git (sinon on ne sait pas ce qui a changé → pas de trappe) ---
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
TOP=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
[ -n "$TOP" ] || exit 0
cd "$TOP" 2>/dev/null || exit 0

# --- Un socle .planning/ doit exister (lab amorcé) — recherche bornée (Stop tourne à chaque tour) ---
PLANNING_DIRS=$(find . -maxdepth 4 \( -name .git -o -name node_modules \) -prune -o -type d -name .planning -print 2>/dev/null | head -20)
[ -n "$PLANNING_DIRS" ] || exit 0

# --- Mode effectif : override env > profil du lab > block (fallback sûr) ---
# Sans VF_PLANNING_STOP, la clé "profile" de <.planning>/config.json décide :
# tous les profils lus valent "leger" → warn ; un seul non-léger, ou aucun profil
# lisible → block. Proportionne le garde au profil sans rien changer aux overrides.
if [ -z "$MODE" ]; then
  MODE="block"
  while IFS= read -r d; do
    [ -n "$d" ] || continue
    cfg="$d/config.json"
    [ -f "$cfg" ] || continue
    prof=$(sed -n 's/.*"profile"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$cfg" 2>/dev/null | head -1)
    [ -n "$prof" ] || continue
    if [ "$prof" = "leger" ]; then
      MODE="warn"
    else
      MODE="block"
      break
    fi
  done <<EOF
$PLANNING_DIRS
EOF
fi

# --- Échappatoire : marqueur « rien à noter » (consommé, one-shot) ---
consume_marker() { if [ -f "$1" ]; then rm -f "$1" 2>/dev/null || true; return 0; fi; return 1; }
consume_marker ".session-noop" && exit 0
while IFS= read -r d; do
  [ -n "$d" ] || continue
  consume_marker "$d/.session-noop" && exit 0
done <<EOF
$PLANNING_DIRS
EOF

# --- Baseline de session (écrite au SessionStart par planning-session-snapshot.sh) ---
SID=$(printf '%s' "$INPUT" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1 | tr -cd 'A-Za-z0-9._-')
[ -n "$SID" ] || exit 0
DIR="${TMPDIR:-/tmp}/vibeflow-planning-guard"
KEY=$(printf '%s' "$TOP" | cksum 2>/dev/null | awk '{print $1}')
[ -n "$KEY" ] || exit 0
SNAP="$DIR/${KEY}-${SID}.snap"
BLOCKED="$DIR/${KEY}-${SID}.blocked"
[ -f "$BLOCKED" ] && exit 0          # déjà bloqué une fois cette session → plus jamais
[ -f "$SNAP" ] || exit 0             # pas de baseline → fail-open

EPOCH=$(sed -n '1p' "$SNAP" 2>/dev/null | tr -cd '0-9')
BASE_HEAD=$(sed -n '2p' "$SNAP" 2>/dev/null | tr -cd 'A-Za-z0-9')
[ -n "$EPOCH" ] || exit 0
NOW=$(date +%s 2>/dev/null | tr -cd '0-9')
[ -n "$NOW" ] || exit 0
[ $((NOW - EPOCH)) -le 172800 ] || exit 0   # baseline > 48h → périmée, fail-open

# --- Classification d'un chemin ---
classify() { # $1 path → planning|meta|deliverable
  case "$1" in
    .planning/*|*/.planning/*) echo planning ;;
    .claude/*|*/.claude/*)     echo meta ;;
    .DS_Store|*/.DS_Store)     echo meta ;;
    *)                         echo deliverable ;;
  esac
}

# --- Signal 1 : ce qui a été COMMITTÉ pendant la session (fenêtre committer-date) ---
RANGE=""
if git rev-parse -q --verify HEAD >/dev/null 2>&1; then
  if [ "$BASE_HEAD" = "none" ]; then
    RANGE="HEAD"                                  # repo sans commit au départ
  elif git cat-file -e "$BASE_HEAD" 2>/dev/null; then
    RANGE="$BASE_HEAD..HEAD"
  fi
fi
COMMITTED=""
if [ -n "$RANGE" ]; then
  COMMITTED=$(git log --since="@$EPOCH" --no-merges --name-only --pretty=format: $RANGE 2>/dev/null | grep -v '^$' | sort -u | head -2000 || true)
fi

planning_changed=0
deliverables=""
if [ -n "$COMMITTED" ]; then
  while IFS= read -r p; do
    [ -n "$p" ] || continue
    case "$(classify "$p")" in
      planning)    planning_changed=1 ;;
      deliverable) deliverables="$deliverables
$p" ;;
    esac
  done <<EOF
$COMMITTED
EOF
fi
[ "$planning_changed" -eq 1 ] && exit 0          # planning committé pendant la session → OK

# --- Signal 2 + attribution : porcelain actuel comparé à la baseline ---
# Latence maîtrisée (Stop tourne à chaque tour) : une boucle bash sans spawn, puis UN seul
# awk (join baseline↔porcelain) et UN seul git hash-object batch pour les candidats.
PORCELAIN=$(git status --porcelain 2>/dev/null || true)
PCOUNT=$(printf '%s\n' "$PORCELAIN" | grep -c . || true)
CANDIDATES=""                                    # "XY<TAB>path" des livrables sales
if [ -n "$PORCELAIN" ]; then
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    xy="${line:0:2}"
    p="${line:3}"
    case "$p" in *" -> "*) p="${p##* -> }" ;; esac
    case "$p" in
      .planning/*|*/.planning/*) planning_changed=1 ;;
      .claude/*|*/.claude/*)     : ;;
      .DS_Store|*/.DS_Store)     : ;;
      *) CANDIDATES="$CANDIDATES
$xy	$p" ;;
    esac
  done <<EOF
$PORCELAIN
EOF
fi
[ "$planning_changed" -eq 1 ] && exit 0          # planning sale dans le working tree → OK

if [ -n "$CANDIDATES" ] && [ "$PCOUNT" -le 400 ] 2>/dev/null; then
  # Join en une passe : ATTR = attribué direct (absent de la baseline, ou statut changé) ;
  # CAND = présent à statut identique → le contenu (hash blob) tranchera.
  JOIN=$(printf '%s\n' "$CANDIDATES" | grep -v '^$' | awk -F'\t' '
    FNR==NR { if (NF>=3) { h[$3]=$1; s[$3]=$2 } ; next }
    NF>=2 {
      xy=$1; p=$2
      if (!(p in s))      { print "ATTR\t-\t" p }
      else if (s[p]!=xy)  { print "ATTR\t-\t" p }
      else if (h[p]!="-") { print "CAND\t" h[p] "\t" p }
    }' "$SNAP" - 2>/dev/null || true)
  TAB="$(printf '\t')"
  cand_paths=()
  cand_hashes=()
  if [ -n "$JOIN" ]; then
    while IFS="$TAB" read -r tag hh pp; do
      [ -n "${pp:-}" ] || continue
      case "$tag" in
        ATTR) deliverables="$deliverables
$pp" ;;                                        # né pendant la session ou statut changé
        CAND) if [ -f "$pp" ]; then
                cand_paths[${#cand_paths[@]}]="$pp"
                cand_hashes[${#cand_hashes[@]}]="$hh"
              fi ;;
      esac
    done <<EOF
$JOIN
EOF
  fi
  if [ "${#cand_paths[@]}" -gt 0 ]; then
    HASHES=$(git hash-object -- "${cand_paths[@]}" 2>/dev/null || true)
    i=0
    while IFS= read -r hgot; do
      if [ -n "$hgot" ] && [ "$i" -lt "${#cand_hashes[@]}" ] && [ "$hgot" != "${cand_hashes[$i]}" ]; then
        deliverables="$deliverables
${cand_paths[$i]}"                              # contenu modifié pendant la session
      fi
      i=$((i+1))
    done <<EOF
$HASHES
EOF
  fi
fi

# --- Signal 3 : un fichier .planning touché depuis le début de session (mtime) ---
# Couvre .planning gitignoré, mises à jour par GSD/scripts, etc. Référence temporelle :
# le fichier baseline LUI-MÊME (créé à l'ouverture de session) via find -newer — un seul
# spawn par dossier .planning, pas de stat par fichier (latence : Stop tourne à chaque tour).
# -newer est STRICT (>) : un .planning écrit dans la même seconde que l'ouverture de
# session appartient à l'état antérieur, pas à la session.
while IFS= read -r d; do
  [ -n "$d" ] || continue
  hit=$(find "$d" -type f -newer "$SNAP" -print 2>/dev/null | head -1)
  [ -n "$hit" ] && exit 0                        # planning touché pendant la session → OK
done <<EOF
$PLANNING_DIRS
EOF

# --- Décision : des livrables attribués à CETTE session, et aucun signal planning → dette ---
ATTRIBUTED=$(printf '%s\n' "$deliverables" | grep -v '^$' | sort -u || true)
[ -n "$ATTRIBUTED" ] || exit 0
NB=$(printf '%s\n' "$ATTRIBUTED" | grep -c . || true)
SAMPLE=$(printf '%s\n' "$ATTRIBUTED" | head -3 | tr '\n' ' ' | sed 's/ $//')

REASON="⛔ Planning non mis à jour : $NB livrable(s) ont changé PENDANT cette session ($SAMPLE) sans aucune mise à jour d'un .planning/. Mets à jour le STATE.md du compartiment concerné (état, ce qui vient d'être livré, prochaines étapes — Phase 7 de la boucle de mission), puis termine. Si vraiment rien à noter : crée le marqueur .planning/.session-noop. Ce garde ne bloquera plus cette session. Toggles : VF_PLANNING_STOP=warn|off (profil léger dans .planning/config.json → warn par défaut)."

if [ "$MODE" = "warn" ]; then
  echo "[planning-guard] $REASON"                # advisory : n'arrête pas
  exit 0
fi
mkdir -p "$DIR" 2>/dev/null || true
: > "$BLOCKED" 2>/dev/null || true               # au pire UN blocage par session
echo "$REASON" >&2                               # block : stderr renvoyé à Claude
exit 2
