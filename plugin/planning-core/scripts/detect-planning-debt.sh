#!/usr/bin/env bash
# detect-planning-debt.sh — Détecte les compartiments en DETTE DE PLANNING dans un lab.
#
# Rôle (advisory, jamais bloquant — 8e signal de dette, planning-core v2) :
# Un compartiment est en dette s'il satisfait LES TROIS conditions :
#   1. ACTIF        — activité récente (fichier modifié dans la fenêtre --active-window)
#   2. SANS PLAN    — ni .planning/, ni STATE.md/BOARD.md/ROADMAP.md/PLAN.md à sa racine
#   3. AU-DESSUS DU SEUIL D'AUTONOMIE — volume ≥ --min-tasks fichiers (proxy de complexité)
# Les dossiers vendorés/générés (.git, node_modules, .venv, vendor, dist, build, .next) sont
# ÉLAGUÉS : ils ne comptent ni dans le volume ni dans l'activité (un npm install ≠ du travail).
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

# --- find borné : élaguer les dossiers vendorés/générés AVANT la descente (-prune, pas filtre post).
# POURQUOI : un node_modules réel = des dizaines de milliers de fichiers → gel du SessionStart
# (hook tué au timeout) + effets sémantiques (fichiers vendorés comptés dans --min-tasks,
# npm install récent rendant le compartiment « actif »). Ce hook doit rester quasi instantané.
# Expansion NON quotée voulue aux sites d'appel (mots fixes sans espace, `(` passé en argument à find).
PRUNE_VENDOR='( -type d ( -name .git -o -name node_modules -o -name .venv -o -name vendor -o -name dist -o -name build -o -name .next ) ) -prune'

has_plan() {
  local dir="$1"
  [ -d "$dir/.planning" ] && return 0
  for f in STATE.md BOARD.md ROADMAP.md PLAN.md; do
    [ -f "$dir/$f" ] && return 0
  done
  return 1
}

debt_found=0
debt_list=""

for dir in "$ROOT"/*/; do
  [ -d "$dir" ] || continue

  # 2. Sans plan ? — test O(1), le moins cher : éliminer d'abord sans aucun parcours.
  if has_plan "$dir"; then continue; fi

  # 3. Volume (seuil d'autonomie) — early-exit : on veut seulement savoir si ≥ MIN_TASKS,
  #    head coupe le flux dès le seuil atteint (jamais de comptage exhaustif de l'arbre).
  files=$(find "$dir" $PRUNE_VENDOR -o -type f -print 2>/dev/null | head -n "$MIN_TASKS" | wc -l | tr -d ' ')
  [ "$files" -ge "$MIN_TASKS" ] || continue

  # 1. Actif ? — O(1) : l'EXISTENCE d'un fichier modifié dans la fenêtre suffit,
  #    head -n 1 stoppe find au premier trouvé (aucun stat spawné par fichier).
  recent=$(find "$dir" $PRUNE_VENDOR -o -type f -mtime -"$ACTIVE_WINDOW" -print 2>/dev/null | head -n 1)
  [ -n "$recent" ] || continue

  debt_found=1
  debt_list="${debt_list}  - ${dir%/} — actif (activité < ${ACTIVE_WINDOW}j), ≥ ${MIN_TASKS} fichiers, AUCUN plan → typer (deliverable/continuous) + /vf-planning"$'\n'
done

if [ "$debt_found" -eq 1 ]; then
  say "Compartiments en dette de planning (actifs, au-dessus du seuil, sans plan) :"
  [ "$QUIET" -eq 1 ] || printf '%s' "$debt_list"
  exit 1
fi

say "OK — aucun compartiment en dette de planning (racine '$ROOT/', seuil ${MIN_TASKS} fichiers, fenêtre ${ACTIVE_WINDOW}j)."
exit 0
