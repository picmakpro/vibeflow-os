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
#   - fichiers  .claude/agent-memory/<agent>/*.md  hors MEMORY.md (l'index)
#   - titres    `## ADR-NNN` ajoutés dans docs/ADR.md          (clé : ADR-NNN)
#   - titres    `## ` ajoutés dans CLAUDE.md                   (clé : CLAUDE.md)
#
# COUVERTURE : un trailer `Ajout-Retrait: <chemin|ADR-NNN|CLAUDE.md> — <retrait | aucun : justification>`
# dans un commit de la BRANCHE (portée branche, comme G-2 : un commit ultérieur couvre un ajout
# antérieur). Motif = glob `case`, jamais eval, jamais une virgule (un trailer = un motif). Le
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
  p ~ /^\.claude\/agent-memory\/[^\/]+\/[^\/]+\.md$/ && n != "MEMORY.md" { print p "\tmemoire" }
' "$TMPD/diff_a" >> "$AJOUTS"

# --- Ajouts : titres (ajoutés moins retirés — un titre seulement modifié n'est pas un ajout) ---------
titres() {  # <fichier> <signe +|-> <sed> : une clé par ligne de titre ajoutée/retirée
  git diff -U0 "$BASE" "$HEAD_SHA" -- "$1" 2>/dev/null | awk -v s="$2" '
    substr($0, 1, 1) == s && substr($0, 2, 3) == "## " { print substr($0, 2) }' | sed -n "$3"
}
ajoute_moins_retire() {  # <fichier> <sed produisant la clé> : clés côté + absentes du côté -
  titres "$1" "+" "$2" | LC_ALL=C sort -u > "$TMPD/plus"
  titres "$1" "-" "$2" | LC_ALL=C sort -u > "$TMPD/moins"
  LC_ALL=C comm -23 "$TMPD/plus" "$TMPD/moins"
}
ajoute_moins_retire docs/ADR.md 's/^## \(ADR-[0-9][0-9]*\).*/\1/p' | awk 'NF { print $0 "\tadr" }' >> "$AJOUTS"
ajoute_moins_retire CLAUDE.md 's/^## .*/&/p' | awk 'NF { print "CLAUDE.md\tregle (" $0 ")" }' >> "$AJOUTS"

# --- Trailers : portée BRANCHE, forme seule ---------------------------------------------------------
charcount() {  # codepoints UTF-8, jamais d'octets, sans dépendre d'aucune locale installée
  printf '%s' "$1" | tr -d '[:space:]' | od -An -tu1 | tr -s ' \n' '\n' | awk 'NF && ($1 < 128 || $1 >= 192) { n++ } END { print n + 0 }'
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
echo "decouverte: commits=${COMMITS_COUNT} ajouts=${AJOUTS_N} marqueurs_conformes=${MARQ_OK}"
while IFS= read -r m; do
  [ -z "$m" ] && continue
  echo "MARQUEUR-MAL-FORME: ${m}"
  [ "$CI_MODE" -eq 1 ] && echo "::warning::check-ajout-retrait : MARQUEUR-MAL-FORME — ${m}"
done <<EOF_MAL
$MAL_FORMES
EOF_MAL

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
