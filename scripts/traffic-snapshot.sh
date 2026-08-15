#!/usr/bin/env bash
# traffic-snapshot.sh — Historique durable des stats GitHub traffic, corrigé du bruit CI.
#
# GitHub ne conserve les stats "traffic" (clones, vues) que 14 jours glissants — sans snapshot,
# la donnée disparaît. Pire : chaque job Actions avec `actions/checkout` compte comme un clone.
# Mesure du 2026-08-15 qui motive ce script : 585 clones sur 14 jours, 101 runs CI × 4 jobs sur la
# même fenêtre — le 2026-08-02, 61 clones affichés pour ~60 checkouts CI, soit une adoption réelle
# proche de zéro là où le graphe GitHub affiche 61. `clones_adjusted` corrige ce biais.
#
# Usage :
#   traffic-snapshot.sh [--repo OWNER/NAME] [--out CHEMIN] [--dry-run] [--help]
#
#   --repo OWNER/NAME   Dépôt ciblé (défaut : picmakpro/vibeflow-os).
#   --out CHEMIN        Fichier JSON à lire/fusionner/écrire (défaut : traffic.json).
#   --dry-run           Émet le JSON fusionné sur stdout, n'écrit jamais le fichier.
#   -h, --help          Cette aide.
#
# Séparation des jetons (point dur du cadrage). L'API traffic exige un accès admin/push que le
# `GITHUB_TOKEN` d'Actions n'a pas ; le comptage des jobs CI, lui, s'en contente. Les appels
# `traffic/clones` et `traffic/views` utilisent `TRAFFIC_PAT` (variable d'env) s'il est non vide,
# sinon retombent sur l'authentification ambiante de `gh` (cas du poste local). Les appels
# `actions/runs` et `actions/runs/<id>/jobs` utilisent toujours l'authentification ambiante. Le
# jeton n'est jamais imprimé, jamais passé en argument de commande, et ce script ne pose jamais
# `set -x`.
#
# Diagnostic 403 : un échec sur `traffic/clones` ou `traffic/views` nomme la cause (droit
# "Administration: read" manquant) et le chemin de correction (PAT fine-grained + secret
# TRAFFIC_PAT), puis sort en 1. Jamais de repli silencieux sur un objet vide.
#
# Fenêtre de calcul : dérivée du plus ancien `timestamp` présent dans l'union clones+vues, tronqué
# à 10 caractères. Aucun appel à `date -d`/`date -v` (portabilité macOS ↔ ubuntu-latest, ce dépôt a
# déjà payé des régressions sur ce point le 2026-07-27).
#
# Forme du fichier écrit : objet dont les clés sont des dates `YYYY-MM-DD` (pas de clé de
# métadonnées), chaque valeur portant `clones`, `clones_uniques`, `views`, `views_uniques`,
# `ci_jobs`, `clones_adjusted` (= max(0, clones - ci_jobs)). L'ensemble des dates est l'union de
# celles vues côté clones et côté vues ; une métrique absente d'un des deux payloads vaut 0.
#
# Fusion idempotente : un `--out` existant est lu, puis fusionné avec le nouveau payload — les
# dates fraîches écrasent, les dates absentes du nouveau payload sont conservées. Écriture atomique
# (fichier temporaire puis `mv`) pour qu'un échec en cours de route ne laisse pas un fichier tronqué.
#
# Couture de test : si VF_TRAFFIC_FIXTURES est défini et non vide, les quatre fonctions d'appel
# (api_traffic_clones, api_traffic_views, api_runs_page, api_run_jobs) lisent leurs payloads sur
# disque au lieu du réseau et les rendent VERBATIM — parsing, agrégation, ajustement et fusion
# restent le chemin de production, sans variante.
#
# Codes de sortie : 0 = conforme · 1 = échec d'appel ou de fusion · 2 = usage/prérequis manquant
set -euo pipefail

REPO="picmakpro/vibeflow-os"
OUT="traffic.json"
DRY_RUN=false

usage() { grep '^# ' "$0" | sed 's/^# //'; }

while [ $# -gt 0 ]; do
  case "$1" in
    --repo) shift; [ $# -gt 0 ] || { echo "[traffic-snapshot] --repo attend une valeur" >&2; exit 2; }
            REPO="$1" ;;
    --repo=*) REPO="${1#--repo=}" ;;
    --out) shift; [ $# -gt 0 ] || { echo "[traffic-snapshot] --out attend une valeur" >&2; exit 2; }
           OUT="$1" ;;
    --out=*) OUT="${1#--out=}" ;;
    --dry-run) DRY_RUN=true ;;
    -h|--help) usage; exit 0 ;;
    *) echo "[traffic-snapshot] argument inconnu : $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

# `gh` n'est requis que hors couture de test : sous VF_TRAFFIC_FIXTURES, les quatre fonctions
# d'appel ne le sollicitent jamais (elles lisent des fixtures sur disque) — l'exiger quand même
# romprait la discriminance du test T9 (la suite doit rester verte sans gh sur le PATH).
if [ -z "${VF_TRAFFIC_FIXTURES:-}" ]; then
  command -v gh >/dev/null 2>&1 || { echo "[traffic-snapshot] gh introuvable — prérequis manquant" >&2; exit 2; }
fi
command -v jq >/dev/null 2>&1 || { echo "[traffic-snapshot] jq introuvable — prérequis manquant" >&2; exit 2; }

# Appel authentifié à l'endpoint traffic (droit admin requis). $1 = chemin d'API relatif.
# TRAFFIC_PAT n'écrase l'authentification ambiante QUE pour cet appel (portée de variable d'env
# scopée à la commande), jamais exportée plus largement.
_gh_traffic_call() {
  local endpoint="$1" body rc
  if [ -n "${TRAFFIC_PAT:-}" ]; then
    body="$(GH_TOKEN="$TRAFFIC_PAT" gh api "$endpoint" 2>&1)" && rc=0 || rc=$?
  else
    body="$(gh api "$endpoint" 2>&1)" && rc=0 || rc=$?
  fi
  if [ "$rc" -ne 0 ]; then
    echo "[traffic-snapshot] échec de l'appel $endpoint (gh sort $rc) : $body" >&2
    echo "[traffic-snapshot] cause probable : l'endpoint traffic exige le droit \"Administration: read\", que le jeton employé n'a pas (403 attendu sans PAT admin)." >&2
    echo "[traffic-snapshot] correction : créer un PAT fine-grained sur le seul dépôt $REPO (permissions Administration: read + Metadata: read), puis le poser en secret de dépôt TRAFFIC_PAT." >&2
    exit 1
  fi
  printf '%s\n' "$body"
}

api_traffic_clones() {
  if [ -n "${VF_TRAFFIC_FIXTURES:-}" ]; then cat "$VF_TRAFFIC_FIXTURES/clones.json"; return 0; fi
  _gh_traffic_call "repos/$REPO/traffic/clones"
}

api_traffic_views() {
  if [ -n "${VF_TRAFFIC_FIXTURES:-}" ]; then cat "$VF_TRAFFIC_FIXTURES/views.json"; return 0; fi
  _gh_traffic_call "repos/$REPO/traffic/views"
}

# Runs CI depuis la borne $1 (YYYY-MM-DD). Authentification ambiante (GITHUB_TOKEN suffit).
api_runs_page() {
  local since="$1"
  if [ -n "${VF_TRAFFIC_FIXTURES:-}" ]; then cat "$VF_TRAFFIC_FIXTURES/runs.json"; return 0; fi
  gh api --paginate "repos/$REPO/actions/runs?created=%3E%3D${since}&per_page=100"
}

# Jobs du run $1. `filter=all` obligatoire : le défaut (`latest`) masque les tentatives de re-run,
# qui produisent pourtant de vrais `actions/checkout`, donc de vrais clones.
api_run_jobs() {
  local run_id="$1"
  if [ -n "${VF_TRAFFIC_FIXTURES:-}" ]; then cat "$VF_TRAFFIC_FIXTURES/jobs/${run_id}.json"; return 0; fi
  gh api "repos/$REPO/actions/runs/${run_id}/jobs?filter=all&per_page=100"
}

TMP_FILES=()
trap 'rm -f "${TMP_FILES[@]:-}"' EXIT

CLONES_JSON="$(api_traffic_clones)"
VIEWS_JSON="$(api_traffic_views)"

# Borne basse de la fenêtre : le plus ancien timestamp de l'union clones+vues, tronqué à 10
# caractères. Dérivée du payload, jamais d'une arithmétique de date (portabilité).
SINCE="$( { printf '%s' "$CLONES_JSON" | jq -r '.clones[]?.timestamp // empty'
            printf '%s' "$VIEWS_JSON"  | jq -r '.views[]?.timestamp // empty'; } \
          | cut -c1-10 | sort | head -1 )"

# Base par date : clones/vues, defaults à 0 pour la métrique absente de l'un des deux payloads.
BASE_JSON="$(jq -n --argjson clones "$CLONES_JSON" --argjson views "$VIEWS_JSON" '
  ( [$clones.clones[]? | {(.timestamp[0:10]): {clones: .count, clones_uniques: .uniques}}]
  + [$views.views[]?   | {(.timestamp[0:10]): {views: .count, views_uniques: .uniques}}]
  ) as $entries
  | reduce $entries[] as $e ({}; . * $e)
  | with_entries(.value |= ({clones: 0, clones_uniques: 0, views: 0, views_uniques: 0} + .))
')"

# Comptage CI par date. Les jobs sont attribués à la date de création de leur run (approximation
# documentée : un run créé à 23h58 dont les jobs tournent après minuit est compté la veille).
CI_LINES="$(mktemp)"; TMP_FILES+=("$CI_LINES")
if [ -n "$SINCE" ]; then
  RUNS_RAW="$(mktemp)"; TMP_FILES+=("$RUNS_RAW")
  if ! api_runs_page "$SINCE" > "$RUNS_RAW"; then
    echo "[traffic-snapshot] échec de la récupération des runs CI depuis $SINCE" >&2
    exit 1
  fi
  N_RUNS="$(jq -r '.workflow_runs[]?.id' "$RUNS_RAW" | wc -l | tr -d ' ')"
  echo "[traffic-snapshot] fenêtre CI depuis $SINCE : $N_RUNS run(s) à examiner" >&2
  jq -r '.workflow_runs[]? | [.id, (.created_at[0:10])] | @tsv' "$RUNS_RAW" \
    | while IFS="$(printf '\t')" read -r run_id run_date; do
        [ -n "$run_id" ] || continue
        jobs_json="$(api_run_jobs "$run_id")"
        job_count="$(printf '%s' "$jobs_json" | jq -r '.total_count // 0')"
        printf '%s\t%s\n' "$run_date" "$job_count" >> "$CI_LINES"
        echo "[traffic-snapshot] run $run_id ($run_date) : $job_count job(s) CI" >&2
      done
fi

CI_JSON="$(jq -R -s '
  split("\n") | map(select(length > 0) | split("\t"))
  | map({date: .[0], count: (.[1] | tonumber)})
  | group_by(.date)
  | map({(.[0].date): (map(.count) | add)})
  | add // {}
' "$CI_LINES")"

FRESH_JSON="$(jq -n --argjson base "$BASE_JSON" --argjson ci "$CI_JSON" '
  $base | with_entries(
    .value.ci_jobs = ($ci[.key] // 0)
    | .value.clones_adjusted = ([(.value.clones - .value.ci_jobs), 0] | max)
  )
')"

# Fusion idempotente : l'existant survit, le frais rafraîchit — jamais de suppression de date.
if [ -f "$OUT" ] && [ -s "$OUT" ] && jq -e . "$OUT" >/dev/null 2>&1; then
  EXISTING_JSON="$(cat "$OUT")"
else
  EXISTING_JSON="{}"
fi
MERGED_JSON="$(jq -n --argjson old "$EXISTING_JSON" --argjson fresh "$FRESH_JSON" '$old * $fresh' | jq -S .)"

if $DRY_RUN; then
  printf '%s\n' "$MERGED_JSON"
else
  OUT_DIR="$(dirname "$OUT")"
  mkdir -p "$OUT_DIR"
  TMP_OUT="$(mktemp "$OUT_DIR/.traffic-snapshot.XXXXXX")"; TMP_FILES+=("$TMP_OUT")
  printf '%s\n' "$MERGED_JSON" > "$TMP_OUT"
  mv "$TMP_OUT" "$OUT"
  N_DATES="$(printf '%s' "$MERGED_JSON" | jq 'length')"
  echo "[traffic-snapshot] écrit : $OUT ($N_DATES date(s))" >&2
fi
