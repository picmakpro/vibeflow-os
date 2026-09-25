#!/usr/bin/env bash
# measure-server-rulesets.sh — compagnon de G-4 (`scripts/check-affirmation-non-mesuree.sh`).
# Interroge `gh api repos/<owner>/<repo>/rulesets` UNE FOIS et enregistre le resultat, horodate,
# dans un fichier verse sous `.planning/`. Ce script est le SEUL a parler au reseau dans ce
# couple : la garde G-4 ne lit QUE le fichier qu'il ecrit, jamais le reseau elle-meme (mandat
# point 4, tache courte 2026-09-23).
#
# CE QUE CE SCRIPT NE FAIT PAS. Il ne juge rien : il constate un etat GitHub a un instant donne
# et l'ecrit. Le jugement (affirmation qualifiee ou non, mesure fraiche ou perimee) appartient
# entierement a `check-affirmation-non-mesuree.sh`. Une mesure ecrite ici n'est un fait DATE que
# jusqu'a ce que la garde juge qu'elle a peri (seuil configurable, defaut 7 jours).
#
# ECHEC D'API JAMAIS CONFONDU AVEC LISTE VIDE — meme discipline que `check-push-sans-pr.sh` (G-3) :
# `gh` absent, echec d'authentification, reponse non-2xx, ou JSON qui n'est pas un tableau ->
# rc 2 NON-VERIFIABLE. Un tableau vide `[]` est une reponse LUE et VALIDE (zero ruleset pose) ->
# rc 0, fichier ecrit avec `ruleset_count: 0`. Precedent nomme : le faux negatif d'auth de la
# v2.39.0 (2026-07-26), ou un `gh` non authentifie avait ete lu comme « aucune release ».
#
# FORMAT DU FICHIER ECRIT (objet JSON, un seul niveau de champs scalaires + un tableau brut) :
#   {
#     "measured_at": "<ISO8601 UTC, generee par ce script, jamais par l'appelant>",
#     "repo": "<owner>/<repo>",
#     "ruleset_count": <entier>,
#     "active_count": <entier, nombre de rulesets dont enforcement == "active">,
#     "rulesets": [ <reponse brute de l'API, telle quelle> ]
#   }
#
# Usage:
#   measure-server-rulesets.sh [--repo O/R] [--out FICHIER] [--rulesets-file FICHIER] [--dry-run] [-h|--help]
#
# Options reservees aux fixtures : --rulesets-file court-circuite l'appel reseau et lit son
# contenu comme s'il etait la reponse brute de `gh api .../rulesets` — TOUTE invocation de
# production (CI, hook, humain) l'omet et laisse l'appel reseau reel avoir lieu.
#
# --dry-run : mode INSPECTION, convention deja en usage dans ce depot (`vibeflow-update.sh
# install/update --dry-run`). N'ECRIT RIEN sur disque — ni le fichier de mesure, ni le repertoire
# --out — et emet sur STDOUT le JSON exact qui aurait ete ecrit, produit par le MEME chemin de
# code que le mode normal (fonction `build_measure_json`, jamais une seconde implementation qui
# pourrait deriver). Les lignes de diagnostic ("decouverte:", "MESURE-ECRITE:") vont sur STDERR
# dans les deux modes, pour que STDOUT ne porte jamais que la donnee. --dry-run combine a --out
# explicite est une CONTRADICTION D'USAGE refusee en rc 64 (jamais un --dry-run qui l'emporterait
# en silence sur un --out que l'appelant a explicitement demande).
#
# Exit codes (meme convention que les gardes voisines) :
#   0  = mesure ecrite (tableau JSON lu, vide ou non), ou emise sur stdout en --dry-run
#   2  = NON VERIFIABLE — `gh` absent, echec d'API, ou reponse non-tableau
#   64 = erreur d'usage (argument inconnu, option sans valeur, --out non inscriptible,
#        --dry-run + --out combines)
set -uo pipefail

REPO=""
OUT=".planning/server-rulesets-measurement.json"
OUT_EXPLICIT=0
RULESETS_FILE=""
DRY_RUN=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo)
      if [ "$#" -lt 2 ]; then echo "[measure-server-rulesets] --repo necessite une valeur" >&2; exit 64; fi
      REPO="$2"; shift 2 ;;
    --out)
      if [ "$#" -lt 2 ]; then echo "[measure-server-rulesets] --out necessite une valeur" >&2; exit 64; fi
      OUT="$2"; OUT_EXPLICIT=1; shift 2 ;;
    --rulesets-file)
      if [ "$#" -lt 2 ]; then echo "[measure-server-rulesets] --rulesets-file necessite une valeur" >&2; exit 64; fi
      RULESETS_FILE="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
    *) echo "[measure-server-rulesets] argument inconnu : $1" >&2; exit 64 ;;
  esac
done

if [ "$DRY_RUN" -eq 1 ] && [ "$OUT_EXPLICIT" -eq 1 ]; then
  echo "[measure-server-rulesets] --dry-run et --out sont incompatibles (contradiction d'usage)" >&2
  exit 64
fi

# --- Resolution du repo (owner/repo), jamais devinee sans source explicite ------------------------
if [ -z "$REPO" ]; then
  if command -v gh >/dev/null 2>&1; then
    REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "")"
  fi
fi
if [ -z "$REPO" ]; then
  url="$(git remote get-url origin 2>/dev/null || echo "")"
  REPO="$(printf '%s' "$url" | sed -E 's#^(git@|https://)([^:/]+)[:/]##; s#\.git$##')"
fi
if [ -z "$REPO" ]; then
  echo "[measure-server-rulesets] impossible de resoudre owner/repo (--repo, gh, ou origin)" >&2
  exit 64
fi

# --- Lecture de la reponse brute -------------------------------------------------------------------
CONTENT=""
if [ -n "$RULESETS_FILE" ]; then
  if [ ! -r "$RULESETS_FILE" ]; then
    echo "[measure-server-rulesets] --rulesets-file illisible : $RULESETS_FILE" >&2
    exit 64
  fi
  CONTENT="$(cat "$RULESETS_FILE")"
else
  if ! command -v gh >/dev/null 2>&1; then
    echo "[measure-server-rulesets] gh introuvable — mesure NON VERIFIABLE" >&2
    exit 2
  fi
  CONTENT="$(gh api "repos/${REPO}/rulesets" 2>/dev/null)" || {
    echo "[measure-server-rulesets] echec de l'appel gh api repos/${REPO}/rulesets — mesure NON VERIFIABLE" >&2
    exit 2
  }
fi

# --- Un tableau JSON, jamais une liste vide confondue avec un echec (borne G-3) --------------------
is_array_jq() { command -v jq >/dev/null 2>&1 && printf '%s' "$1" | jq -e 'type == "array"' >/dev/null 2>&1; }
is_array_awk() {
  # Repli awk (jq indisponible) : premier caractere non blanc de la reponse doit etre '['.
  printf '%s' "$1" | awk '{ for (i = 1; i <= length($0); i++) { c = substr($0,i,1); if (c ~ /[[:space:]]/) continue; if (c == "[") { print "ok"; exit } else { exit } } }' | grep -q ok
}

if command -v jq >/dev/null 2>&1; then
  if ! is_array_jq "$CONTENT"; then
    echo "[measure-server-rulesets] reponse non-tableau (echec d'API probable) — mesure NON VERIFIABLE" >&2
    exit 2
  fi
  RULESET_COUNT="$(printf '%s' "$CONTENT" | jq 'length')"
  ACTIVE_COUNT="$(printf '%s' "$CONTENT" | jq '[.[] | select(.enforcement == "active")] | length')"
else
  if ! is_array_awk "$CONTENT"; then
    echo "[measure-server-rulesets] reponse non-tableau (echec d'API probable, jq indisponible) — mesure NON VERIFIABLE" >&2
    exit 2
  fi
  RULESET_COUNT="$(printf '%s' "$CONTENT" | grep -o '"id"[[:space:]]*:' | wc -l | tr -d ' ')"
  ACTIVE_COUNT="$(printf '%s' "$CONTENT" | grep -o '"enforcement"[[:space:]]*:[[:space:]]*"active"' | wc -l | tr -d ' ')"
fi

MEASURED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# --- Construction du JSON de mesure — UN SEUL chemin de code, partage entre --dry-run (stdout)
# et le mode normal (fichier --out). Jamais une seconde implementation qui pourrait deriver de
# la premiere (contrainte du mandat, cf. vibeflow-update.sh --dry-run : plan et pose sortent du
# meme appel de code).
build_measure_json() {
  printf '{\n'
  printf '  "measured_at": "%s",\n' "$MEASURED_AT"
  printf '  "repo": "%s",\n' "$REPO"
  printf '  "ruleset_count": %s,\n' "$RULESET_COUNT"
  printf '  "active_count": %s,\n' "$ACTIVE_COUNT"
  printf '  "rulesets": %s\n' "$CONTENT"
  printf '}\n'
}

if [ "$DRY_RUN" -eq 1 ]; then
  # N'ECRIT RIEN : ni --out, ni son repertoire parent. La donnee (JSON) va sur stdout ; les
  # diagnostics vont sur stderr, pour que stdout ne porte jamais que la mesure.
  build_measure_json
  echo "decouverte: repo=${REPO} ruleset_count=${RULESET_COUNT} active_count=${ACTIVE_COUNT} mesure_ecrite=(dry-run, rien ecrit)" >&2
  echo "MESURE-ECRITE: ${MEASURED_AT} (dry-run)" >&2
  exit 0
fi

OUT_DIR="$(dirname "$OUT")"
if [ -n "$OUT_DIR" ] && [ "$OUT_DIR" != "." ] && [ ! -d "$OUT_DIR" ]; then
  mkdir -p "$OUT_DIR" 2>/dev/null || { echo "[measure-server-rulesets] --out repertoire non creable : $OUT_DIR" >&2; exit 64; }
fi

build_measure_json > "$OUT" || { echo "[measure-server-rulesets] --out non inscriptible : $OUT" >&2; exit 64; }

echo "decouverte: repo=${REPO} ruleset_count=${RULESET_COUNT} active_count=${ACTIVE_COUNT} mesure_ecrite=${OUT}" >&2
echo "MESURE-ECRITE: ${MEASURED_AT}" >&2
exit 0
