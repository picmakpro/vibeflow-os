#!/usr/bin/env bash
# check-planning-state.sh — Vérifie la fraîcheur du socle .planning/ d'un lab.
#
# Rôle (moteur léger, universel, sans dépendance dev) : c'est le garde-fou de la CLÉ DE VOÛTE.
# Il répond à deux questions, de façon advisory (jamais bloquant) :
#   1. Le lab a-t-il un socle .planning/ ? (sinon → suggérer /vf-planning pour l'amorcer)
#   2. STATE.md est-il frais ? (un STATE périmé est pire que pas de STATE)
#
# Conçu pour 3 usages :
#   - manuel :        check-planning-state.sh
#   - au /checkpoint : intégré dans l'audit de cohérence
#   - en hook :       SessionStart → surface un rappel si STATE absent/périmé.
#     (Depuis ADR-043 : câblé AUTOMATIQUEMENT dans settings.json à l'install du module
#      via hooks/hooks.json + merge-hooks.sh — advisory, jamais bloquant, `|| true`.)
#
# Usage:
#   check-planning-state.sh [--path <dir>] [--max-age-days <N>] [--quiet] [--defer-to-gsd]
# Defaults: --path .planning  --max-age-days 7
#
# --defer-to-gsd (ADR-054) : opt-in, câblé dans hooks.json uniquement. Si le moteur GSD est
# actif sur ce projet, gsd-session-state.sh porte déjà le signal de fraîcheur → on se retire
# en silence (exit 0). SANS ce flag, le comportement est strictement inchangé.
#
# Exit codes (pour un hook qui veut router) :
#   0 = OK (frais)        1 = STATE périmé        2 = STATE absent
#   3 = .planning/ absent (lab non amorcé)
set -uo pipefail

PLANNING_DIR=".planning"
MAX_AGE_DAYS=7
QUIET=0
DEFER_TO_GSD=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --path) PLANNING_DIR="${2:?--path nécessite une valeur}"; shift 2 ;;
    --max-age-days) MAX_AGE_DAYS="${2:?--max-age-days nécessite une valeur}"; shift 2 ;;
    --quiet) QUIET=1; shift ;;
    --defer-to-gsd) DEFER_TO_GSD=1; shift ;;
    -h|--help) grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
    *) echo "[check-planning-state] argument inconnu : $1" >&2; exit 64 ;;
  esac
done

say() { [ "$QUIET" -eq 1 ] || echo "[planning-state] $*"; }

# --- ADR-054 : ne pas doubler le digest de GSD ---
# Si le moteur GSD est actif, gsd-session-state.sh porte déjà le signal de fraîcheur de ce
# projet : on se retire en silence (exit 0). Appelé avec --defer-to-gsd depuis hooks.json
# uniquement — l'usage manuel et le /checkpoint gardent le comportement complet.
if [ "$DEFER_TO_GSD" -eq 1 ]; then
  DETECT="$(dirname "$0")/detect-gsd-engine.sh"
  if [ -f "$DETECT" ]; then
    bash "$DETECT" --quiet --path "$PLANNING_DIR" && exit 0
  fi
fi

# --- Conversion YYYY-MM-DD → epoch, portable BSD (macOS) ET GNU (Linux) ---
date_to_epoch() {
  local d="$1"
  date -j -f "%Y-%m-%d" "$d" +%s 2>/dev/null || date -d "$d" +%s 2>/dev/null
}
today_epoch() { date +%s; }

# 1. Socle présent ?
if [ ! -d "$PLANNING_DIR" ]; then
  say "Aucun socle $PLANNING_DIR/ — lab non amorcé. Invoquer /vf-planning pour le mettre en place."
  exit 3
fi

STATE_FILE="$PLANNING_DIR/STATE.md"
# 2. STATE présent ? (clé de voûte)
if [ ! -f "$STATE_FILE" ]; then
  say "$PLANNING_DIR/ existe mais STATE.md (clé de voûte) est ABSENT. Le recréer via /vf-planning."
  exit 2
fi

# 3. Fraîcheur : lire last_updated dans le frontmatter YAML.
# Extraction par grep -oE (tolère les dates non paddées type 2026-7-5) : l'ancien sed
# laissait passer la LIGNE ENTIÈRE quand la date ne matchait pas → message d'erreur confus
# (« Impossible de parser last_updated='last_updated: 2026-7-5' »).
raw_date=$(grep -m1 '^last_updated:' "$STATE_FILE" | grep -oE '[0-9]{4}-[0-9]{1,2}-[0-9]{1,2}' | head -1)

if [ -z "$raw_date" ]; then
  say "STATE.md présent mais sans 'last_updated' lisible (YYYY-MM-DD). Ajouter le champ au frontmatter."
  exit 1
fi

# Normaliser en YYYY-MM-DD (zéro-padding mois/jour) — 10# force la base 10 (piège octal de 08/09).
y=${raw_date%%-*}; md=${raw_date#*-}; m=${md%%-*}; d=${md#*-}
last_updated=$(printf '%04d-%02d-%02d' "$((10#$y))" "$((10#$m))" "$((10#$d))")

ep_then=$(date_to_epoch "$last_updated")
ep_now=$(today_epoch)
if [ -z "$ep_then" ]; then
  say "Impossible de parser last_updated='$last_updated' (valeur extraite : '$raw_date'). Vérifier le format YYYY-MM-DD."
  exit 1
fi

age_days=$(( (ep_now - ep_then) / 86400 ))
if [ "$age_days" -gt "$MAX_AGE_DAYS" ]; then
  say "STATE.md périmé : $age_days j depuis la dernière maj ($last_updated, seuil ${MAX_AGE_DAYS}j). Le rafraîchir."
  exit 1
fi

say "OK — STATE.md frais ($age_days j ≤ ${MAX_AGE_DAYS}j, maj $last_updated)."
exit 0
