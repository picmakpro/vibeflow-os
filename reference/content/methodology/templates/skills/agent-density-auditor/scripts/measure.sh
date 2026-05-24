#!/usr/bin/env bash
# measure.sh — Mesure la densite d'un agent ou d'un dossier d'agents
# Usage:
#   bash measure.sh <path-to-agent.md>
#   bash measure.sh <path-to-directory>
# Output: tableau densite (lignes totales, lignes hors frontmatter, tokens estimes, statut)
# Idempotent, read-only, exit 0.

set -u

# Seuils ADR-029
THRESHOLD_OK=200
THRESHOLD_WARN=250
THRESHOLD_HEAVY=400
TOKENS_PER_LINE=12  # estimation conservative

measure_file() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    printf "%-60s  %s\n" "$file" "NOT_FOUND"
    return 0
  fi

  local total_lines body_lines tokens_est status

  total_lines=$(wc -l < "$file" | tr -d ' ')

  # Detect end of YAML frontmatter (second --- line)
  local end_fm
  end_fm=$(awk 'BEGIN{c=0} /^---[[:space:]]*$/{c++; if(c==2){print NR; exit}}' "$file")
  if [[ -n "$end_fm" ]]; then
    body_lines=$(( total_lines - end_fm ))
  else
    body_lines=$total_lines
  fi

  tokens_est=$(( body_lines * TOKENS_PER_LINE ))

  if   (( body_lines <= THRESHOLD_OK ));    then status="OK"
  elif (( body_lines <= THRESHOLD_WARN ));  then status="WARN"
  elif (( body_lines <= THRESHOLD_HEAVY )); then status="HEAVY"
  else                                            status="CRITICAL"
  fi

  printf "%-60s  %6d  %6d  %8d  %s\n" "$file" "$total_lines" "$body_lines" "$tokens_est" "$status"
}

print_header() {
  printf "%-60s  %6s  %6s  %8s  %s\n" "PATH" "LINES" "BODY" "TOKENS" "STATUS"
  printf "%s\n" "------------------------------------------------------------------------------------------------------"
}

print_footer() {
  printf "%s\n" "------------------------------------------------------------------------------------------------------"
  printf "Seuils ADR-029 : OK ≤%d / WARN ≤%d / HEAVY ≤%d / CRITICAL >%d (lignes hors frontmatter)\n" \
    "$THRESHOLD_OK" "$THRESHOLD_WARN" "$THRESHOLD_HEAVY" "$THRESHOLD_HEAVY"
  printf "Tokens estimes = lignes_body × %d (estimation conservative)\n" "$TOKENS_PER_LINE"
}

main() {
  if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <path-to-agent.md | path-to-directory>" >&2
    exit 0
  fi

  local target="$1"

  if [[ -d "$target" ]]; then
    print_header
    # Find all .md files in directory (non recursive prefere pour .claude/agents/)
    while IFS= read -r -d '' f; do
      measure_file "$f"
    done < <(find "$target" -maxdepth 2 -type f -name '*.md' -print0 | sort -z)
    print_footer
  elif [[ -f "$target" ]]; then
    print_header
    measure_file "$target"
    print_footer
  else
    echo "Path not found: $target" >&2
    exit 0
  fi
}

main "$@"
