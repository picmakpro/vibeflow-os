#!/usr/bin/env bash
# generate-agent-commands.sh — Génère une commande slash d'INCARNATION par agent posé.
#
# Problème résolu : un agent invoqué via `Task`/`@agent` tourne dans une SOUS-FENÊTRE isolée.
# On veut une commande `/agent` qui INCARNE l'agent dans la FENÊTRE PRINCIPALE (session courante),
# auto-générée à chaque init. La commande générée référence `@.claude/agents/<agent>.md` : son
# contenu est inliné au runtime → incarnation, pas délégation.
#
# Usage:
#   ./generate-agent-commands.sh                       # balaye TOUS les agents (mode init/sweep)
#   ./generate-agent-commands.sh --agent <name>        # génère la commande d'UN seul agent
#   ./generate-agent-commands.sh --agents-dir D --commands-dir C
#
# Scope : par défaut, lit VF_TARGET_ROOT (défaut .claude) → agents-dir=$ROOT/agents, commands-dir=$ROOT/commands.
#
# Garde-fous :
#   - IDEMPOTENT : ne JAMAIS écraser une commande existante (customisation utilisateur préservée).
#   - Best-effort : un agent illisible ne fait pas échouer le balayage.

set -euo pipefail

ROOT="${VF_TARGET_ROOT:-.claude}"
AGENTS_DIR="$ROOT/agents"
COMMANDS_DIR="$ROOT/commands"
ONLY_AGENT=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --agent)        ONLY_AGENT="$2"; shift 2 ;;
    --agent=*)      ONLY_AGENT="${1#--agent=}"; shift ;;
    --agents-dir)   AGENTS_DIR="$2"; shift 2 ;;
    --agents-dir=*) AGENTS_DIR="${1#--agents-dir=}"; shift ;;
    --commands-dir)   COMMANDS_DIR="$2"; shift 2 ;;
    --commands-dir=*) COMMANDS_DIR="${1#--commands-dir=}"; shift ;;
    *) echo "[gen-cmd] argument inconnu : $1" >&2; exit 2 ;;
  esac
done

log() { echo "[gen-cmd] $*" >&2; }

# Émet le corps d'une commande d'incarnation pour l'agent <name>.
# Le corps référence @<agents-dir>/<name>.md (inliné au runtime) + ordonne l'incarnation
# dans la session courante, SANS sous-agent Task.
emit_command() {
  local name="$1" agent_file="$2" desc ref_dir
  # Réutiliser la description de l'agent si présente (1re ligne `description:` du frontmatter).
  desc="$(grep -m1 '^description:' "$agent_file" 2>/dev/null | sed 's/^description:[[:space:]]*//; s/^["'\'']//; s/["'\'']$//')"
  [ -n "$desc" ] || desc="Incarne l'agent $name."
  # Référence @ canonique : tout chemin ".../.claude/agents" → ".claude/agents" (forme projet-relative
  # utilisée partout dans le produit, résolue au runtime quel que soit le scope).
  ref_dir="$AGENTS_DIR"
  case "$ref_dir" in
    */.claude/agents|./.claude/agents|.claude/agents) ref_dir=".claude/agents" ;;
    *) ref_dir="${ref_dir#./}" ;;
  esac
  cat <<EOF
---
description: "Incarne l'agent $name dans la fenêtre principale (session courante) — $desc"
argument-hint: "[ta demande pour $name]"
---

Adopte intégralement le rôle, les contraintes et le protocole de l'agent **$name** défini ci-dessous,
et tiens ce rôle pour le reste de CETTE session — dans la **fenêtre principale**, **sans** déléguer
à un sous-agent Task. Tu *es* cet agent pour la suite de l'échange.

@$ref_dir/$name.md

Demande de l'utilisateur : \$ARGUMENTS

Si la demande est vide, salue brièvement dans le rôle de **$name** et demande sur quoi travailler.
EOF
}

# Génère la commande d'un agent (idempotent : skip si elle existe déjà).
generate_one() {
  local name="$1"
  local agent_file="$AGENTS_DIR/$name.md"
  local cmd_file="$COMMANDS_DIR/$name.md"
  if [ ! -f "$agent_file" ]; then
    log "agent introuvable, ignoré : $agent_file"
    return 0
  fi
  if [ -f "$cmd_file" ]; then
    log "commande déjà présente, conservée : $cmd_file"
    return 0
  fi
  mkdir -p "$COMMANDS_DIR"
  emit_command "$name" "$agent_file" > "$cmd_file"
  log "créée : $cmd_file  (incarnation de $name)"
}

if [ -n "$ONLY_AGENT" ]; then
  generate_one "$ONLY_AGENT"
else
  [ -d "$AGENTS_DIR" ] || { log "aucun dossier agents ($AGENTS_DIR) — rien à faire"; exit 0; }
  shopt -s nullglob
  for f in "$AGENTS_DIR"/*.md; do
    generate_one "$(basename "$f" .md)"
  done
  shopt -u nullglob
fi
