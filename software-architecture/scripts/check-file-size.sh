#!/usr/bin/env bash
# check-file-size.sh — Gate de taille de fichier (doctrine Architecture Logicielle AI-Safe, ADR-035)
#
# Iron Law : aucun fichier de code > 300 lignes sans plan de découpe.
#
# Usage:
#   check-file-size.sh --staged          # vérifie les fichiers de code indexés (git, pre-commit)
#   check-file-size.sh --all             # scanne src/ app/ lib/ features/
#   check-file-size.sh <file> [file...]  # vérifie des fichiers précis
#
# Seuils (surchargables par variables d'environnement) :
#   VF_ARCH_WARN  (défaut 250)  — avertissement
#   VF_ARCH_BLOCK (défaut 300)  — blocage (exit 2)
#
# Échappatoire (à tracer en dette) : ajouter dans les 5 premières lignes du fichier
#   le marqueur  vibeflow:allow-large-file
# Le fichier est alors ignoré par le gate (warning seulement).
#
# Codes de sortie : 0 = OK (ou warnings) · 2 = blocage (au moins un fichier dépasse BLOCK)

set -euo pipefail

WARN="${VF_ARCH_WARN:-250}"
BLOCK="${VF_ARCH_BLOCK:-300}"
CODE_EXT_RE='\.(ts|tsx|js|jsx|mjs|cjs|py|go|rb|java|kt|swift|rs|php)$'
SCAN_DIRS=(src app lib features)

violations=0
warnings=0

is_code_file() { [[ "$1" =~ $CODE_EXT_RE ]]; }

has_optout() {
  # marqueur dans les 5 premières lignes
  head -n 5 "$1" 2>/dev/null | grep -q 'vibeflow:allow-large-file'
}

check_one() {
  local f="$1"
  [ -f "$f" ] || return 0
  is_code_file "$f" || return 0
  local n
  n=$(wc -l < "$f" | tr -d ' ')
  if [ "$n" -ge "$BLOCK" ]; then
    if has_optout "$f"; then
      echo "  ⚠ $f : $n lignes (≥ $BLOCK) — toléré (marqueur vibeflow:allow-large-file = DETTE)"
      warnings=$((warnings + 1))
    else
      echo "  ✗ $f : $n lignes (≥ $BLOCK) — BLOCAGE : découper (SRP) ou tracer la dette"
      violations=$((violations + 1))
    fi
  elif [ "$n" -ge "$WARN" ]; then
    echo "  ⚠ $f : $n lignes (≥ $WARN) — surveiller, approche du seuil de découpe"
    warnings=$((warnings + 1))
  fi
}

collect_staged() {
  git diff --cached --name-only --diff-filter=ACM 2>/dev/null || true
}

collect_all() {
  local d
  for d in "${SCAN_DIRS[@]}"; do
    [ -d "$d" ] && find "$d" -type f 2>/dev/null
  done
}

main() {
  local files=()
  case "${1:-}" in
    --staged) mapfile -t files < <(collect_staged) ;;
    --all)    mapfile -t files < <(collect_all) ;;
    "")       echo "Usage: check-file-size.sh --staged | --all | <file...>" >&2; exit 0 ;;
    *)        files=("$@") ;;
  esac

  echo "[check-file-size] seuils : warn ≥ $WARN, block ≥ $BLOCK"
  local f
  for f in "${files[@]:-}"; do
    [ -n "$f" ] && check_one "$f"
  done

  if [ "$violations" -gt 0 ]; then
    echo "[check-file-size] ✗ $violations fichier(s) au-dessus de $BLOCK lignes. Découper avant de continuer."
    exit 2
  fi
  echo "[check-file-size] ✓ OK ($warnings avertissement(s))"
}

main "$@"
