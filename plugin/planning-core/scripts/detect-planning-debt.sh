#!/usr/bin/env bash
# detect-planning-debt.sh — Détecte les compartiments en DETTE DE PLANNING dans un lab.
#
# Rôle (advisory, jamais bloquant — 8e signal de dette, planning-core v2) :
# Un compartiment est en dette s'il satisfait LES TROIS conditions :
#   1. ACTIF        — activité récente (fichier modifié dans la fenêtre --active-window)
#   2. SANS PLAN    — ni .planning/, ni STATE.md/BOARD.md/ROADMAP.md/PLAN.md à sa racine
#   3. AU-DESSUS DU SEUIL D'AUTONOMIE — volume ≥ --min-tasks fichiers (proxy de complexité)
#
# Philosophie : on n'impose PAS un plan partout (sur-ingénierie). On signale seulement les
# compartiments qui en MÉRITENT un et n'en ont pas. Alerte → l'agent propose /vf-planning.
# Cf. references/compartments.md § 3 (seuil) et § 5 (INDEX).
#
# Usage:
#   detect-planning-debt.sh [--root <dir>] [--active-window <N>] [--min-tasks <N>] [--quiet]
# Defaults: --root projects  --active-window 14  --min-tasks 5
#
# Exit codes (pour un hook/validator qui veut router) :
#   0 = aucune dette détectée
#   1 = au moins un compartiment en dette de planning (advisory)
#   3 = racine des compartiments absente (lab probablement mono-objectif → rien à faire)
set -uo pipefail

ROOT="projects"
ACTIVE_WINDOW=14
MIN_TASKS=5
QUIET=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --root) ROOT="${2:?--root nécessite une valeur}"; shift 2 ;;
    --active-window) ACTIVE_WINDOW="${2:?--active-window nécessite une valeur}"; shift 2 ;;
    --min-tasks) MIN_TASKS="${2:?--min-tasks nécessite une valeur}"; shift 2 ;;
    --quiet) QUIET=1; shift ;;
    -h|--help) grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
    *) echo "[detect-planning-debt] argument inconnu : $1" >&2; exit 64 ;;
  esac
done

say() { [ "$QUIET" -eq 1 ] || echo "[planning-debt] $*"; }

if [ ! -d "$ROOT" ]; then
  say "Racine '$ROOT/' absente — lab mono-objectif ou compartiments ailleurs. Rien à signaler."
  exit 3
fi

# --- mtime portable (BSD macOS / GNU Linux) ---
file_mtime() {
  stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null
}
now_epoch() { date +%s; }

# Plus récent mtime d'un dossier (hors .git), 0 si vide.
newest_mtime() {
  local dir="$1" newest=0 m
  while IFS= read -r f; do
    m=$(file_mtime "$f"); [ -n "$m" ] || continue
    [ "$m" -gt "$newest" ] && newest="$m"
  done < <(find "$dir" -type f -not -path '*/.git/*' 2>/dev/null)
  echo "$newest"
}

has_plan() {
  local dir="$1"
  [ -d "$dir/.planning" ] && return 0
  for f in STATE.md BOARD.md ROADMAP.md PLAN.md; do
    [ -f "$dir/$f" ] && return 0
  done
  return 1
}

NOW=$(now_epoch)
debt_found=0
debt_list=""

for dir in "$ROOT"/*/; do
  [ -d "$dir" ] || continue
  name=$(basename "$dir")

  # 3. Volume (seuil d'autonomie) — proxy : nb de fichiers hors .git
  files=$(find "$dir" -type f -not -path '*/.git/*' 2>/dev/null | wc -l | tr -d ' ')
  [ "$files" -ge "$MIN_TASKS" ] || continue

  # 2. Sans plan ?
  if has_plan "$dir"; then continue; fi

  # 1. Actif ? (activité dans la fenêtre)
  nm=$(newest_mtime "$dir")
  [ "$nm" -gt 0 ] || continue
  age_days=$(( (NOW - nm) / 86400 ))
  [ "$age_days" -le "$ACTIVE_WINDOW" ] || continue

  debt_found=1
  debt_list="${debt_list}  - ${dir%/} — actif (dernière activité il y a ${age_days}j), ${files} fichiers, AUCUN plan → typer (deliverable/continuous) + /vf-planning"$'\n'
done

if [ "$debt_found" -eq 1 ]; then
  say "Compartiments en dette de planning (actifs, au-dessus du seuil, sans plan) :"
  [ "$QUIET" -eq 1 ] || printf '%s' "$debt_list"
  exit 1
fi

say "OK — aucun compartiment en dette de planning (racine '$ROOT/', seuil ${MIN_TASKS} fichiers, fenêtre ${ACTIVE_WINDOW}j)."
exit 0
