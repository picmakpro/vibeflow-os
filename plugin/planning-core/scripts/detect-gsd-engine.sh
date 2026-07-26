#!/usr/bin/env bash
# detect-gsd-engine.sh — Le MOTEUR de planning GSD est-il en place sur ce lab ?
#
# Rôle (ADR-055) : répondre à une question FACTUELLE, jamais à une question de métier.
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

# Fenêtre de compat dual-layout (D-01, 11-CONTEXT.md) : gsd-core (nouveau) prioritaire, legacy
# get-shit-done en repli. Cascade à 4 niveaux, résolue uniquement si GSD_HOME n'est pas déjà
# fourni par l'environnement (préserve les appels qui fixent GSD_HOME explicitement) :
#   1. <projet>/.claude/gsd-core     — scope --local de gsd-core 1.8.0 (payload projet)
#   2. $CLAUDE_CONFIG_DIR|$HOME/.claude/gsd-core — scope --global de gsd-core
#   3. $CLAUDE_CONFIG_DIR|$HOME/.claude/get-shit-done — legacy (pas de variante projet-local :
#      antérieur au scope --local, aucune preuve qu'il ait pu être posé à l'échelle projet)
#   4. défaut — nomme le futur (gsd-core) dans les messages d'erreur, pas le passé
default_gsd_home() {
  local root claude_home
  root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  claude_home="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
  if [ -d "$root/.claude/gsd-core" ]; then
    echo "$root/.claude/gsd-core"
  elif [ -d "$claude_home/gsd-core" ]; then
    echo "$claude_home/gsd-core"
  elif [ -d "$claude_home/get-shit-done" ]; then
    echo "$claude_home/get-shit-done"
  else
    echo "$claude_home/gsd-core"
  fi
}
GSD_HOME="${GSD_HOME:-$(default_gsd_home)}"
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

# Le marqueur du moteur est une clé du FRONTMATTER, pas une chaîne du fichier. Un `grep` non borné
# prendrait un `gsd_state_version:` cité dans le CORPS (bloc d'exemple YAML, doc inline) pour le
# marqueur réel : le script sortirait « moteur actif » sur un socle planning-core, et les deux hooks
# qui le câblent en `&& exit 0` se retireraient à tort. D'où la borne.
# Modèle : extract_frontmatter_field() dans plugin/dev-orchestrator/scripts/build-gsd-index.sh.
# Réimplémenté localement et non sourcé : planning-core ne dépend d'aucun module (`requires: []`).
has_frontmatter_key() { # <file> <key>
  awk -v key="$2" '
    NR == 1 && $0 ~ /^---[[:space:]]*$/   { in_fm = 1; next }
    in_fm && $0 ~ /^---[[:space:]]*$/     { exit }
    in_fm && $0 ~ "^" key ":[[:space:]]*" { found = 1; exit }
    END { exit (found ? 0 : 1) }
  ' "$1"
}

# --- Priorité 2 : moteur GSD actif ? (marqueur = clé du frontmatter) ---
if [ -f "$STATE_FILE" ] && has_frontmatter_key "$STATE_FILE" gsd_state_version; then
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

if [ -f "$STATE_FILE" ] && has_frontmatter_key "$STATE_FILE" planning_version; then
  if has_code_signal; then
    say "Socle de facture planning-core en présence de code — migration à examiner (ne rien réécrire)."
    exit 2
  fi
fi

# --- Priorité 4 : terrain libre — le jugement métier décide seul ---
say "Aucun moteur de planning en place."
exit 3
