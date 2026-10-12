#!/usr/bin/env bash
# compte.sh — imprime le nombre de lignes non vides d'un fichier.
set -eu

if [ "$#" -lt 1 ]; then
  echo "usage: compte.sh <fichier>" >&2
  exit 64
fi

fichier="$1"
grep -c -v '^[[:space:]]*$' "$fichier" || true
