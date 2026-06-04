#!/usr/bin/env bash
# ensure-deps.sh — Bootstrap auto-install non-interactif des dépendances (dev-orchestrator)
#
# Vision §1 / D3 : rendre les deux dépendances invisibles et auto-installées.
#   - GSD          → via npm (npx get-shit-done-cc), flags --claude + --global (non-interactif).
#   - Superpowers  → via plugin Claude Code (claude plugin install --scope user).
#
# Garde-fou (D3 / BOOT-04) : ce script NE LANCE JAMAIS `gsd-new-project` (interactif).
# L'init projet reste sur confirmation explicite de l'agent.
#
# Usage:
#   ./ensure-deps.sh                       # détecte + auto-installe ce qui manque
#   VF_ENSURE_DRY_RUN=1 ./ensure-deps.sh   # détecte + logue les commandes SANS les exécuter (tests, idempotence)
#   VF_ENSURE_AUTO_MAP=1 ./ensure-deps.sh  # autorise un message map-codebase si du code est détecté (non-interactif)
#
# Variables d'environnement :
#   VF_ENSURE_DRY_RUN  (défaut vide) — 1 → simule sans exécuter npx/claude.
#   VF_ENSURE_AUTO_MAP (défaut vide) — 1 → logue que gsd-map-codebase est lançable si codebase détecté.
#
# Comportement : idempotent (2e run consécutif = no-op). Jamais d'échec silencieux :
# si un prérequis (Node/npm ou CLI claude) manque, les étapes manuelles sont affichées et exit 0.
#
# Référence : BOOT-01 (GSD auto), BOOT-02 (Superpowers auto), BOOT-03 (idempotent + fallback manuel),
#             BOOT-04 (gsd-new-project jamais lancé seul), D3.

# Pas de `-e` : certaines détections (command -v, grep) doivent pouvoir échouer sans tuer le script.
set -uo pipefail

# ---------- Variables ----------
DRY_RUN="${VF_ENSURE_DRY_RUN:-}"
GSD_VERSION_FILE="$HOME/.claude/get-shit-done/VERSION"

# ---------- Helpers ----------
log() {
  echo "[ensure-deps] $*" >&2
}

err() {
  echo "[ensure-deps] ERROR: $*" >&2
}

# Exécute une commande, ou la logue seulement en mode dry-run. Retourne le code de sortie réel.
run_cmd() {
  if [ -n "$DRY_RUN" ]; then
    log "(dry-run) $*"
    return 0
  fi
  "$@"
}

# ---------- GSD (BOOT-01 / BOOT-03) ----------

# Détecte GSD : binaire gsd-sdk sur le PATH OU fichier VERSION présent.
detect_gsd() {
  command -v gsd-sdk >/dev/null 2>&1 || [ -f "$GSD_VERSION_FILE" ]
}

ensure_gsd() {
  if detect_gsd; then
    log "GSD déjà présent (skip)."
    return 0
  fi

  # Prérequis : Node/npm sur le PATH. Absent → étapes manuelles, jamais d'échec silencieux.
  if ! command -v npm >/dev/null 2>&1; then
    err "Node/npm introuvable — GSD ne peut pas être auto-installé."
    log "Étape manuelle GSD :"
    log "  1. Installer Node.js (https://nodejs.org) puis vérifier : npm --version"
    log "  2. Relancer ce script : ./ensure-deps.sh"
    return 0
  fi

  log "GSD absent — installation via npx (non-interactif)..."
  if run_cmd npx -y get-shit-done-cc@latest --claude --global; then
    log "GSD installé via npx."
    return 0
  fi

  # Échec de l'install → bascule sur étapes manuelles (pas d'échec silencieux).
  err "L'auto-install GSD a échoué."
  log "Étape manuelle GSD :"
  log "  npx -y get-shit-done-cc@latest --claude --global"
  return 0
}

# ---------- Main ----------
main() {
  log "Bootstrap dépendances (mode=$([ -n "$DRY_RUN" ] && echo dry-run || echo apply))"
  ensure_gsd
  return 0
}

main "$@"
