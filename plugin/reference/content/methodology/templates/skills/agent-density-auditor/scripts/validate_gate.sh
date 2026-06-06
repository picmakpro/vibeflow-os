#!/usr/bin/env bash
# validate_gate.sh — Gate de validation ADR-029 pour un agent.
# Usage: bash validate_gate.sh <path-to-agent.md>
# Exit: 0 = conforme | 1 = violation bloquante
# Utilise par hook PreToolUse (Edit|Write sur .claude/agents/*.md) et Initializer.

set -u

# Seuils ADR-029
MAX_BODY_LINES=250
MAX_DESCRIPTION_CHARS=1024
MAX_SECTION_LINES=100

VIOLATIONS=0
WARNINGS=0

err() { echo "VIOLATION: $*" >&2; VIOLATIONS=$((VIOLATIONS + 1)); }
warn() { echo "WARNING: $*" >&2; WARNINGS=$((WARNINGS + 1)); }
ok() { echo "OK: $*" >&2; }

main() {
  if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <path-to-agent.md>" >&2
    exit 1
  fi

  local file="$1"

  if [[ ! -f "$file" ]]; then
    err "Fichier introuvable : $file"
    exit 1
  fi

  # 1. Calculer lignes body (hors frontmatter)
  local total_lines body_lines end_fm
  total_lines=$(wc -l < "$file" | tr -d ' ')
  end_fm=$(awk 'BEGIN{c=0} /^---[[:space:]]*$/{c++; if(c==2){print NR; exit}}' "$file")

  if [[ -z "$end_fm" ]]; then
    warn "Pas de frontmatter YAML detecte — agent atypique"
    body_lines=$total_lines
  else
    body_lines=$(( total_lines - end_fm ))
  fi

  # 2. Check lignes body
  if (( body_lines > MAX_BODY_LINES )); then
    err "Prompt systeme trop long : $body_lines lignes (max $MAX_BODY_LINES selon ADR-029). Lancer plan_migration.py."
  else
    ok "Lignes body : $body_lines / $MAX_BODY_LINES"
  fi

  # 3. Extraire frontmatter pour analyse
  if [[ -n "$end_fm" ]]; then
    local fm_content
    fm_content=$(sed -n "2,$((end_fm - 1))p" "$file")

    # 3a. Description ≤ 1024 chars
    local desc_line desc_chars
    desc_line=$(echo "$fm_content" | grep -E '^description:' | head -n 1 || true)
    if [[ -n "$desc_line" ]]; then
      # Supporte description sur plusieurs lignes (YAML | ou >) approximativement : prendre juste la ligne directe
      desc_chars=$(( ${#desc_line} - 13 ))  # "description: " = 13 chars
      if (( desc_chars > MAX_DESCRIPTION_CHARS )); then
        err "Description frontmatter trop longue : $desc_chars chars (max $MAX_DESCRIPTION_CHARS)"
      else
        ok "Description : $desc_chars / $MAX_DESCRIPTION_CHARS chars"
      fi
    else
      warn "Pas de champ 'description' dans le frontmatter"
    fi

    # 3b. skills natif Claude Code declare (ADR-030 revisee 2026-05-17)
    # Convention officielle Claude Code : champ 'skills:' liste flat des skills preCharges.
    # Cf. https://code.claude.com/docs/en/subagents.md
    if echo "$fm_content" | grep -qE '^skills:'; then
      ok "Frontmatter declare 'skills:' (champ natif Claude Code)"
    else
      warn "Frontmatter ne declare pas 'skills:' (ADR-030 : champ natif pour preCharger des skills a l'invocation)"
    fi

    # 3c. Detection de l'ancienne convention inventee (ADR-030 v1, deprecated 2026-05-17)
    if echo "$fm_content" | grep -qE '^bootstrap_skills:'; then
      warn "Frontmatter utilise 'bootstrap_skills:' (deprecated ADR-031, champ non lu par Claude Code) — migrer vers 'skills:' natif"
    fi
    if echo "$fm_content" | grep -qE '^on_demand_skills:'; then
      warn "Frontmatter utilise 'on_demand_skills:' (deprecated ADR-031, champ non lu par Claude Code) — supprimer (skills non listes = invocables via Skill tool/description match)"
    fi
  fi

  # 4. Detecter sections trop longues (signal extraction necessaire)
  # Une section va d'un heading L1/L2/L3 au prochain heading ou EOF
  local longest_section
  longest_section=$(awk '
    BEGIN { count = 0; max = 0; title = ""; current_title = "" }
    /^#{1,3}[[:space:]]/ {
      if (count > max) { max = count; title = current_title }
      current_title = $0
      count = 0
      next
    }
    { count++ }
    END {
      if (count > max) { max = count; title = current_title }
      print max "|" title
    }
  ' "$file")

  local longest_lines longest_title
  longest_lines=$(echo "$longest_section" | cut -d'|' -f1)
  longest_title=$(echo "$longest_section" | cut -d'|' -f2-)

  if (( longest_lines > MAX_SECTION_LINES )); then
    warn "Section unique trop longue : $longest_lines lignes ($longest_title) — candidat extraction"
  fi

  # 5. Verdict final
  echo "----"
  if (( VIOLATIONS > 0 )); then
    echo "GATE FAILED : $VIOLATIONS violation(s), $WARNINGS warning(s)" >&2
    echo "Action : lancer plan_migration.py puis appliquer la migration" >&2
    exit 1
  fi

  if (( WARNINGS > 0 )); then
    echo "GATE PASSED avec $WARNINGS warning(s) — non bloquant" >&2
  else
    echo "GATE PASSED — agent conforme ADR-029" >&2
  fi
  exit 0
}

main "$@"
