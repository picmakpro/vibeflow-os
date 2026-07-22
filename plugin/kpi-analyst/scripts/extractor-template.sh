#!/usr/bin/env bash
# extractor-template.sh — GABARIT d'extracteur déterministe d'UN KPI.
#
# L'agent kpi-analyst COPIE ce fichier vers .claude/kpi/extractors/<key>.sh et le remplit pour lire
# la source réelle du lab. Un extracteur :
#   - lit UNE ou plusieurs sources DANS le lab (Tier 1 : aucun accès externe) ;
#   - calcule une valeur de façon DÉTERMINISTE (somme, comptage, dernier connu) — AUCUN appel LLM ;
#   - émet EXACTEMENT une ligne JSON sur stdout :
#       {"key":"<key>","value":<number>,"source":"<chemin/section>","confidence":"high|medium|low"}
#
# Règles d'or :
#   - Même entrée → même sortie (idempotence). Pas d'horodatage dans la valeur, pas d'aléa.
#   - JAMAIS inventer : si la source est absente/ambiguë → value=null + confidence="low".
#   - TOUJOURS citer la source (fichier/dossier/section) qui justifie le chiffre.
set -euo pipefail

command -v jq >/dev/null 2>&1 || { echo "[extractor] jq introuvable (requis)" >&2; exit 1; }
# jqx — wrapper jq obligatoire (ADR-052) : neutralise le CRLF du jq Windows natif (mode texte).
jqx() ( set -o pipefail; command jq "$@" | tr -d '\r'; )

# ── À PERSONNALISER ─────────────────────────────────────────────────────────────────────────────
KEY="ca_realise"                       # doit correspondre à une key du schema.json
SOURCE="business/pipeline/clients/"    # chemin/section qui justifie la valeur

# Exemple Tier 1 — somme de montants depuis des fichiers du lab (à adapter au format réel) :
#   value=$(grep -rhoE 'montant:\s*[0-9]+' "$SOURCE" 2>/dev/null | grep -oE '[0-9]+' | paste -sd+ - | bc)
value=""   # ← remplir par le calcul réel

# ── Émission normalisée ─────────────────────────────────────────────────────────────────────────
if [ -z "${value}" ]; then
  # Donnée absente : on NE devine PAS. low + null, à confirmer.
  jqx -nc --arg k "$KEY" --arg s "$SOURCE" '{key:$k, value:null, source:$s, confidence:"low"}'
else
  jqx -nc --arg k "$KEY" --argjson v "$value" --arg s "$SOURCE" \
    '{key:$k, value:$v, source:$s, confidence:"high"}'
fi
