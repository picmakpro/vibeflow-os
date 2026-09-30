#!/usr/bin/env bash
# check-method-budget.sh — Budgets de méthode d'un lab (v2.67.0) : taille du fichier d'état,
# nombre de worktrees actifs, et RANGEMENT (ce qui a été créé et n'a plus de raison d'être : branches
# locales intégrées, stash sans propriétaire, mémoires d'agents hors git ou hors index, branches
# distantes intégrées de leur seul propriétaire). CONSTATE ; seuls --archive et --auto DÉPLACENT (archivage,
# voir plus bas), jamais ne supprime, jamais ne commite.
#
# Pourquoi : la trace d'un lab ne fait que s'accumuler si rien ne la borne. Mesuré sur un lab
# client après deux mois de missions : STATE.md à 195 Ko (1 406 lignes, un « Point du … » ajouté
# en tête à chaque mission, jamais retiré), 15 worktrees ouverts dont 7 déjà intégrés. Un STATE de
# cette taille n'est plus lu en entier par aucun agent, et chaque worktree oublié coûte un
# `pod install`, un Metro ou une question « quelle branche ? ». La doctrine existait déjà
# (planning-core bridge-memory : « STATE.md ne garde que le courant ») ; il lui manquait un seuil
# mesurable et un moment où on le mesure. Moment : la clôture de mission (mission-flow.md
# §Budgets de méthode), et à la demande.
#
# Budgets (surchargeables par l'environnement) :
#   VF_STATE_BUDGET_KB   taille max d'un STATE.md, en Ko (défaut 8)
#   VF_WORKTREE_BUDGET   worktrees actifs max par dépôt, hors arbre principal (défaut 3)
#   VF_BUDGET_PR_LIMIT   nombre de PR mergées lues chez gh (défaut 200) ; l'atteindre = liste possiblement tronquée
#   VF_BACKLOG_OPEN_BUDGET        sujets OUVERTS max d'un BACKLOG.md (défaut 20). Un sujet est un titre `## ` ;
#                                 il est CLOS si le premier mot après le dernier " — " du titre est l'un de
#                                 CLOS, RÉSORBÉ, ADOPTÉ, ADOPTÉE (vocabulaire fermé ; TRANCHÉ n'en fait PAS partie :
#                                 une décision prise n'est pas un sujet livré). Un sujet clos ne compte pas dans le
#                                 budget : il est ARCHIVABLE. 20 sujets = ce qu'un tri humain tient d'un regard ;
#                                 au-delà le fichier n'est plus relu en entier.
#   VF_MEMORY_INDEX_BUDGET_LINES  lignes max d'un MEMORY.md sous .claude/agent-memory/*/ et .claude/memory/
#                                 (défaut 200) : au-delà, l'index n'est plus chargé en entier par le harnais.
#   VF_ROADMAP_BUDGET_KB          taille max d'un ROADMAP.md (racine et compartiments), en Ko (défaut 64).
#   VF_STATE_NOTE_MAX_LINES       lignes max d'un paragraphe de prose du corps d'un STATE.md (défaut 12) ;
#                                 paragraphe = suite de lignes de prose (ni titre, ni liste, ni tableau, ni
#                                 citation, ni bloc de code, ni frontmatter).
#   VF_BACKLOG_ENTRY_MAX_LINES    lignes max d'une entrée de BACKLOG.md, du titre à la dernière ligne non vide (défaut 40).
#   VF_ARCHIVE_PROTECTED_WS       compartiments jamais archivés par l'outil, séparés par des virgules (défaut
#                                 gouvernance : compartiment d'un autre mainteneur).
#   VF_ARCHIVE_DATE               date AAAA-MM-JJ des noms d'archive (défaut : le jour ; surcharge pour les suites).
#
# Usage :
#   check-method-budget.sh [--root <dir>] [--repo <dir>]... [--strict] [--quiet]
#                          [--owner <login>]... [--no-remote]
#                          [--archive <types> | --auto] [--ws <nom>]...
#   --root   racine du lab (défaut .). STATE.md lus : <root>/.planning/STATE.md et celui de
#            chaque compartiment de workstream (énumérés par vf_ws_enumerate).
#   --repo   dépôt git dont compter les worktrees (répétable). Défaut : <root> s'il est un dépôt
#            git, sinon chaque sous-dossier direct de <root> qui en est un (lab multi-dépôts).
#   --strict un dépassement rend 1 (défaut : avertissement seul, rend 0).
#   --quiet  n'imprime que les dépassements et ce qui est rangeable.
#   --owner  login GitHub dont les branches distantes intégrées sont candidates (répétable ; défaut :
#            `gh api user --jq .login`). Une branche dont la PR est d'un autre auteur n'est JAMAIS
#            candidate (arbitrage Samuel, AskUserQuestion session principale, 2026-09-29 : jamais les
#            branches de Willy). Variable VF_BUDGET_GH : binaire gh à appeler (défaut gh).
#            Seules les refs du remote `origin` sont examinées : la ref d'un autre remote (fork) n'est jamais
#            candidate. Sont exclues de tout rangement, locales comme distantes, les branches par défaut ou
#            longue durée : liste UNIQUE dans la fonction is_longlived du script (l'en-tête ne la recopie
#            pas, pour ne pas dériver) ; ne l'est jamais non plus la base d'une PR mergée. Ce qui est
#            MESURÉ avant de conclure, sinon NON VÉRIFIABLE : le dépôt que gh interroge (`gh repo view`) est
#            celui de remote.origin.url ; seule une PR dont la tête vit DANS ce dépôt (isCrossRepository
#            faux) rapproche une branche `origin/…` (une PR de fork homonyme ne compte pas) ; la liste des
#            PR mergées n'est pas tronquée (VF_BUDGET_PR_LIMIT, défaut 200) ; un remote origin existe si
#            aucun remote origin (ni URL, ni ref `origin/…`) alors que des refs distantes
#            existent = branches distantes non examinées, dit.
#   --no-remote  ne consulte pas GitHub (aucun appel gh) : branches distantes non examinées.
#   --archive <types>  ARCHIVE (déplace, ne supprime pas) ce qu'une règle décidable désigne ; types = liste
#            explicite parmi backlog, state, roadmap (séparés par des virgules ; sans liste : rc 64). backlog :
#            les sujets clos, toujours ; state : au-delà du budget, le contenu des seules sections d'HISTORIQUE
#            (titre contenant historique, history, décisions, journal, performance metrics ou point du, sous-sections
#            comprises ; jamais une section d'état ouvert : todos, blocages, différés, tâches rapides). L'archive garde
#            TITRES ET DATES : les sous-sections d'historique et les entrées « Point du … » partent avec leur titre ;
#            le STATE ne garde que les titres de conteneur (Historique, Décisions…), le frontmatter, la ligne ^Phase:,
#            les pointeurs déjà posés et UN SEUL pointeur par archivage ; un second passage ne déplace rien ; roadmap :
#            au-delà du budget, les blocs <details> dont le résumé porte ✅ ou SHIPPED (un jalon non livré reste). La racine `.planning/` est toujours incluse ; un compartiment
#            de workstream n'est archivé que s'il est nommé par --ws (répétable) ; un compartiment protégé
#            (VF_ARCHIVE_PROTECTED_WS) rend 64. Une source modifiée ou non suivie par git : refus, rien écrit,
#            rc 2. Destination `.planning/archives/<type>/<compartiment|racine>-<fichier>-<AAAA-MM-JJ>.md` :
#            les blocs déplacés TELS QUELS, aucune ligne d'en-tête ni séparateur ajouté ; à leur place une ligne
#            `<!-- vf-archive: <archive> -->` ; une ligne de `.planning/archives/INDEX.tsv` (date, type, source,
#            archive, ref = blob d'origine, motif). JAMAIS de commit ni de `git add` : le déplacement se voit au
#            `git status`. L'archive est écrite et relue AVANT toute modification de la source. Verrou exclusif
#            `.planning/.archive.lock` (mkdir atomique, attente VF_ARCHIVE_LOCK_WAIT dixièmes de seconde, défaut 100 ;
#            jamais de reprise automatique d'un verrou : refus qui nomme le pid) ; la source est relue juste avant
#            son remplacement et doit être identique à ce qui a été décidé, sinon refus bruyant, archive et ligne
#            d'INDEX retirées, source intacte : aucune perte silencieuse d'une écriture concurrente.
#            RESTAURER : `git cat-file blob <ref de l'INDEX>` restitue la source d'avant l'archivage.
#   --dry-run  avec --auto seulement : la MÊME décision, rien d'écrit (ni verrou, ni archive, ni INDEX) ; ne rend que
#            les ARCHIVAGE REFUSÉ qu'un --auto rendrait (photographie de début de mission : un refus préexistant
#            n'est pas imputé à qui arrive après). Sans --auto : rc 64.
#   --auto   décision ET exécution, pour le geste de fin (clôture de mission, fin de travail direct) : mêmes règles,
#            types = ceux qui ont de l'archivable ; compartiments = --ws répétés, sinon celui de la session, résolu par
#            vf_ws_resolve (VF_WORKSTREAM, GSD_WORKSTREAM, puis le pointeur .planning/active-workstream). Dépôt
#            partitionné (.planning/workstreams) et aucun compartiment résolu : ARCHIVAGE NON TENTÉ, rien déplacé.
#            Compartiment protégé ou source non commitée : ARCHIVAGE REFUSÉ, rien déplacé, rc inchangé (jamais 2).
#            L'archivage précède les mesures : une exécution rend l'état d'après. En --auto, JAMAIS d'attente sur le
#            verrou (un Stop ne se bloque pas 10 s par fichier) : verrou tenu = refus immédiat qui nomme le pid et dit
#            s'il est vivant ; aucune reprise automatique.
#
# JETONS de constat (CONTRAT lu par guard-fin-de-geste.sh et check-mission-exit.sh E7 ; une ligne chacun) :
#   RANGEABLE, À VALIDER  (rangement, plan 41.3-02 ; un stash se désigne par son SHA, jamais par sa position stash@{N} : elle se décale à chaque nouveau stash) · ARCHIVABLE (sujet clos encore au BACKLOG) · ARCHIVÉ (ce que
#   l'archivage vient de déplacer) · ARCHIVAGE REFUSÉ · ARCHIVAGE NON TENTÉ · DÉPASSÉ / PROSE DÉPASSÉE (budget ou
#   plafond de prose : un constat, pas un geste à faire). Aucune ligne de budget ne porte RANGEABLE.
#
# Sortie standard : une ligne par constat, préfixe [budget]. Pour chaque worktree actif, dit s'il
# est RANGEABLE (sa branche ou sa tête est déjà intégrée dans la branche de référence du dépôt) ou
# ORPHELIN (dossier disparu, `git worktree prune`). Jamais de suppression : ranger est un geste
# du manager ou de l'humain, sans --force, après vérification qu'aucune session ne s'en sert.
#
# Codes : 0 = dans les budgets, ou dépassement sans --strict · 1 = dépassement avec --strict ·
#         2 = non vérifiable avec --strict (compartiments de workstream illisibles, politique
#         introuvable, gh ou jq indisponible ou muet, stash illisible, branche de référence introuvable
#         ou orpheline, git for-each-ref en échec) — jamais un 0 de complaisance sous
#         --strict · 64 = argument invalide. Sous --strict, tout RANGEABLE et tout À VALIDER
#         compte comme un dépassement. --archive : 2 aussi quand une source est refusée (rien écrit pour elle).
set -uo pipefail

ROOT="."
REPOS=()
STRICT=0
QUIET=0
NO_REMOTE=0
OWNERS=""
STATE_KB="${VF_STATE_BUDGET_KB:-8}"
PR_LIMIT="${VF_BUDGET_PR_LIMIT:-200}"
WT_MAX="${VF_WORKTREE_BUDGET:-3}"
BACKLOG_OPEN_MAX="${VF_BACKLOG_OPEN_BUDGET:-20}"
MEMIDX_MAX="${VF_MEMORY_INDEX_BUDGET_LINES:-200}"
ROADMAP_KB="${VF_ROADMAP_BUDGET_KB:-64}"
STATE_NOTE_MAX="${VF_STATE_NOTE_MAX_LINES:-12}"
BACKLOG_ENTRY_MAX="${VF_BACKLOG_ENTRY_MAX_LINES:-40}"
PROTECTED_WS="${VF_ARCHIVE_PROTECTED_WS:-gouvernance}"
ARCHIVE_DATE="${VF_ARCHIVE_DATE:-$(date +%Y-%m-%d)}"
ARCHIVE_TYPES=""
AUTO=0
DRY=0
WS_NAMED=""

usage() { sed -n '/^# Usage :/,/^# Sortie standard/p' "$0" >&2; exit 64; }

while [ "$#" -gt 0 ]; do
  case "$1" in
    --root) [ "$#" -ge 2 ] || usage; ROOT="$2"; shift 2 ;;
    --repo) [ "$#" -ge 2 ] || usage; REPOS+=("$2"); shift 2 ;;
    --strict) STRICT=1; shift ;;
    --quiet) QUIET=1; shift ;;
    --owner) [ "$#" -ge 2 ] || usage; OWNERS="$OWNERS
$2"; shift 2 ;;
    --no-remote) NO_REMOTE=1; shift ;;
    --archive)
      [ "$#" -ge 2 ] || { echo "[budget] --archive exige une liste de types (backlog, state, roadmap)" >&2; exit 64; }
      case "$2" in --*) echo "[budget] --archive exige une liste de types (backlog, state, roadmap)" >&2; exit 64 ;; esac
      ARCHIVE_TYPES="$2"; shift 2 ;;
    --auto) AUTO=1; shift ;;
    --dry-run) DRY=1; shift ;;
    --ws) [ "$#" -ge 2 ] || usage; WS_NAMED="$WS_NAMED
$2"; shift 2 ;;
    -h|--help) usage ;;
    *) echo "[budget] argument inconnu : $1" >&2; usage ;;
  esac
done
case "$STATE_KB" in ''|*[!0-9]*) echo "[budget] VF_STATE_BUDGET_KB invalide : $STATE_KB" >&2; exit 64 ;; esac
case "$WT_MAX" in ''|*[!0-9]*) echo "[budget] VF_WORKTREE_BUDGET invalide : $WT_MAX" >&2; exit 64 ;; esac
case "$PR_LIMIT" in ''|*[!0-9]*|0) echo "[budget] VF_BUDGET_PR_LIMIT invalide : $PR_LIMIT" >&2; exit 64 ;; esac
for _v in BACKLOG_OPEN_MAX MEMIDX_MAX ROADMAP_KB STATE_NOTE_MAX BACKLOG_ENTRY_MAX; do
  eval "_val=\${$_v}"
  case "$_val" in ''|*[!0-9]*|0) echo "[budget] budget invalide ($_v) : $_val" >&2; exit 64 ;; esac
done
case "$ARCHIVE_DATE" in [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;; *) echo "[budget] VF_ARCHIVE_DATE invalide : $ARCHIVE_DATE" >&2; exit 64 ;; esac
if [ "$AUTO" -eq 1 ] && [ -n "$ARCHIVE_TYPES" ]; then echo "[budget] --archive et --auto s'excluent" >&2; exit 64; fi
if [ "$DRY" -eq 1 ] && [ "$AUTO" -eq 0 ]; then echo "[budget] --dry-run exige --auto" >&2; exit 64; fi
if [ -n "${WS_NAMED//[$'\n ']/}" ] && [ "$AUTO" -eq 0 ] && [ -z "$ARCHIVE_TYPES" ]; then echo "[budget] --ws exige --archive ou --auto" >&2; exit 64; fi
if [ -n "$ARCHIVE_TYPES" ]; then
  for _t in $(printf '%s' "$ARCHIVE_TYPES" | tr ',' ' '); do
    case "$_t" in backlog|state|roadmap) ;; *) echo "[budget] type d'archive inconnu : $_t (attendu : backlog, state, roadmap)" >&2; exit 64 ;; esac
  done
  # Un compartiment protégé nommé explicitement : refus net, avant tout geste.
  while IFS= read -r _w; do
    [ -n "$_w" ] || continue
    case ",$PROTECTED_WS," in *",$_w,"*) echo "[budget] compartiment protégé (VF_ARCHIVE_PROTECTED_WS) : $_w" >&2; exit 64 ;; esac
  done <<EOF0
$WS_NAMED
EOF0
fi
[ -d "$ROOT" ] || { echo "[budget] racine introuvable : $ROOT" >&2; exit 64; }
case "$ROOT" in /) ;; *) ROOT="${ROOT%/}" ;; esac
[ -n "$ROOT" ] || ROOT="/"
ROOT_ABS="$(cd "$ROOT" && pwd)"; ROOT_PHYS="$(cd "$ROOT" && pwd -P)"

OVER=0
UNVERIFIABLE=0
say() { [ "$QUIET" -eq 1 ] || echo "[budget] $*"; }
flag() { echo "[budget] $*"; }

# >>> vf-archive-writer
# --- Lecture des fichiers de planning : BACKLOG, STATE, ROADMAP (lecture seule) ---------------------
# Programmes awk (LC_ALL=C : octets, le vocabulaire est en UTF-8). SANS apostrophe : ils vivent dans des chaînes
# entre apostrophes. Fonctions communes à la mesure ET à l'archivage : une seule règle de « clos ».
AWK_COMMON='
function isclosed(t,   n, p, w) {
  n = split(t, p, " — ")
  if (n < 2) return 0
  w = p[n]; sub(/^[ \t]+/, "", w); sub(/[ \t(:,;.].*$/, "", w)
  return (w == "CLOS" || w == "RÉSORBÉ" || w == "ADOPTÉ" || w == "ADOPTÉE")
}
function isfence(l) { return (l ~ /^(```|~~~)/) }
function sanit(t) { gsub(/--/, "-", t); return t }
'
AWK_BACKLOG_MEASURE="$AWK_COMMON"'
function endb() {
  if (!inb) return
  if (cl) nc++; else no++
  if (last > MAX) printf "L\t%d\t%d\t%s\n", start, last, title
  inb = 0; last = 0
}
{ if (isfence($0)) fence = !fence }
!fence && /^## / { endb(); title = substr($0, 4); cl = isclosed(title); start = NR; len = 0; inb = 1 }
inb { len++; if ($0 !~ /^[ \t]*$/) last = len }
END { endb(); printf "C\t%d\t%d\n", no + 0, nc + 0 }
'
AWK_STATE_PROSE='
NR == 1 && /^---[ \t]*$/ { fm = 1; next }
fm == 1 { if ($0 ~ /^---[ \t]*$/) fm = 2; next }
function endrun() { if (run > MAX) printf "%d\t%d\n", start, run; run = 0 }
isfence($0) { fence = !fence; endrun(); next }
fence { next }
{
  prose = ($0 !~ /^[ \t]*$/ && $0 !~ /^#/ && $0 !~ /^[ \t]*[-*+] / && $0 !~ /^[ \t]*[0-9]+[.)] / && $0 !~ /^[ \t]*\|/ && $0 !~ /^[ \t]*>/ && $0 !~ /^<!--/)
  if (prose) { if (run == 0) start = NR; run++ } else endrun()
}
END { endrun() }
'
AWK_STATE_PROSE="$AWK_COMMON$AWK_STATE_PROSE"
# Archivage : chaque programme écrit la source allégée sur la sortie standard, le contenu déplacé dans ARCH
# (verbatim, sans en-tête), le nombre d'unités déplacées dans CNT. Pointeur : ligne « <!-- vf-archive: ... -->».
AWK_BACKLOG_ARCHIVE="$AWK_COMMON"'
function flushb(   i) {
  if (!inb) return
  if (cl) {
    for (i = 1; i <= nb; i++) { if (index(blk[i], "<!-- vf-archive: ") == 1) print blk[i]; else print blk[i] > ARCH }
    n++; print "<!-- vf-archive: " ARCHREL " — ## " sanit(title) " -->"
  } else for (i = 1; i <= nb; i++) print blk[i]
  nb = 0; inb = 0
}
{
  if (isfence($0)) { fence = !fence; if (inb) blk[++nb] = $0; else print; next }
  if (!fence && $0 ~ /^## /) { flushb(); title = substr($0, 4); cl = isclosed(title); inb = 1; blk[++nb] = $0; next }
  if (inb) blk[++nb] = $0; else print
}
END { flushb(); print n + 0 > CNT }
'
AWK_STATE_ARCHIVE="$AWK_COMMON"'
function ishist(h) { return (tolower(h) ~ /historique|history|d..?cisions|decisions|journal|performance metrics|point du/) }
function isentry(h) { return (tolower(h) ~ /point du/) }
function ispointer(l) { return (index(l, "<!-- vf-archive: ") == 1) }
function pr(l) { print l; lastblank = (l ~ /^[ \t]*$/) }
function mv(l) { if (!ptr) { pr("<!-- vf-archive: " ARCHREL " -->"); ptr = 1 } print l > ARCH; n++ }
BEGIN { hist = 0; hlev = 0; lastblank = 1 }
NR == 1 && /^---[ \t]*$/ { fm = 1; pr($0); next }
fm == 1 { pr($0); if ($0 ~ /^---[ \t]*$/) fm = 2; next }
{
  if (isfence($0)) fence = !fence
  else if (!fence && $0 ~ /^#+ /) {
    match($0, /^#+/); lev = RLENGTH
    if (lev == 1) { hist = 0; pr($0); next }
    if (hist && lev > hlev) { mv($0); next }
    hist = ishist($0); hlev = lev
    if (hist && isentry($0)) mv($0); else pr($0)
    next
  }
  if (ispointer($0) || $0 ~ /^Phase:/) { pr($0); next }
  if (!hist) { pr($0); next }
  if ($0 ~ /^[ \t]*$/) { if (lastblank) print > ARCH; else pr($0); next }
  mv($0)
}
END { print n + 0 > CNT }
'
AWK_ROADMAP_ARCHIVE="$AWK_COMMON"'
function chk(l,   m) { if (sum == "" && match(l, /<summary>.*<\/summary>/)) sum = substr(l, RSTART + 9, RLENGTH - 19) }
function shipped(t) { return (t ~ /✅/ || t ~ /SHIPPED/) }
function flushd(   i) {
  if (shipped(sum)) {
    for (i = 1; i <= nb; i++) { if (index(buf[i], "<!-- vf-archive: ") == 1) print buf[i]; else print buf[i] > ARCH }
    n++; print "<!-- vf-archive: " ARCHREL " — " sanit(sum) " -->"
  } else for (i = 1; i <= nb; i++) print buf[i]
  nb = 0; sum = ""
}
{
  if (depth == 0 && isfence($0)) fence = !fence
  if (depth == 0 && !fence && $0 ~ /^<details[ >]/) { depth = 1; nb = 0; sum = ""; buf[++nb] = $0; chk($0); next }
  if (depth > 0) {
    buf[++nb] = $0; chk($0)
    if ($0 ~ /<details[ >]/) depth++
    if ($0 ~ /<\/details>/) depth--
    if (depth == 0) flushd()
    next
  }
  print
}
END { for (i = 1; i <= nb && depth > 0; i++) print buf[i]; print n + 0 > CNT }
'

# Programmes awk ci-dessus (leurs `>` sont des comparaisons ou des écritures vers ARCH/CNT) et fonctions ci-dessous :
# SEUL endroit du script qui ÉCRIT (archive, source allégée, INDEX). La suite (X8) l'exempte du filet statique
# d'écriture, et seulement lui ; X9 vérifie qu'il n'existe qu'une paire de marqueurs. La lecture seule des
# autres modes est prouvée par exécution (RO1-RO5). Verbes git employés ici : rev-parse, ls-files (lecture).
ARCHIVE_REFUSED=0
TMPD=""
ARCHIVE_LOCK=""
archive_unlock() { [ -n "$ARCHIVE_LOCK" ] && rm -rf "$ARCHIVE_LOCK"; ARCHIVE_LOCK=""; return 0; }
trap '[ -n "$TMPD" ] && rm -rf "$TMPD"; archive_unlock' EXIT
archive_lock() { # rend 0 verrou pris, 1 sinon (attente bornee) ; le pid du detenteur est lu dans LOCK_HOLDER
  local d="$ROOT/.planning/.archive.lock" waited=0 max="${VF_ARCHIVE_LOCK_WAIT:-100}"
  case "$max" in ''|*[!0-9]*) max=100 ;; esac
  [ "$AUTO" -eq 0 ] || max=0   # --auto : jamais d attente (un Stop ne se bloque pas 10 s par fichier)
  LOCK_HOLDER=""
  while ! mkdir "$d" 2>/dev/null; do
    LOCK_HOLDER=$(cat "$d/pid" 2>/dev/null)
    waited=$((waited + 1)); [ "$waited" -le "$max" ] || return 1
    sleep 0.1
  done
  ARCHIVE_LOCK="$d"; printf '%s\n' "$$" > "$d/pid"
  return 0
}
src_unclean() { # <chemin relatif a ROOT> : imprime la raison et rend 0 si la source N est PAS archivable
  local rel="$1" h i
  git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1 || { echo "$ROOT n'est pas un dépôt git"; return 0; }
  git -C "$ROOT" ls-files --error-unmatch -- "$rel" >/dev/null 2>&1 || { echo "non suivie par git"; return 0; }
  h=$(git -C "$ROOT" rev-parse -q --verify "HEAD:./$rel" 2>/dev/null) || { echo "absente de HEAD"; return 0; }
  i=$(git -C "$ROOT" rev-parse -q --verify ":./$rel" 2>/dev/null) || { echo "absente de l'index"; return 0; }
  [ "$h" = "$i" ] || { echo "modifiée dans l'index, non commitée"; return 0; }
  [ -z "$(git -C "$ROOT" ls-files -m -- "$rel" 2>/dev/null)" ] || { echo "modifiée dans l'arbre de travail, non commitée"; return 0; }
  return 1
}
archive_refuse() { # <message> : un refus ne perd rien ; explicite = rc 2 en fin, auto = constat seul
  ARCHIVE_REFUSED=1
  flag "ARCHIVAGE REFUSÉ : $1"
}
archive_one() { # <type> <label> <fichier absolu> <nom du fichier> : sous verrou exclusif, un archivage à la fois
  local src="$3" rel="${3#"$ROOT"/}" why live
  [ -f "$src" ] && [ -r "$src" ] || return 0
  if [ "$DRY" -eq 1 ]; then archive_one_locked "$@"; return 0; fi   # photographie : ni verrou, ni écriture
  if ! archive_lock; then
    why="verrou d archivage tenu (${ROOT}/.planning/.archive.lock), rien déplacé"
    if [ -n "$LOCK_HOLDER" ]; then
      case "$LOCK_HOLDER" in *[!0-9]*) live="pid illisible" ;; *) if kill -0 "$LOCK_HOLDER" 2>/dev/null; then live="vivant"; else live="absent : ce processus n existe plus, supprimer le dossier à la main"; fi ;; esac
      why="verrou d archivage tenu par le processus $LOCK_HOLDER (${live}) (${ROOT}/.planning/.archive.lock), rien déplacé, aucune reprise automatique"
    fi
    archive_refuse "${rel} : ${why}"
    return 0
  fi
  archive_one_locked "$@"
  archive_unlock
}
archive_one_locked() { # <type> <label> <fichier absolu> <nom du fichier>
  local type="$1" label="$2" src="$3" base="$4" rel bytes n why arch archrel i ref motif idx had
  # Chemin relatif à la racine : les compartiments sont énumérés en chemins ABSOLUS, même sous --root .
  case "$src" in
    "$ROOT"/*) rel="${src#"$ROOT"/}" ;;
    "$ROOT_ABS"/*) rel="${src#"$ROOT_ABS"/}" ;;
    "$ROOT_PHYS"/*) rel="${src#"$ROOT_PHYS"/}" ;;
    *) archive_refuse "${src} est hors de la racine ${ROOT}, rien déplacé"; return 0 ;;
  esac
  bytes=$(wc -c < "$src" | tr -d ' ')
  case "$type" in
    state) [ "$bytes" -gt $(( STATE_KB * 1024 )) ] || return 0; motif="budget ${STATE_KB} Ko (SOBR-02)" ;;
    roadmap) [ "$bytes" -gt $(( ROADMAP_KB * 1024 )) ] || return 0; motif="budget ${ROADMAP_KB} Ko, blocs replies (SOBR-06)" ;;
    backlog) motif="sujets clos (SOBR-06)" ;;
  esac
  [ -n "$TMPD" ] || { TMPD=$(mktemp -d) || { UNVERIFIABLE=1; flag "ARCHIVAGE NON TENTÉ : dossier temporaire impossible"; return 0; }; }
  archrel=".planning/archives/$type/${label}-${base}-${ARCHIVE_DATE}.md"
  i=1; while [ -e "$ROOT/$archrel" ]; do i=$((i + 1)); archrel=".planning/archives/$type/${label}-${base}-${ARCHIVE_DATE}-${i}.md"; done
  : > "$TMPD/cnt"; : > "$TMPD/arch"
  # La décision porte sur un INSTANTANÉ de la source ; le remplacement n'a lieu que si la source lui est encore identique.
  cp "$src" "$TMPD/snap" || { archive_refuse "${rel} : lecture impossible (copie de travail en échec)"; UNVERIFIABLE=1; return 0; }
  local prog
  case "$type" in backlog) prog="$AWK_BACKLOG_ARCHIVE" ;; state) prog="$AWK_STATE_ARCHIVE" ;; roadmap) prog="$AWK_ROADMAP_ARCHIVE" ;; esac
  LC_ALL=C awk -v ARCH="$TMPD/arch" -v ARCHREL="$archrel" -v CNT="$TMPD/cnt" "$prog" "$TMPD/snap" > "$TMPD/new" \
    || { archive_refuse "${rel} : lecture impossible (awk en échec)"; UNVERIFIABLE=1; return 0; }
  n=$(cat "$TMPD/cnt"); case "$n" in ''|*[!0-9]*) n=0 ;; esac
  [ "$n" -gt 0 ] || return 0
  if why=$(src_unclean "$rel"); then archive_refuse "$rel $why, rien déplacé"; return 0; fi
  # Preuve avant toute écriture : les lignes de la source = celles de la source allégée (hors pointeurs) + l'archive.
  # Les pointeurs sont écartés des DEUX côtés (ceux d'un archivage précédent vivent dans la source d'origine comme dans la nouvelle) ;
  # ils ont leur propre preuve : tout pointeur d'origine est encore là.
  { cat "$TMPD/new"; cat "$TMPD/arch"; } | awk 'index($0, "<!-- vf-archive: ") != 1' | LC_ALL=C sort > "$TMPD/m1"
  awk 'index($0, "<!-- vf-archive: ") != 1' "$TMPD/snap" | LC_ALL=C sort > "$TMPD/m0"
  cmp -s "$TMPD/m0" "$TMPD/m1" || { archive_refuse "$rel : preuve des lignes conservées en échec, rien déplacé"; return 0; }
  awk 'index($0, "<!-- vf-archive: ") == 1' "$TMPD/snap" | LC_ALL=C sort > "$TMPD/p0"
  awk 'index($0, "<!-- vf-archive: ") == 1' "$TMPD/new" | LC_ALL=C sort > "$TMPD/p1"
  [ -z "$(LC_ALL=C comm -23 "$TMPD/p0" "$TMPD/p1")" ] || { archive_refuse "$rel : un pointeur d'un archivage précédent a disparu, rien déplacé"; return 0; }
  [ "$DRY" -eq 0 ] || return 0   # --dry-run : la décision est prise (et ses refus dits), rien n'est écrit
  ref=$(git -C "$ROOT" rev-parse "HEAD:./$rel" 2>/dev/null) || { archive_refuse "$rel : blob d'origine illisible, rien déplacé"; return 0; }
  mkdir -p "$ROOT/.planning/archives/$type" || { archive_refuse "$rel : dossier d'archive impossible"; return 0; }
  cat "$TMPD/arch" > "$ROOT/$archrel" && cmp -s "$ROOT/$archrel" "$TMPD/arch" \
    || { rm -f "$ROOT/$archrel"; archive_refuse "$rel : archive non relisible, rien déplacé"; return 0; }
  idx="$ROOT/.planning/archives/INDEX.tsv"
  if [ -s "$idx" ]; then had=1; cp "$idx" "$TMPD/idx.prev"; else had=0; printf 'date\ttype\tsource\tarchive\tref\tmotif\n' > "$idx"; fi
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$ARCHIVE_DATE" "$type" "$rel" "$archrel" "$ref" "$motif" >> "$idx"
  # Dernière vérification, juste avant le remplacement : une écriture concurrente sur la source n'est jamais écrasée.
  if ! cmp -s "$src" "$TMPD/snap"; then
    rm -f "$ROOT/$archrel"
    if [ "$had" -eq 1 ]; then cat "$TMPD/idx.prev" > "$idx"; else rm -f "$idx"; fi
    rmdir "$ROOT/.planning/archives/$type" "$ROOT/.planning/archives" 2>/dev/null
    archive_refuse "$rel : la source a changé pendant l'archivage (écriture concurrente), rien déplacé, archive et ligne d'INDEX retirées"
    return 0
  fi
  cat "$TMPD/new" > "$src"
  flag "ARCHIVÉ : ${rel} → ${archrel} (${n} unité(s), blob d'origine ${ref:0:8}, restaurer : git cat-file blob ${ref})"
}
# <<< vf-archive-writer

# --- Budget 1 : taille des fichiers d'état -------------------------------------------------
STATE_FILES=()
[ -f "$ROOT/.planning/STATE.md" ] && STATE_FILES+=("$ROOT/.planning/STATE.md")
# Compartiments de workstream : énumérés par la primitive unique `vf_ws_enumerate`
# (planning-core/scripts/workstream-policy.sh, catégorie a1 du recensement
# workstream-planning-consumers.md), jamais par un glob maison. Politique sourcée SEULEMENT si
# `workstreams/` existe (même posture que check-divergence.sh) ; les trois codes du contrat sont
# traités, un compartiment non vérifiable est DIT, jamais tu.
WS_DIRS=""
if [ -e "$ROOT/.planning/workstreams" ]; then
  WS_POLICY=""
  for _cand in "$(dirname "$0")/workstream-policy.sh" \
               "$(dirname "$0")/../../planning-core/scripts/workstream-policy.sh"; do
    [ -r "$_cand" ] && { WS_POLICY="$_cand"; break; }
  done
  if [ -z "$WS_POLICY" ]; then
    UNVERIFIABLE=1
    flag "STATE NON VÉRIFIABLE : workstream-policy.sh introuvable, compartiments de workstream non mesurés"
  else
    # shellcheck source=/dev/null
    . "$WS_POLICY"
    WS_LIST="$(vf_ws_enumerate "$ROOT/.planning")"; _ws_rc=$?
    case "$_ws_rc" in
      0)
        WS_DIRS="$WS_LIST"
        while IFS= read -r _wsdir; do
          [ -n "$_wsdir" ] && [ -f "$_wsdir/STATE.md" ] && STATE_FILES+=("$_wsdir/STATE.md")
        done <<EOF
$WS_LIST
EOF
        ;;
      3) : ;;
      *)
        UNVERIFIABLE=1
        flag "STATE NON VÉRIFIABLE : .planning/workstreams illisible (vf_ws_enumerate rc $_ws_rc)"
        ;;
    esac
  fi
fi
archive_pass() {
  local names nm dir found t label file base targets types line
  names="$WS_NAMED"
  if [ "$AUTO" -eq 1 ] && [ -z "${names//[$'\n ']/}" ]; then
    if [ -e "$ROOT/.planning/workstreams" ] && command -v vf_ws_resolve >/dev/null 2>&1; then
      vf_ws_resolve "$ROOT/.planning"; names="${VF_WS_NAME:-}"
    else
      names="${GSD_WORKSTREAM:-}"
    fi
    if [ -z "$names" ] && [ -e "$ROOT/.planning/workstreams" ]; then
      flag "ARCHIVAGE NON TENTÉ : compartiment de session non résolu (aucun --ws, ni VF_WORKSTREAM, GSD_WORKSTREAM ou pointeur active-workstream) sur un dépôt partitionné, rien déplacé"
      return 0
    fi
  fi
  targets="racine|$ROOT/.planning"
  while IFS= read -r nm; do
    [ -n "$nm" ] || continue
    case ",$PROTECTED_WS," in
      *",$nm,"*) flag "ARCHIVAGE REFUSÉ : compartiment protégé ${nm} (VF_ARCHIVE_PROTECTED_WS), rien déplacé"; return 0 ;;
    esac
    found=""
    while IFS= read -r dir; do
      [ -n "$dir" ] || continue
      [ "${dir##*/}" = "$nm" ] && { found="$dir"; break; }
    done <<EOF4
$WS_DIRS
EOF4
    if [ -z "$found" ]; then
      if [ "$AUTO" -eq 1 ]; then flag "ARCHIVAGE NON TENTÉ : compartiment ${nm} introuvable sous .planning/workstreams, rien déplacé"; return 0; fi
      echo "[budget] compartiment introuvable : $nm" >&2; exit 64
    fi
    targets="$targets
${nm}|$found"
  done <<EOF5
$names
EOF5
  if [ "$AUTO" -eq 1 ]; then types="backlog state roadmap"; else types="$(printf '%s' "$ARCHIVE_TYPES" | tr ',' ' ')"; fi
  while IFS='|' read -r label dir; do
    [ -n "$label" ] || continue
    for t in $types; do
      case "$t" in backlog) file=BACKLOG.md; base=BACKLOG ;; state) file=STATE.md; base=STATE ;; roadmap) file=ROADMAP.md; base=ROADMAP ;; esac
      archive_one "$t" "$label" "$dir/$file" "$base"
    done
  done <<EOF6
$targets
EOF6
}
if [ "$AUTO" -eq 1 ] || [ -n "$ARCHIVE_TYPES" ]; then archive_pass; fi
if [ "${#STATE_FILES[@]}" -eq 0 ]; then
  say "STATE : aucun fichier d'état sous $ROOT/.planning, budget non applicable"
fi
for f in "${STATE_FILES[@]+"${STATE_FILES[@]}"}"; do
  bytes=$(wc -c < "$f" | tr -d ' ')
  kb=$(( (bytes + 1023) / 1024 ))
  if [ "$bytes" -gt $(( STATE_KB * 1024 )) ]; then
    OVER=1
    flag "STATE DÉPASSÉ : $f fait $kb Ko (budget $STATE_KB Ko). Réécrire la position courante, archiver l'historique sous .planning/archives/state/"
  else
    say "STATE ok : $f fait $kb Ko (budget $STATE_KB Ko)"
  fi
done

# --- Budget 1bis : BACKLOG ouvert, ROADMAP, index de mémoire, plafonds de prose ------------------------
readable() { # <fichier> <étiquette> : 0 lisible, 1 absent, 2 présent mais illisible (NON VÉRIFIABLE dit)
  [ -e "$1" ] || return 1
  if [ -f "$1" ] && [ -r "$1" ]; then return 0; fi
  UNVERIFIABLE=1; flag "$2 NON VÉRIFIABLE : $1 est illisible ou n'est pas un fichier"; return 2
}
PLAN_DIRS="$ROOT/.planning"
[ -z "$WS_DIRS" ] || PLAN_DIRS="$PLAN_DIRS
$WS_DIRS"
while IFS= read -r d; do
  [ -n "$d" ] || continue
  f="$d/BACKLOG.md"
  if readable "$f" BACKLOG; then
    out=$(LC_ALL=C awk -v MAX="$BACKLOG_ENTRY_MAX" "$AWK_BACKLOG_MEASURE" "$f"); rc=$?
    if [ "$rc" -ne 0 ]; then UNVERIFIABLE=1; flag "BACKLOG NON VÉRIFIABLE : $f lecture en échec (awk rc $rc)"; else
      nopen=0; nclosed=0
      while IFS=$'\t' read -r kind a b c; do
        case "$kind" in
          C) nopen="$a"; nclosed="$b" ;;
          L) OVER=1; flag "PROSE DÉPASSÉE : ${f}:${a} (entrée « ${c} » de ${b} lignes, plafond ${BACKLOG_ENTRY_MAX})" ;;
        esac
      done <<EOF7
$out
EOF7
      if [ "$nopen" -gt "$BACKLOG_OPEN_MAX" ]; then
        OVER=1; flag "BACKLOG DÉPASSÉ : $f compte $nopen sujets ouverts (budget $BACKLOG_OPEN_MAX) — trier, clore ou traiter"
      else
        say "BACKLOG ok : $f compte $nopen sujets ouverts (budget $BACKLOG_OPEN_MAX)"
      fi
      if [ "$nclosed" -gt 0 ]; then
        OVER=1; flag "ARCHIVABLE : $f porte $nclosed sujet(s) clos encore en ligne (--archive backlog)"
      fi
    fi
  fi
  f="$d/ROADMAP.md"
  if readable "$f" ROADMAP; then
    bytes=$(wc -c < "$f" | tr -d ' '); kb=$(( (bytes + 1023) / 1024 ))
    if [ "$bytes" -gt $(( ROADMAP_KB * 1024 )) ]; then
      OVER=1; flag "ROADMAP DÉPASSÉ : $f fait $kb Ko (budget $ROADMAP_KB Ko) — replier les jalons livrés (<details>) puis --archive roadmap"
    else
      say "ROADMAP ok : $f fait $kb Ko (budget $ROADMAP_KB Ko)"
    fi
  fi
done <<EOF8
$PLAN_DIRS
EOF8
for f in "${STATE_FILES[@]+"${STATE_FILES[@]}"}"; do
  readable "$f" STATE || continue
  out=$(LC_ALL=C awk -v MAX="$STATE_NOTE_MAX" "$AWK_STATE_PROSE" "$f"); rc=$?
  if [ "$rc" -ne 0 ]; then UNVERIFIABLE=1; flag "STATE NON VÉRIFIABLE : $f lecture en échec (awk rc $rc)"; continue; fi
  while IFS=$'\t' read -r a b; do
    [ -n "$a" ] || continue
    OVER=1; flag "PROSE DÉPASSÉE : ${f}:${a} (paragraphe de ${b} lignes, plafond ${STATE_NOTE_MAX})"
  done <<EOF9
$out
EOF9
done
MEM_INDEXES=$( { find "$ROOT/.claude/agent-memory" -maxdepth 2 -name MEMORY.md 2>/dev/null; [ -f "$ROOT/.claude/memory/MEMORY.md" ] && echo "$ROOT/.claude/memory/MEMORY.md"; } | LC_ALL=C sort )
while IFS= read -r f; do
  [ -n "$f" ] || continue
  readable "$f" MEMORY || continue
  nl=$(awk 'END { print NR }' "$f")
  if [ "$nl" -gt "$MEMIDX_MAX" ]; then
    OVER=1; flag "MEMORY DÉPASSÉ : $f fait $nl lignes (budget $MEMIDX_MAX : au-delà l'index n'est plus chargé en entier)"
  else
    say "MEMORY ok : $f fait $nl lignes (budget $MEMIDX_MAX)"
  fi
done <<EOF10
$MEM_INDEXES
EOF10

# --- Budget 2 : worktrees actifs par dépôt -------------------------------------------------
is_repo() { git -C "$1" rev-parse --git-dir >/dev/null 2>&1; }
if [ "${#REPOS[@]}" -eq 0 ]; then
  if is_repo "$ROOT"; then
    REPOS+=("$ROOT")
  else
    for d in "$ROOT"/*/; do
      d="${d%/}"
      [ -e "$d/.git" ] && REPOS+=("$d")
    done
  fi
fi

base_ref() { # <repo> -> branche de référence (origin/HEAD, sinon main, sinon master)
  local r="$1" ref
  ref=$(git -C "$r" symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null)
  if [ -n "$ref" ]; then echo "$ref"; return; fi
  for ref in main master; do
    git -C "$r" rev-parse -q --verify "refs/heads/$ref" >/dev/null 2>&1 && { echo "$ref"; return; }
  done
}

common_dir() { # <repo> -> dossier git commun, absolu (un worktree et son dépôt le partagent)
  local d
  d=$(git -C "$1" rev-parse --git-common-dir 2>/dev/null) || return 1
  case "$d" in /*) ;; *) d="$1/$d" ;; esac
  (cd "$d" 2>/dev/null && pwd -P)
}

is_worked() { # <repo> <branche> : 0 si la branche a été travaillée (plus d'une entrée de reflog)
  # Une branche NEUVE et une branche INTÉGRÉE ont la même topologie (tête ancêtre de la base) :
  # seul le reflog les sépare. Une seule entrée (la création) = jamais travaillée = pas rangeable.
  [ "$(git -C "$1" reflog show --format=%H "refs/heads/$2" -- 2>/dev/null | grep -c .)" -gt 1 ]
}

# --- Budget 3 : rangement (lecture seule, jamais un verbe de suppression) ------------------------
GH_BIN="${VF_BUDGET_GH:-gh}"
OWNERS_OK=0

resolve_owners() { # <repo> : complète OWNERS via `gh api user` si aucun --owner ; rend 1 si impossible
  [ "$OWNERS_OK" -eq 1 ] && return 0
  if [ -z "${OWNERS//[$'\n ']/}" ]; then
    local login
    login=$(cd "$1" && "$GH_BIN" api user --jq .login 2>/dev/null) || return 1
    [ -n "$login" ] || return 1
    OWNERS="$login"
  fi
  OWNERS_OK=1
}

is_owner() { # <login> : 0 si le login figure parmi les propriétaires (insensible à la casse)
  local want have
  want=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')
  while IFS= read -r have; do
    [ -n "$have" ] || continue
    [ "$(printf '%s' "$have" | tr '[:upper:]' '[:lower:]')" = "$want" ] && return 0
  done <<EOF2
$OWNERS
EOF2
  return 1
}

is_longlived() { # <nom de branche, sans préfixe de remote> : 0 si par défaut ou longue durée (source UNIQUE de la liste)
  case "$1" in
    main|master|develop|dev|development|trunk|staging|production|prod|stable|release/*|releases/*) return 0 ;;
  esac
  return 1
}

rangement_branches() { # <repo> <base> <branches-en-worktree>
  local repo="$1" base="$2" wtb="$3" bshort cur b list rc
  bshort="${base#origin/}"
  cur=$(git -C "$repo" symbolic-ref -q --short HEAD 2>/dev/null)
  list=$(git -C "$repo" for-each-ref --merged "$base" --format='%(refname:short)' refs/heads 2>/dev/null); rc=$?
  [ "$rc" -eq 0 ] || { UNVERIFIABLE=1; flag "NON VÉRIFIABLE branches locales : git for-each-ref --merged $base a échoué (rc $rc)"; return 0; }
  while IFS= read -r b; do
    [ -n "$b" ] || continue
    [ "$b" = "$bshort" ] && continue
    [ "$b" = "$cur" ] && continue
    is_longlived "$b" && { say "branche $b : par défaut ou longue durée, jamais candidate"; continue; }
    case "
$wtb
" in *"
$b
"*) continue ;; esac
    is_worked "$repo" "$b" || continue
    OVER=1
    flag "RANGEABLE branche : $b déjà intégrée dans $base"
  done <<EOF2
$list
EOF2
}

rangement_stash() { # <repo> <base>
  local repo="$1" base="$2" bshort gd sha msg rest own list
  bshort="${base#origin/}"
  list=$(git -C "$repo" stash list --format='%gd%x09%H%x09%gs' 2>/dev/null)
  while IFS=$'\t' read -r gd sha msg; do
    [ -n "$gd" ] || continue
    sha="${sha:0:12}"
    case "$msg" in "WIP on "*) rest="${msg#WIP on }" ;; "On "*) rest="${msg#On }" ;; *) rest="" ;; esac
    case "$rest" in *:*) own="${rest%%:*}" ;; *) own="" ;; esac
    case "$own" in *"("*|*" "*) own="" ;; esac
    if [ -z "$own" ]; then
      UNVERIFIABLE=1
      flag "NON VÉRIFIABLE stash : $gd $sha « $msg » (branche d'origine illisible)"
      continue
    fi
    [ "$own" = "$bshort" ] && continue
    if ! git -C "$repo" rev-parse -q --verify "refs/heads/$own" >/dev/null 2>&1; then
      OVER=1; flag "RANGEABLE stash : $sha « $msg »"
    elif [ -n "$base" ] && is_worked "$repo" "$own" \
         && git -C "$repo" merge-base --is-ancestor "refs/heads/$own" "$base" 2>/dev/null; then
      OVER=1; flag "RANGEABLE stash : $sha « $msg »"
    fi
  done <<EOF2
$list
EOF2
}

rangement_memoires() { # <repo>
  local repo="$1" f idx list nprobe
  [ -d "$repo/.claude/agent-memory" ] || return 0
  list=$(git -C "$repo" ls-files --others --exclude-standard -- .claude/agent-memory 2>/dev/null | grep '\.md$')
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    OVER=1; flag "RANGEABLE mémoire hors git : $f"
  done <<EOF2
$list
EOF2
  list=$(git -C "$repo" ls-files -- '.claude/agent-memory/*/*.md' 2>/dev/null)
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    [ "${f##*/}" = MEMORY.md ] && continue
    idx="$repo/${f%/*}/MEMORY.md"
    grep -qF "${f##*/}" "$idx" 2>/dev/null && continue
    OVER=1; flag "RANGEABLE mémoire hors index : $f"
  done <<EOF2
$list
EOF2
  nprobe=$(find "$repo/.claude/agent-memory" -maxdepth 1 -name 'zz-probe-*' 2>/dev/null | grep -c .)
  [ "$nprobe" -eq 0 ] || say "constat : $nprobe dossier(s) zz-probe-* sous .claude/agent-memory (sondes, jamais touchées)"
}

rangement_distantes() { # <repo> <base>
  local repo="$1" base="$2" bshort raw allr refs ref short name json tsv rc auths a n pr nprs trunc origin_url want have others
  bshort="${base#origin/}"
  allr=$(git -C "$repo" for-each-ref --format='%(refname)' refs/remotes 2>/dev/null); rc=$?
  [ "$rc" -eq 0 ] || { UNVERIFIABLE=1; flag "NON VÉRIFIABLE branches distantes : git for-each-ref refs/remotes a échoué (rc $rc)"; return 0; }
  origin_url=$(git -C "$repo" config --get remote.origin.url 2>/dev/null)
  case "$allr" in
    *refs/remotes/origin/*) ;;
    *)
      if [ -z "$origin_url" ]; then
        if [ -z "$allr" ]; then say "branches distantes : aucune ref distante"; return 0; fi
        others=$(printf '%s\n' "$allr" | sed -n 's|^refs/remotes/\([^/]*\)/.*|\1|p' | sort -u | tr '\n' ' ')
        UNVERIFIABLE=1; flag "NON VÉRIFIABLE branches distantes : aucun remote origin, branches distantes non examinées (refs d'autres remotes : ${others% })"; return 0
      fi ;;
  esac
  raw=$(git -C "$repo" for-each-ref --merged "$base" --format='%(refname)' refs/remotes 2>/dev/null); rc=$?
  [ "$rc" -eq 0 ] || { UNVERIFIABLE=1; flag "NON VÉRIFIABLE branches distantes : git for-each-ref --merged $base a échoué (rc $rc)"; return 0; }
  refs=""
  while IFS= read -r ref; do
    [ -n "$ref" ] || continue
    short="${ref#refs/remotes/}"
    case "$short" in origin/*) name="${short#origin/}" ;; *) say "branche distante $short : hors du remote origin, jamais candidate"; continue ;; esac
    case "$name" in
      HEAD) continue ;;
      "$bshort") continue ;;
    esac
    is_longlived "$name" && { say "branche distante $short : par défaut ou longue durée, jamais candidate"; continue; }
    refs="$refs
$short"
  done <<EOF2
$raw
EOF2
  refs="${refs#?}"
  if [ -z "$refs" ]; then say "branches distantes : aucune candidate intégrée dans $base"; return 0; fi
  if ! command -v "$GH_BIN" >/dev/null 2>&1; then
    UNVERIFIABLE=1; flag "NON VÉRIFIABLE branches distantes : gh introuvable ($GH_BIN)"; return 0
  fi
  if ! command -v jq >/dev/null 2>&1; then
    UNVERIFIABLE=1; flag "NON VÉRIFIABLE branches distantes : jq introuvable"; return 0
  fi
  if ! resolve_owners "$repo"; then
    UNVERIFIABLE=1; flag "NON VÉRIFIABLE branches distantes : propriétaire illisible (gh api user a échoué, aucun --owner)"; return 0
  fi
  # Le dépôt que gh interroge doit être celui de remote.origin.url : sinon les PR lues ne sont pas celles de origin.
  want=$(printf '%s' "$origin_url" | sed -E 's#/+$##; s#\.git$##; s#^.*[:/]([^:/]+/[^:/]+)$#\1#')
  case "$want" in */*) ;; *) UNVERIFIABLE=1; flag "NON VÉRIFIABLE branches distantes : remote.origin.url absent ou illisible (« $origin_url »), dépôt des PR non comparable"; return 0 ;; esac
  have=$(cd "$repo" && "$GH_BIN" repo view --json nameWithOwner --jq .nameWithOwner 2>/dev/null); rc=$?
  if [ "$rc" -ne 0 ] || [ -z "$have" ]; then
    UNVERIFIABLE=1; flag "NON VÉRIFIABLE branches distantes : gh repo view a échoué ou n'a rien rendu (rc $rc), dépôt interrogé inconnu"; return 0
  fi
  if [ "$(printf '%s' "$have" | tr '[:upper:]' '[:lower:]')" != "$(printf '%s' "$want" | tr '[:upper:]' '[:lower:]')" ]; then
    UNVERIFIABLE=1; flag "NON VÉRIFIABLE branches distantes : gh interroge $have mais remote.origin.url désigne $want, les PR lues ne sont pas celles de origin"; return 0
  fi
  json=$(cd "$repo" && "$GH_BIN" pr list --state merged --limit "$PR_LIMIT" --json headRefName,number,author,baseRefName,isCrossRepository 2>/dev/null); rc=$?
  if [ "$rc" -ne 0 ]; then
    UNVERIFIABLE=1; flag "NON VÉRIFIABLE branches distantes : gh pr list a échoué (rc $rc)"; return 0
  fi
  case "$json" in *[![:space:]]*) ;; *) UNVERIFIABLE=1; flag "NON VÉRIFIABLE branches distantes : gh pr list n'a rien rendu (sortie vide, rc 0)"; return 0 ;; esac
  tsv=$(printf '%s' "$json" | jq -r 'if type=="array" then .[] | [.headRefName, (.number|tostring), (.author.login // ""), (.baseRefName // ""), (if .isCrossRepository == null then "inconnu" else (.isCrossRepository|tostring) end)] | @tsv else error("pas une liste") end' 2>/dev/null); rc=$?
  if [ "$rc" -ne 0 ]; then
    UNVERIFIABLE=1; flag "NON VÉRIFIABLE branches distantes : réponse de gh illisible (JSON invalide)"; return 0
  fi
  nprs=$(printf '%s\n' "$tsv" | grep -c .)
  trunc=0; [ "$nprs" -ge "$PR_LIMIT" ] && trunc=1
  say "branches distantes, propriétaires : $(printf '%s' "$OWNERS" | tr '\n' ' ' | sed 's/^ *//; s/ *$//')"
  while IFS= read -r ref; do
    [ -n "$ref" ] || continue
    name="${ref#*/}"
    if printf '%s\n' "$tsv" | NAME="$name" awk -F'\t' '$4 == ENVIRON["NAME"] { f = 1 } END { exit !f }'; then
      say "branche distante $ref : base d'une PR mergée (longue durée), jamais candidate"; continue
    fi
    auths=$(printf '%s\n' "$tsv" | NAME="$name" awk -F'\t' '$1 == ENVIRON["NAME"] && $5 == "false" { print $3 "\t" $2 }')
    if [ -z "$auths" ]; then
      if [ "$trunc" -eq 1 ]; then
        UNVERIFIABLE=1; flag "NON VÉRIFIABLE branche distante : $ref, aucune PR connue parmi les $nprs mergées lues (limite $PR_LIMIT atteinte, liste possiblement tronquée : VF_BUDGET_PR_LIMIT)"
      elif printf '%s\n' "$tsv" | NAME="$name" awk -F'\t' '$1 == ENVIRON["NAME"] { f = 1 } END { exit !f }'; then
        say "branche distante $ref : seule une PR de fork porte ce nom (aucune PR mergée connue de la tête dans origin), jamais candidate"
      else
        say "branche distante $ref : aucune PR mergée connue, jamais candidate"
      fi
      continue
    fi
    n=0; pr=""
    while IFS=$'\t' read -r a n_pr; do
      [ -n "$pr" ] || pr="$n_pr"
      is_owner "$a" || n=1
    done <<EOF2
$auths
EOF2
    if [ "$n" -eq 0 ]; then
      OVER=1; flag "À VALIDER branche distante : $ref (PR #$pr, $(printf '%s' "$auths" | cut -f1 | sed -n 1p)) — suppression = geste humain"
    else
      say "branche distante $ref : hors propriétaire, jamais candidate"
    fi
  done <<EOF2
$refs
EOF2
}

rangement() { # <repo> <base> <branches-en-worktree>
  local repo="$1" base="$2" wtb="$3"
  if [ -n "$base" ]; then
    rangement_branches "$repo" "$base" "$wtb"
    rangement_stash "$repo" "$base"
  fi
  rangement_memoires "$repo"
  if [ "$NO_REMOTE" -eq 1 ]; then
    say "branches distantes : non examinées (--no-remote)"
  elif [ -n "$base" ]; then
    rangement_distantes "$repo" "$base"
  fi
}

SEEN=" "
for repo in "${REPOS[@]+"${REPOS[@]}"}"; do
  if ! is_repo "$repo"; then
    say "worktrees : $repo n'est pas un dépôt git, ignoré"
    continue
  fi
  # Un worktree posé à côté du dépôt (dossier frère avec un fichier .git) désigne le MÊME dépôt :
  # compté une seule fois, sinon le budget se déclenche autant de fois qu'il y a de worktrees.
  cdir=$(common_dir "$repo") || cdir="$repo"
  case "$SEEN" in *" $cdir "*) continue ;; esac
  SEEN="$SEEN$cdir "
  repo=$(git -C "$repo" worktree list --porcelain 2>/dev/null | sed -n '1s/^worktree //p')
  [ -n "$repo" ] || continue
  porcelain=$(git -C "$repo" worktree list --porcelain 2>/dev/null)
  base=$(base_ref "$repo")
  if [ -z "$base" ]; then UNVERIFIABLE=1; flag "NON VÉRIFIABLE rangement : branche de référence introuvable dans $repo (ni origin/HEAD, ni main, ni master) : worktrees, branches, stash et branches distantes non classés"
  elif ! git -C "$repo" rev-parse -q --verify "$base^{commit}" >/dev/null 2>&1; then UNVERIFIABLE=1; flag "NON VÉRIFIABLE rangement : la branche de référence $base ne désigne aucun commit dans $repo (origin/HEAD orphelin ?) : worktrees, branches, stash et branches distantes non classés"; base=""
  fi
  active=0
  details=""
  first=1
  path=""; head=""; branch=""; prunable=0
  flush() {
    [ -n "$path" ] || return 0
    if [ "$first" -eq 1 ]; then first=0; return 0; fi  # arbre principal : hors budget
    if [ "$prunable" -eq 1 ] || [ ! -d "$path" ]; then
      details="$details
[budget]   ORPHELIN : $path (dossier absent, git worktree prune)"
      return 0
    fi
    active=$((active + 1))
    local label="${branch:-HEAD détachée ${head:0:8}}"
    local worked=1
    if [ -n "$branch" ]; then
      is_worked "$repo" "$branch" || worked=0
    fi
    if [ "$worked" -eq 0 ]; then
      [ "$QUIET" -eq 1 ] || details="$details
[budget]   actif : $path [$label] neuf, aucun commit depuis sa création"
    elif [ -n "$base" ] && git -C "$repo" merge-base --is-ancestor "$head" "$base" 2>/dev/null; then
      OVER=1
      details="$details
[budget]   RANGEABLE : $path [$label] déjà intégrée dans $base"
    elif [ "$QUIET" -eq 0 ]; then
      details="$details
[budget]   actif : $path [$label]"
    fi
  }
  while IFS= read -r line; do
    case "$line" in
      "worktree "*) flush; path="${line#worktree }"; head=""; branch=""; prunable=0 ;;
      "HEAD "*) head="${line#HEAD }" ;;
      "branch "*) branch="${line#branch refs/heads/}" ;;
      prunable*) prunable=1 ;;
    esac
  done <<EOF
$porcelain
EOF
  flush
  if [ "$active" -gt "$WT_MAX" ]; then
    OVER=1
    flag "worktrees DÉPASSÉ : $repo en a $active actifs (budget $WT_MAX)"
  else
    say "worktrees ok : $repo en a $active actifs (budget $WT_MAX)"
  fi
  [ -n "$details" ] && printf '%s\n' "${details#?}"
  wt_branches=$(printf '%s\n' "$porcelain" | sed -n 's|^branch refs/heads/||p')
  rangement "$repo" "$base" "$wt_branches"
done

if [ -n "$ARCHIVE_TYPES" ] && [ "$ARCHIVE_REFUSED" -eq 1 ]; then
  exit 2
fi
if [ "$STRICT" -eq 1 ] && [ "$UNVERIFIABLE" -eq 1 ]; then
  exit 2
fi
if [ "$OVER" -eq 1 ] && [ "$STRICT" -eq 1 ]; then
  exit 1
fi
exit 0
