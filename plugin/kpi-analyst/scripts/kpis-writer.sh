#!/usr/bin/env bash
# kpis-writer.sh — Assembleur DÉTERMINISTE du registre KPIS.md d'un lab.
#
# Combine :
#   - le SCHÉMA validé (.claude/kpi/schema.json) — liste stable des KPIs (key/label/unit/target/...)
#   - les VALEURS produites par les extracteurs (.claude/kpi/extractors/*.sh), chacun émettant UNE
#     ligne JSON : {"key":...,"value":...,"source":...,"confidence":...}
#
# Produit .claude/memory/KPIS.md : frontmatter + index (lecture par défaut) + bloc JSON source-de-vérité
# (schema + values) ingéré par le Hub (tables lab_kpi_configs + kpis).
#
# DÉTERMINISTE par construction : aucun appel LLM ici. Mêmes entrées → même sortie (idempotence §6).
# L'intelligence (déduire le schéma, écrire les extracteurs) est faite EN AMONT par l'agent.
#
# Usage :
#   kpis-writer.sh --lab <slug> --domain <d> \
#     [--schema .claude/kpi/schema.json] [--extractors .claude/kpi/extractors] \
#     [--out .claude/memory/KPIS.md]
set -euo pipefail

log() { echo "[kpis-writer] $*" >&2; }
err() { echo "[kpis-writer] ERROR: $*" >&2; exit 1; }

command -v jq >/dev/null 2>&1 || err "jq introuvable (requis).
  Installer : macOS 'brew install jq' (natif depuis macOS 15) · Windows (Git Bash) 'winget install jqlang.jq' · Debian/Ubuntu 'sudo apt-get install jq'"

# jqx — wrapper jq OBLIGATOIRE (ADR-054) : le jq Windows natif écrit en mode texte (\n → \r\n) ;
# un \r résiduel contaminerait une DONNÉE PERSISTÉE (KPIS.md, ingéré par le Hub) via --arg.
# Subshell + pipefail locaux : propage le code retour de jq sans imposer pipefail à l'appelant.
jqx() ( set -o pipefail; command jq "$@" | tr -d '\r'; )

LAB="" DOMAIN=""
SCHEMA=".claude/kpi/schema.json"
EXTRACTORS=".claude/kpi/extractors"
OUT=".claude/memory/KPIS.md"

while [ $# -gt 0 ]; do
  case "$1" in
    --lab) LAB="${2:-}"; shift 2 ;;
    --domain) DOMAIN="${2:-}"; shift 2 ;;
    --schema) SCHEMA="${2:-}"; shift 2 ;;
    --extractors) EXTRACTORS="${2:-}"; shift 2 ;;
    --out) OUT="${2:-}"; shift 2 ;;
    --tier1-only) shift ;;  # garde-fou explicite : n'agrège que l'interne (Tier 2 jamais lancé ici)
    *) err "argument inconnu : $1" ;;
  esac
done

[ -n "$LAB" ] || err "--lab <slug> requis"
[ -f "$SCHEMA" ] || err "schéma introuvable : $SCHEMA (l'agent doit le poser après validation humaine)"
jqx empty "$SCHEMA" 2>/dev/null || err "schéma JSON invalide : $SCHEMA"
[ -n "$DOMAIN" ] || DOMAIN=$(jqx -r '.domain // "generic"' "$SCHEMA")

# ── 1. Collecter les valeurs : exécuter chaque extracteur, valider sa sortie JSON ───────────────
VALUES="[]"
if [ -d "$EXTRACTORS" ]; then
  for ex in "$EXTRACTORS"/*.sh; do
    [ -f "$ex" ] || continue
    line=$(bash "$ex" 2>/dev/null || true)
    [ -n "$line" ] || { log "extracteur sans sortie, ignoré : $(basename "$ex")"; continue; }
    echo "$line" | jqx -e 'has("key") and has("value")' >/dev/null 2>&1 || {
      log "sortie invalide (manque key/value), ignoré : $(basename "$ex")"; continue; }
    # Normaliser : source/confidence par défaut si absents (garde-fou : pas de source → low).
    norm=$(echo "$line" | jqx -c '{
      key, value,
      source: (.source // ""),
      confidence: (.confidence // (if (.source // "") == "" then "low" else "medium" end)),
      trend: (.trend // null)
    }')
    VALUES=$(echo "$VALUES" | jqx -c --argjson v "$norm" '. + [$v]')
  done
fi

GENERATED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# ── 2. Construire le payload machine (schema + values) ──────────────────────────────────────────
PAYLOAD=$(jqx -n \
  --arg lab "$LAB" --arg domain "$DOMAIN" --arg at "$GENERATED_AT" \
  --slurpfile schemaFile "$SCHEMA" \
  --argjson values "$VALUES" '
  {
    schemaVersion: 1,
    labSlug: $lab,
    domain: $domain,
    generatedAt: $at,
    generatedBy: "kpi-analyst",
    schema: ($schemaFile[0].kpis // []),
    values: $values
  }')

# ── 3. Index lisible (convention consolidator : index en tête) ──────────────────────────────────
INDEX=$(echo "$PAYLOAD" | jqx -r '
  .schema as $s
  | "| key | label | value | unit | confidence | source |\n|-----|-------|-------|------|------------|--------|\n"
    + ([ .values[] as $v
        | ($s[] | select(.key == $v.key)) as $cfg
        | "| \($v.key) | \($cfg.label // $v.key) | \($v.value) | \($cfg.unit // "") | \($v.confidence) | \($v.source) |"
       ] | join("\n"))')

# ── 4. Émettre KPIS.md ──────────────────────────────────────────────────────────────────────────
mkdir -p "$(dirname "$OUT")"
{
  echo "---"
  echo "registre: KPIS"
  echo "labSlug: $LAB"
  echo "domain: $DOMAIN"
  echo "schemaVersion: 1"
  echo "generatedAt: $GENERATED_AT"
  echo "generatedBy: kpi-analyst"
  echo "---"
  echo
  echo "# KPIS — $LAB"
  echo
  echo "> Registre des indicateurs métier réels. Généré par l'agent \`kpi-analyst\` — **jamais saisi à la"
  echo "> main**. Chaque valeur porte sa \`source\`. Lecture par défaut = l'index ci-dessous."
  echo
  echo "## Index"
  echo
  echo "$INDEX"
  echo
  echo "## Données (source de vérité machine — ingérée par le Hub)"
  echo
  echo '```json'
  echo "$PAYLOAD" | jqx .
  echo '```'
} > "$OUT"

log "écrit : $OUT ($(echo "$VALUES" | jqx 'length') valeur(s), $(echo "$PAYLOAD" | jqx '.schema | length') KPI(s) au schéma)"
