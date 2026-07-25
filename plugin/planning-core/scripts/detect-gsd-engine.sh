#!/usr/bin/env bash
# detect-gsd-engine.sh — Le MOTEUR de planning GSD est-il en place sur ce lab ?
#
# Rôle (ADR-054) : répondre à une question FACTUELLE, jamais à une question de métier.
# Le métier d'un lab relève du JUGEMENT du skill (references/domain-detection.md) — un
# détecteur bash s'y tromperait (un lab de contenu peut avoir un package.json). Ce script
# ne dit donc PAS « ce lab est dev » : il dit « il y a (ou non) un moteur GSD en place »,
# et le skill décide ensuite.
#
# Usage:
#   detect-gsd-engine.sh [--path <dir>] [--quiet]
# Defaults: --path .planning
# Env: GSD_HOME (défaut $HOME/.claude/get-shit-done) — surchargeable pour les tests.
#
# Exit codes, évalués dans CET ordre (le premier qui matche gagne) :
#   1 = chaîne GSD absente de la machine — aucun moteur disponible
#   0 = moteur GSD ACTIF (STATE.md porte gsd_state_version)
#   2 = signalement de MIGRATION (STATE.md de facture planning-core + signaux de code)
#   3 = aucun moteur en place (pas de .planning/, ou socle sans marqueur ni signal de code)
#  64 = argument inconnu
set -uo pipefail

PLANNING_DIR=".planning"
GSD_HOME="${GSD_HOME:-$HOME/.claude/get-shit-done}"
QUIET=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --path) PLANNING_DIR="${2:?--path nécessite une valeur}"; shift 2 ;;
    --quiet) QUIET=1; shift ;;
    -h|--help) grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
    *) echo "[detect-gsd-engine] argument inconnu : $1" >&2; exit 64 ;;
  esac
done

say() { [ "$QUIET" -eq 1 ] || echo "[gsd-engine] $*"; }

# --- Priorité 1 : la chaîne GSD est-elle installée ? ---
if [ ! -d "$GSD_HOME" ]; then
  say "Chaîne GSD absente ($GSD_HOME) — aucun moteur de planning disponible."
  exit 1
fi

STATE_FILE="$PLANNING_DIR/STATE.md"

# --- Priorité 2 : moteur GSD actif ? (marqueur = clé du frontmatter) ---
if [ -f "$STATE_FILE" ] && grep -qE '^gsd_state_version:' "$STATE_FILE" 2>/dev/null; then
  say "Moteur GSD actif — le planning de ce projet appartient à GSD."
  exit 0
fi

# --- Priorité 3 : socle planning-core + signaux de code → migration à examiner ---
# Les signaux de code sont un indice de SURFACE : ils déclenchent un examen, jamais un verdict.
has_code_signal() {
  local f
  for f in package.json go.mod Cargo.toml pyproject.toml pom.xml build.gradle \
           build.gradle.kts composer.json Gemfile tsconfig.json Package.swift; do
    [ -f "./$f" ] && return 0
  done
  # Projet Xcode : dossier *.xcodeproj à la racine.
  for f in ./*.xcodeproj; do [ -d "$f" ] && return 0; done
  return 1
}

if [ -f "$STATE_FILE" ] && grep -qE '^planning_version:' "$STATE_FILE" 2>/dev/null; then
  if has_code_signal; then
    say "Socle de facture planning-core en présence de code — migration à examiner (ne rien réécrire)."
    exit 2
  fi
fi

# --- Priorité 4 : terrain libre — le jugement métier décide seul ---
say "Aucun moteur de planning en place."
exit 3
