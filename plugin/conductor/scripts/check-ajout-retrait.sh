#!/usr/bin/env bash
# check-ajout-retrait.sh — SOBR-05 (phase 41.3). Rend VISIBLE qu'une branche AJOUTE à la méthode —
# un gate, un ADR, une règle de CLAUDE.md, une mémoire d'agent — sans dire ce qu'elle RETIRE en
# contrepartie, ni pourquoi rien n'est à retirer. Principe : ce qu'on crée, on le range ; ce qu'on
# ajoute, on dit ce qu'on enlève (arbitrage Samuel, AskUserQuestion session principale, 2026-09-29).
#
# CONSULTATIF (ADR-074 amendé) : la matière gardée est de la documentation et du jugement sur la
# méthode, pas l'intégrité technique d'un état. Par défaut rc 0 quoi qu'on trouve ; le défaut est
# SIGNALÉ (stdout, et `::warning::` sous --ci), jamais silencieux. --strict rend les codes 0/1/2 :
# c'est le mode de la suite et du dogfood, pas celui de la CI.
#
# LIMITE DE FOND (comme G-1/G-2/G-3, ADR-072) : cette garde vit dans le dépôt, la PR qu'elle juge
# peut la modifier, et le trailer est DÉCLARATIF — sa forme est vérifiée, jamais sa véracité.
#
# AJOUTS SURVEILLÉS (une seule lecture du diff base..HEAD, statut A seul, renommages exclus) :
#   - fichiers  plugin/<module>/scripts/{check,guard}-*.sh  et  scripts/check-*.sh
#   - fichiers  plugin/<module>/rules/*.md                     (règles de module)
#   - fichiers  .claude/agent-memory/**/*.md  hors MEMORY.md (l'index), sous-dossiers compris
#   - titres    `## ADR-NNN` ajoutés dans docs/ADR.md          (clé : ADR-NNN)
#   - CLAUDE.md titres `## ` ET puces de tête de ligne (`- `, `N. `) ajoutés  (clé : CLAUDE.md) ; une
#               puce se compare SANS son marqueur (un renumérotage n'est pas un ajout)
# REMPLACEMENT : le retrait est dans le diff. Un fichier supprimé (statut D) du même genre compense un
# ajout de ce genre (un pour un) ; dans ADR.md et CLAUDE.md, seul l'EXCÈS d'ajouts sur les retraits (par
# contenu) est jugé. Un remplacement ne rougit donc pas : il est listé AJOUT-COMPENSE, jamais tu.
#
# COUVERTURE : un trailer `Ajout-Retrait: <chemin|ADR-NNN|CLAUDE.md> — <retrait | aucun : justification>`
# dans un commit de la BRANCHE (portée branche, comme G-2 : un commit ultérieur couvre un ajout
# antérieur). Motif = glob `case`, jamais eval, jamais une virgule (un trailer = un motif) ; un glob ne
# couvre pas le monde : il n'est admis que dans le DERNIER segment (`plugin/*` et `*` refusés) et doit y
# garder au moins 6 caractères littéraux (`check-*.sh` passe, `*.sh` et `*` non) — sinon MARQUEUR-MAL-FORME
# et rien n'est couvert. Le
# séparateur est ` — ` (ou ` - `, borne ASCII). Après le séparateur : soit un retrait nommé (10
# caractères non blancs au moins), soit `aucun :` SUIVI d'une justification de 10 caractères au moins
# — `aucun :` seul ne couvre rien.
#
# Usage : check-ajout-retrait.sh [--root DIR] [--base-ref REF] [--strict] [--ci]
# Exit : 0 = couvert, rien à juger, ou défaut consultatif · 1 = --strict et ajout non couvert ·
#        2 = --strict et NON VÉRIFIABLE (base introuvable, hors dépôt, diff illisible) ·
#        64 = usage. Base : --base-ref, sinon refs/remotes/origin/main, origin/main, refs/heads/main,
#        main ; puis `git merge-base HEAD <ref>`, jamais l'adjacence du journal.
set -uo pipefail

ROOT="."
BASE_REF_OVERRIDE=""
STRICT=0
CI_MODE=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --root)
      if [ "$#" -lt 2 ]; then echo "[check-ajout-retrait] --root necessite une valeur" >&2; exit 64; fi
      ROOT="$2"; shift 2 ;;
    --base-ref)
      if [ "$#" -lt 2 ]; then echo "[check-ajout-retrait] --base-ref necessite une valeur" >&2; exit 64; fi
      BASE_REF_OVERRIDE="$2"; shift 2 ;;
    --strict) STRICT=1; shift ;;
    --ci) CI_MODE=1; shift ;;
    -h|--help) grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
    *) echo "[check-ajout-retrait] argument inconnu : $1" >&2; exit 64 ;;
  esac
done

if [ ! -d "$ROOT" ] || ! cd "$ROOT" 2>/dev/null; then
  echo "[check-ajout-retrait] --root introuvable : $ROOT" >&2
  exit 64
fi

# NON VÉRIFIABLE est BRUYANT (stderr, ::warning:: en CI) ; seul --strict en fait un rc 2.
non_verifiable() {
  echo "NON-VERIFIABLE: $1" >&2
  if [ "$CI_MODE" -eq 1 ]; then echo "::warning::check-ajout-retrait : NON VÉRIFIABLE — $1"; fi
  [ "$STRICT" -eq 1 ] && exit 2
  exit 0
}

git rev-parse --show-toplevel >/dev/null 2>&1 || non_verifiable "hors d'un arbre git : $ROOT"

CASCADE="refs/remotes/origin/main origin/main refs/heads/main main"
resolve_ref() {
  if [ -n "$BASE_REF_OVERRIDE" ]; then
    git rev-parse --verify -q "${BASE_REF_OVERRIDE}^{commit}" >/dev/null 2>&1 && { printf '%s' "$BASE_REF_OVERRIDE"; return 0; }
    return 1
  fi
  for r in $CASCADE; do
    git rev-parse --verify -q "${r}^{commit}" >/dev/null 2>&1 && { printf '%s' "$r"; return 0; }
  done
  return 1
}

REF_RESOLVED="$(resolve_ref)" || non_verifiable "aucune ref de base resoluble (cascade : --base-ref, ${CASCADE})"
BASE="$(git merge-base HEAD "$REF_RESOLVED" 2>/dev/null)"
[ -n "$BASE" ] || non_verifiable "merge-base introuvable entre HEAD et ${REF_RESOLVED}"
HEAD_SHA="$(git rev-parse HEAD)"

TMPD="$(mktemp -d)"
trap 'rm -rf "$TMPD"' EXIT
AJOUTS="$TMPD/ajouts"; TRAILERS_OK="$TMPD/trailers_ok"
: > "$AJOUTS"; : > "$TRAILERS_OK"

# --- Ajouts : fichiers (statut A, renommages exclus) -------------------------------------------------
git diff --name-status -M --diff-filter=A "$BASE" "$HEAD_SHA" > "$TMPD/diff_a" 2>/dev/null || non_verifiable "git diff --name-status illisible"
awk -F'\t' '
  $1 != "A" { next }
  { p = $2; n = p; sub(/.*\//, "", n) }
  p ~ /^plugin\/[^\/]+\/scripts\/(check|guard)-[^\/]+\.sh$/ { print p "\tfichier"; next }
  p ~ /^scripts\/check-[^\/]+\.sh$/ { print p "\tfichier"; next }
  p ~ /^plugin\/[^\/]+\/rules\/[^\/]+\.md$/ { print p "\trules"; next }
  p ~ /^\.claude\/agent-memory\/.+\.md$/ && n != "MEMORY.md" { print p "\tmemoire" }
' "$TMPD/diff_a" >> "$AJOUTS"

# --- Retraits : fichiers supprimés (statut D) des mêmes genres — un retrait visible compense un ajout ---
git diff --name-status -M --diff-filter=D "$BASE" "$HEAD_SHA" > "$TMPD/diff_d" 2>/dev/null || non_verifiable "git diff --name-status (D) illisible"
awk -F'\t' '
  $1 != "D" { next }
  { p = $2; n = p; sub(/.*\//, "", n) }
  p ~ /^plugin\/[^\/]+\/scripts\/(check|guard)-[^\/]+\.sh$/ { print "fichier"; next }
  p ~ /^scripts\/check-[^\/]+\.sh$/ { print "fichier"; next }
  p ~ /^plugin\/[^\/]+\/rules\/[^\/]+\.md$/ { print "rules"; next }
  p ~ /^\.claude\/agent-memory\/.+\.md$/ && n != "MEMORY.md" { print "memoire" }
' "$TMPD/diff_d" > "$TMPD/retraits"
COMPENSES="$TMPD/compenses"; : > "$COMPENSES"
awk -F'\t' -v rf="$TMPD/retraits" -v cf="$COMPENSES" '
  BEGIN { while ((getline l < rf) > 0) r[l]++ }
  ($2 in r) && r[$2] > 0 { r[$2]--; print $0 > cf; next }
  { print }
' "$AJOUTS" > "$TMPD/ajouts_nets" && cat "$TMPD/ajouts_nets" > "$AJOUTS"

# --- Ajouts : titres et puces (ajoutés moins retirés, par contenu — modifier n'est pas ajouter) -------
titres() {  # <fichier> <signe +|-> <sed> : une clé par ligne de titre ajoutée/retirée
  git diff -U0 "$BASE" "$HEAD_SHA" -- "$1" 2>/dev/null | awk -v s="$2" '
    substr($0, 1, 1) == s && substr($0, 2, 3) == "## " { print substr($0, 2) }' | sed -n "$3"
}
regles() {  # <signe +|-> : titres `## ` et puces de tête de ligne de CLAUDE.md, sans leur marqueur de liste
  git diff -U0 "$BASE" "$HEAD_SHA" -- CLAUDE.md 2>/dev/null | awk -v s="$1" '
    substr($0, 1, 1) != s { next }
    { l = substr($0, 2) }
    l ~ /^## / { print l; next }
    l ~ /^- / { sub(/^- /, "", l); print l; next }
    l ~ /^[0-9]+\. / { sub(/^[0-9]+\. /, "", l); print l }'
}
net_excess() {  # <plus> <moins> (triés, uniques) : les premiers (|plus\moins| - |moins\plus|) éléments de plus\moins
  LC_ALL=C comm -23 "$1" "$2" > "$TMPD/po"; LC_ALL=C comm -13 "$1" "$2" > "$TMPD/mo"
  local n m ex
  n="$(awk 'END { print NR }' "$TMPD/po")"; m="$(awk 'END { print NR }' "$TMPD/mo")"; ex=$((n - m))
  [ "$ex" -gt 0 ] && head -n "$ex" "$TMPD/po"
  return 0
}
titres docs/ADR.md "+" 's/^## \(ADR-[0-9][0-9]*\).*/\1/p' | LC_ALL=C sort -u > "$TMPD/plus"
titres docs/ADR.md "-" 's/^## \(ADR-[0-9][0-9]*\).*/\1/p' | LC_ALL=C sort -u > "$TMPD/moins"
net_excess "$TMPD/plus" "$TMPD/moins" | awk 'NF { print $0 "\tadr" }' >> "$AJOUTS"
regles "+" | LC_ALL=C sort -u > "$TMPD/plus"; regles "-" | LC_ALL=C sort -u > "$TMPD/moins"
net_excess "$TMPD/plus" "$TMPD/moins" | awk 'NF { t = substr($0, 1, 60); print "CLAUDE.md\tregle (" t ")" }' >> "$AJOUTS"

# --- Trailers : portée BRANCHE, forme seule ---------------------------------------------------------
charcount() {  # codepoints UTF-8, jamais d'octets, sans dépendre d'aucune locale installée
  printf '%s' "$1" | tr -d '[:space:]' | od -An -tu1 | tr -s ' \n' '\n' | awk 'NF && ($1 < 128 || $1 >= 192) { n++ } END { print n + 0 }'
}
glob_admis() {  # <motif> : un glob ne couvre pas le monde (dernier segment seul, >= 6 caractères littéraux)
  local m="$1" dirs last lit
  case "$m" in */*) dirs="${m%/*}"; last="${m##*/}" ;; *) dirs=""; last="$m" ;; esac
  case "$m" in *'*'*|*'?'*|*'['*) ;; *) return 0 ;; esac
  case "$dirs" in *'*'*|*'?'*|*'['*) return 1 ;; esac
  lit="$(printf '%s' "$last" | tr -d '*?[]')"
  [ "${#lit}" -ge 6 ]
}
COMMITS_LIST="$(git rev-list "${BASE}..${HEAD_SHA}" 2>/dev/null)"
COMMITS_COUNT="$(printf '%s\n' "$COMMITS_LIST" | awk 'NF { n++ } END { print n + 0 }')"
MARQ_OK=0
MAL_FORMES=""
while IFS= read -r c; do
  [ -z "$c" ] && continue
  while IFS= read -r line; do
    trimmed="${line#"${line%%[![:space:]]*}"}"
    case "$trimmed" in
      Ajout-Retrait:*) ;;
      *) continue ;;
    esac
    value="${trimmed#Ajout-Retrait:}"; value="${value# }"
    sep=""
    case "$value" in
      *' — '*) sep=' — ' ;;
      *' - '*) sep=' - ' ;;
    esac
    motif=""; reste=""; ok=0
    if [ -n "$sep" ]; then
      motif="${value%%"$sep"*}"; reste="${value#*"$sep"}"
      ok=1
      [ -n "$motif" ] || ok=0
      case "$motif" in *,*) ok=0 ;; esac
      case "$reste" in
        aucun\ :*|aucun:*) just="${reste#aucun}"; just="${just# }"; just="${just#:}" ;;
        aucun*) just=""; ok=0 ;;
        *) just="$reste" ;;
      esac
      [ "$ok" -eq 1 ] && [ "$(charcount "$just")" -lt 10 ] && ok=0
      if [ "$ok" -eq 1 ] && ! glob_admis "$motif"; then ok=0; trimmed="$trimmed  [motif glob trop large : admis seulement dans le dernier segment, 6 caractères littéraux au moins]"; fi
    fi
    if [ "$ok" -eq 1 ]; then
      MARQ_OK=$((MARQ_OK + 1))
      printf '%s\n' "$motif" >> "$TRAILERS_OK"
    else
      MAL_FORMES="${MAL_FORMES}${trimmed}"$'\n'
    fi
  done <<EOF_MSG
$(git log -1 --format=%B "$c" 2>/dev/null)
EOF_MSG
done <<EOF_COMMITS
$COMMITS_LIST
EOF_COMMITS

AJOUTS_N="$(awk 'NF { n++ } END { print n + 0 }' "$AJOUTS")"
COMPENSES_N="$(awk 'NF { n++ } END { print n + 0 }' "$COMPENSES")"
echo "decouverte: commits=${COMMITS_COUNT} ajouts=${AJOUTS_N} compenses=${COMPENSES_N} marqueurs_conformes=${MARQ_OK}"
while IFS="$(printf '\t')" read -r ck cg; do
  [ -z "$ck" ] && continue
  echo "AJOUT-COMPENSE: ${ck} (${cg}) — un fichier du même genre est supprimé dans ce diff (le retrait est visible)"
done < "$COMPENSES"
while IFS= read -r m; do
  [ -z "$m" ] && continue
  echo "MARQUEUR-MAL-FORME: ${m}"
  [ "$CI_MODE" -eq 1 ] && echo "::warning::check-ajout-retrait : MARQUEUR-MAL-FORME — ${m}"
done <<EOF_MAL
$MAL_FORMES
EOF_MAL

if [ "$AJOUTS_N" -eq 0 ] && [ "$COMPENSES_N" -gt 0 ]; then
  echo "COUVERT"
  exit 0
fi
if [ "$AJOUTS_N" -eq 0 ]; then
  echo "RIEN-A-JUGER: aucun ajout surveille entre ${BASE} et HEAD"
  exit 0
fi

# --- Couverture : `case`, jamais eval ------------------------------------------------------------------
NON_COUVERTS=0
while IFS="$(printf '\t')" read -r cle genre; do
  [ -z "$cle" ] && continue
  couvert=0
  while IFS= read -r motif; do
    [ -z "$motif" ] && continue
    case "$cle" in
      ($motif) couvert=1; break ;;
    esac
  done < "$TRAILERS_OK"
  if [ "$couvert" -eq 1 ]; then
    echo "AJOUT-COUVERT: ${cle} (${genre})"
  else
    echo "AJOUT-NON-COUVERT: ${cle} (${genre}) — trailer attendu : Ajout-Retrait: ${cle} — <retrait | aucun : justification>"
    [ "$CI_MODE" -eq 1 ] && echo "::warning::check-ajout-retrait (consultatif) : ${cle} (${genre}) ajouté sans trailer Ajout-Retrait — dire ce qu'on retire, ou pourquoi rien"
    NON_COUVERTS=$((NON_COUVERTS + 1))
  fi
done < "$AJOUTS"

if [ "$NON_COUVERTS" -eq 0 ]; then
  echo "COUVERT"
  exit 0
fi
echo "NON-COUVERT: ${NON_COUVERTS} ajout(s) sans retrait ni justification"
[ "$STRICT" -eq 1 ] && exit 1
exit 0
