#!/usr/bin/env bash
# build-gsd-index.sh — Générateur d'index factuel des skills GSD installés (dev-orchestrator)
#
# Iron Law (D4 — anti-hallucination) : aucun nom de skill n'est écrit en dur.
# L'index est exclusivement extrait du frontmatter des SKILL.md présents sur disque.
#
# Usage:
#   ./build-gsd-index.sh                      # écrit l'index dans references/ (défaut dev)
#   VF_INDEX_OUT=/chemin/index.md ./build-gsd-index.sh   # écrit à un chemin arbitraire (D7, hook post-install)
#   VF_GSD_SKILLS_DIR=/tmp/fixtures ./build-gsd-index.sh # source surchargeable (tests)
#
# Variables d'environnement :
#   VF_GSD_SKILLS_DIR (défaut $HOME/.claude/skills) — racine des skills à scanner
#   VF_INDEX_OUT      (défaut references/gsd-skills-index.md) — fichier de sortie ; dossier parent créé si besoin
#
# Comportement : idempotent (overwrite complet à chaque run). Si aucun skill gsd-* trouvé,
# écrit un header avec message clair et exit 0 (l'index sera régénéré après install GSD).
#
# Référence : IDX-01 (index factuel), IDX-02 (ré-exécutable + paramétrable), D4, D7

set -euo pipefail

# ---------- Variables ----------
SKILLS_DIR="${VF_GSD_SKILLS_DIR:-$HOME/.claude/skills}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUT="${VF_INDEX_OUT:-$SCRIPT_DIR/../references/gsd-skills-index.md}"

# Fenêtre de compat dual-layout (D-01, 11-CONTEXT.md), même cascade que detect-gsd-engine.sh :
# projet-local gsd-core > $CLAUDE_CONFIG_DIR|$HOME gsd-core > legacy get-shit-done > défaut.
# VF_GSD_WORKFLOWS_DIR explicite reste toujours prioritaire (source surchargeable pour les tests).
default_workflows_dir() {
  local root claude_home
  root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  claude_home="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
  if [ -d "$root/.claude/gsd-core/workflows" ]; then
    echo "$root/.claude/gsd-core/workflows"
  elif [ -d "$claude_home/gsd-core/workflows" ]; then
    echo "$claude_home/gsd-core/workflows"
  elif [ -d "$claude_home/get-shit-done/workflows" ]; then
    echo "$claude_home/get-shit-done/workflows"
  else
    echo "$claude_home/gsd-core/workflows"
  fi
}
WORKFLOWS_DIR="${VF_GSD_WORKFLOWS_DIR:-$(default_workflows_dir)}"

# ---------- Helpers ----------
log() {
  echo "[build-gsd-index.sh] $*" >&2
}

# Extrait la valeur d'un champ frontmatter (name / description) d'un SKILL.md.
# Lit uniquement le bloc frontmatter (jusqu'au 2e délimiteur ---) et strip les guillemets.
extract_frontmatter_field() {
  local file="$1" field="$2"
  awk -v field="$field" '
    NR == 1 && $0 ~ /^---[[:space:]]*$/ { in_fm = 1; next }
    in_fm && $0 ~ /^---[[:space:]]*$/   { exit }
    in_fm {
      # match "field:" en début de ligne
      if ($0 ~ "^" field ":[[:space:]]*") {
        sub("^" field ":[[:space:]]*", "", $0)
        print $0
        exit
      }
    }
  ' "$file"
}

# Retire les guillemets simples/doubles englobants et les pipes (sécurité table markdown).
clean_value() {
  local v="$1"
  v="${v%\"}"; v="${v#\"}"
  v="${v%\'}"; v="${v#\'}"
  v="${v//|/\\|}"
  # trim trailing whitespace
  v="${v%"${v##*[![:space:]]}"}"
  printf '%s' "$v"
}

# ---------- Génération de l'index ----------
mkdir -p "$(dirname "$OUT")"

generated_at="$(date -Iseconds 2>/dev/null || date "+%Y-%m-%dT%H:%M:%S%z")"

# Collecte des lignes de table dans un tmp (pour compter avant d'écrire l'en-tête).
rows_tmp="$(mktemp)"
trap 'rm -f "$rows_tmp"' EXIT

skill_count=0
shopt -s nullglob
for skill_md in "$SKILLS_DIR"/gsd-*/SKILL.md; do
  name="$(extract_frontmatter_field "$skill_md" "name")"
  desc="$(extract_frontmatter_field "$skill_md" "description")"
  # Fallback du nom : dossier parent si frontmatter sans name
  if [ -z "$name" ]; then
    name="$(basename "$(dirname "$skill_md")")"
  fi
  name="$(clean_value "$name")"
  desc="$(clean_value "$desc")"
  [ -z "$desc" ] && desc="—"
  printf '| %s | %s |\n' "$name" "$desc" >> "$rows_tmp"
  skill_count=$((skill_count + 1))
done
shopt -u nullglob

# ---------- Écriture de la sortie ----------
{
  echo "# GSD Skills Index (auto-généré — NE PAS ÉDITER)"
  echo "> Généré le $generated_at par build-gsd-index.sh depuis $SKILLS_DIR/gsd-*"
  echo ""
  if [ "$skill_count" -eq 0 ]; then
    echo "_Aucun skill \`gsd-*\` trouvé sur disque. L'index sera régénéré après installation des skills GSD._"
  else
    echo "| Skill | Description |"
    echo "|-------|-------------|"
    sort "$rows_tmp"
  fi

  # Source secondaire optionnelle : workflows GSD (facultatif, ne bloque pas si absent).
  if [ -d "$WORKFLOWS_DIR" ]; then
    shopt -s nullglob
    workflows=("$WORKFLOWS_DIR"/*.md)
    shopt -u nullglob
    if [ "${#workflows[@]}" -gt 0 ]; then
      echo ""
      echo "## Workflows GSD (source secondaire)"
      echo ""
      for wf in "${workflows[@]}"; do echo "- $(basename "$wf" .md)"; done | sort
    fi
  fi
} > "$OUT"

log "Index généré : $OUT ($skill_count skill(s) gsd-*)"
