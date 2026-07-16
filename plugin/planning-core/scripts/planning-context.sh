#!/usr/bin/env bash
# planning-context.sh — Injecte un DIGEST planning au démarrage de session (SessionStart).
#
# Rôle (ADR-050) : là où check-planning-state.sh se contente de SIGNALER la fraîcheur,
# ce script INJECTE réellement le contexte planning — en respectant la structuration du
# contexte (index-first, jamais saturant) :
#   - lab À COMPARTIMENTS (.planning/INDEX.md présent) → injecte l'INDEX (compartiments +
#     statut 1 ligne) + une directive « lis le STATE du compartiment ciblé avant d'agir ».
#     Le STATE du bon compartiment est injecté APRÈS, à la tâche, par planning-task-context.sh
#     (UserPromptSubmit) — on ne charge donc jamais tous les compartiments d'un coup.
#   - lab MONO (.planning/STATE.md présent, pas d'INDEX) → injecte un EXTRAIT BORNÉ de STATE.md.
#   - lab non amorcé (pas de .planning/) → rien (check-planning-state.sh porte déjà le rappel).
#
# Sortie = texte markdown sur stdout (ajouté au contexte de session par Claude Code au SessionStart).
# Fail-open : jamais bloquant, toute erreur → exit 0 silencieux.
#
# Usage:
#   planning-context.sh [--path <dir>] [--max-lines <N>]
# Defaults: --path .planning  --max-lines 45
set -uo pipefail

PLANNING_DIR=".planning"
MAX_LINES=45

while [ "$#" -gt 0 ]; do
  case "$1" in
    --path) PLANNING_DIR="${2:-.planning}"; shift 2 ;;
    --max-lines) MAX_LINES="${2:-45}"; shift 2 ;;
    -h|--help) grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
    *) shift ;;
  esac
done

# Pas de socle → rien à injecter (le rappel "non amorcé" vient de check-planning-state.sh).
[ -d "$PLANNING_DIR" ] || exit 0

INDEX_FILE="$PLANNING_DIR/INDEX.md"
STATE_FILE="$PLANNING_DIR/STATE.md"

if [ -f "$INDEX_FILE" ]; then
  # --- Lab à compartiments : index-first ---
  echo "## 📍 Contexte planning (injecté — lab à compartiments)"
  echo ""
  echo "Voici l'INDEX des compartiments du lab. **Avant d'agir sur un compartiment, lis d'abord son"
  echo "\`.planning/STATE.md\`** (borné) — ne charge pas tous les compartiments d'un coup (structuration"
  echo "du contexte). Le STATE du compartiment ciblé te sera injecté automatiquement quand ta tâche sera connue."
  echo ""
  echo '```'
  head -n 80 "$INDEX_FILE"
  echo '```'
  exit 0
fi

if [ -f "$STATE_FILE" ]; then
  # --- Lab mono : injecter un extrait borné de STATE.md ---
  total=$(wc -l < "$STATE_FILE" | tr -d ' ')
  echo "## 📍 Contexte planning (injecté — STATE.md, extrait borné)"
  echo ""
  echo "État courant du lab (${MAX_LINES} premières lignes sur ${total} — lis le reste à la demande) :"
  echo ""
  echo '```'
  head -n "$MAX_LINES" "$STATE_FILE"
  echo '```'
  [ "$total" -gt "$MAX_LINES" ] && echo "_(…tronqué — \`Read $STATE_FILE\` pour la suite.)_"
  exit 0
fi

# .planning/ existe mais ni INDEX ni STATE : laisser check-planning-state.sh signaler.
exit 0
