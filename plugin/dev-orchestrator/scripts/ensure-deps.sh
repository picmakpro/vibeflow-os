#!/usr/bin/env bash
# ensure-deps.sh — Bootstrap auto-install non-interactif des dépendances (dev-orchestrator)
#
# Vision §1 / D3 : rendre les deux dépendances invisibles et auto-installées.
#   - GSD          → via npm (npx get-shit-done-cc), flag --claude + flag de scope dérivé (non-interactif).
#   - Superpowers  → via plugin Claude Code (claude plugin install --scope <scope>).
#
# Garde-fou (D3 / BOOT-04) : ce script NE LANCE JAMAIS `gsd-new-project` (interactif).
# L'init projet reste sur confirmation explicite de l'agent.
#
# Usage:
#   ./ensure-deps.sh                       # détecte + auto-installe ce qui manque
#   VF_ENSURE_DRY_RUN=1 ./ensure-deps.sh   # détecte + logue les commandes SANS les exécuter (tests, idempotence)
#   VF_ENSURE_AUTO_MAP=1 ./ensure-deps.sh  # autorise un message map-codebase si du code est détecté (non-interactif)
#   VF_SCOPE=project ./ensure-deps.sh      # scope d'install (user|project|local) — voir mapping ci-dessous
#   VF_ENSURE_DRY_RUN=1 VF_ENSURE_FORCE=1 ./ensure-deps.sh  # dry-run observable : logue la cmd scopée même si déps présentes
#
# Variables d'environnement :
#   VF_ENSURE_DRY_RUN  (défaut vide) — 1 → simule sans exécuter npx/claude.
#   VF_ENSURE_AUTO_MAP (défaut vide) — 1 → logue que gsd-map-codebase est lançable si codebase détecté.
#   VF_SCOPE           (défaut user) — scope d'install : user|project|local. Mapping (spec §3 / §8) :
#                        GSD :         user → --global ; project|local → --local
#                        Superpowers : user|project|local → --scope <même valeur>
#                      Le défaut LEGACY `user` est un fallback pour les APPELS DIRECTS uniquement
#                      (CI, debug, run manuel). EN PRODUCTION, le skill /vibeflow-install (Phase 4)
#                      passe TOUJOURS un VF_SCOPE explicite à l'engine ET à ce script (un seul scope
#                      partout — cohérence ID4, spec §3/§8). Ce défaut ne co-occurre donc jamais en prod
#                      avec le défaut LEGACY de l'engine (`project`). Une valeur explicite incohérente
#                      est rejetée tôt par la validation stricte ci-dessous (err + exit 1).
#   VF_ENSURE_FORCE    (défaut vide) — 1 → EN DRY-RUN UNIQUEMENT, court-circuite l'early-return de
#                      détection (skip) pour loguer la commande scopée QUI SERAIT émise, sans rien
#                      installer. Sans effet hors dry-run (jamais d'install forcée). Rend le dry-run
#                      observable sur une machine où GSD/Superpowers sont déjà présents (CI/dev).
#
# Comportement : idempotent (2e run consécutif = no-op, mode normal non forcé). Jamais d'échec silencieux :
# si un prérequis (Node/npm ou CLI claude) manque, les étapes manuelles sont affichées et exit 0.
#
# Référence : BOOT-01 (GSD auto), BOOT-02 (Superpowers auto), BOOT-03 (idempotent + fallback manuel),
#             BOOT-04 (gsd-new-project jamais lancé seul), SCOPE-03 (scope-aware via VF_SCOPE), D3.

# Pas de `-e` : certaines détections (command -v, grep) doivent pouvoir échouer sans tuer le script.
set -uo pipefail

# ---------- Variables ----------
DRY_RUN="${VF_ENSURE_DRY_RUN:-}"
AUTO_MAP="${VF_ENSURE_AUTO_MAP:-}"
# Scope d'install. Défaut LEGACY `user` = rétro-compat APPEL-DIRECT (le skill /vibeflow-install
# de Phase 4 passe TOUJOURS un VF_SCOPE explicite en prod — cohérence ID4, voir en-tête).
SCOPE="${VF_SCOPE:-user}"
# 1 → en DRY-RUN, court-circuite l'early-return de détection pour loguer la cmd scopée (sans installer).
# Sans effet hors dry-run (jamais d'install forcée).
FORCE="${VF_ENSURE_FORCE:-}"
GSD_VERSION_FILE="$HOME/.claude/get-shit-done/VERSION"
PLUGINS_CACHE_DIR="$HOME/.claude/plugins/cache"

# ---------- Helpers ----------
log() {
  echo "[ensure-deps] $*" >&2
}

err() {
  echo "[ensure-deps] ERROR: $*" >&2
}

# ---------- Validation du scope (T-03-04) ----------
# Valider VF_SCOPE EN TÊTE, AVANT toute définition de main et tout effet de bord / run_cmd :
# un scope invalide injecté dans les flags d'install est rejeté tôt (err + exit 1).
case "$SCOPE" in
  user | project | local) ;;
  *)
    err "VF_SCOPE invalide : $SCOPE (attendu user|project|local)"
    exit 1
    ;;
esac

# Dérivation des flags de scope (spec §3 / §8) :
#   GSD :         user → --global ; project|local → --local
#   Superpowers : user|project|local → --scope <même valeur>
if [ "$SCOPE" = "user" ]; then
  GSD_SCOPE_FLAG="--global"
else
  GSD_SCOPE_FLAG="--local"
fi
SUPERPOWERS_SCOPE="$SCOPE"

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
  # Early-return skip si GSD détecté — SAUF en dry-run forcé (on tombe alors dans le chemin run_cmd
  # qui ne fait que loguer la cmd scopée, sans installer). Mode normal : comportement inchangé.
  if detect_gsd && ! { [ -n "$DRY_RUN" ] && [ -n "$FORCE" ]; }; then
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

  log "GSD absent — installation via npx (non-interactif, scope=$SCOPE → $GSD_SCOPE_FLAG)..."
  if run_cmd npx -y get-shit-done-cc@latest --claude "$GSD_SCOPE_FLAG"; then
    log "GSD installé via npx."
    return 0
  fi

  # Échec de l'install → bascule sur étapes manuelles (pas d'échec silencieux).
  err "L'auto-install GSD a échoué."
  log "Étape manuelle GSD :"
  log "  npx -y get-shit-done-cc@latest --claude $GSD_SCOPE_FLAG"
  return 0
}

# ---------- Superpowers (BOOT-02 / BOOT-03) ----------

# Détecte Superpowers : présent dans la liste des plugins OU dossier en cache.
detect_superpowers() {
  if command -v claude >/dev/null 2>&1 && claude plugin list 2>/dev/null | grep -q superpowers; then
    return 0
  fi
  [ -d "$PLUGINS_CACHE_DIR" ] && find "$PLUGINS_CACHE_DIR" -type d -name 'superpowers*' 2>/dev/null | grep -q .
}

ensure_superpowers() {
  # Early-return skip si Superpowers détecté — SAUF en dry-run forcé (on logue alors la cmd scopée
  # via run_cmd sans installer). Mode normal : comportement inchangé.
  if detect_superpowers && ! { [ -n "$DRY_RUN" ] && [ -n "$FORCE" ]; }; then
    log "Superpowers déjà présent (skip)."
    return 0
  fi

  # Prérequis : CLI claude sur le PATH. Absent → étape manuelle TUI, jamais d'échec silencieux.
  if ! command -v claude >/dev/null 2>&1; then
    err "CLI claude introuvable — Superpowers ne peut pas être auto-installé."
    log "Étape manuelle Superpowers (dans la TUI Claude Code) :"
    log "  /plugin install superpowers@claude-plugins-official"
    return 0
  fi

  log "Superpowers absent — installation via plugin (non-interactif, --scope $SUPERPOWERS_SCOPE)..."
  if run_cmd claude plugin install superpowers@claude-plugins-official --scope "$SUPERPOWERS_SCOPE"; then
    log "Superpowers installé via plugin."
    return 0
  fi

  # Fallback : ajouter le marketplace puis re-tenter l'install.
  log "Install directe KO — tentative via marketplace..."
  if run_cmd claude plugin marketplace add anthropics/claude-plugins-official &&
    run_cmd claude plugin install superpowers@claude-plugins-official --scope "$SUPERPOWERS_SCOPE"; then
    log "Superpowers installé via marketplace + plugin."
    return 0
  fi

  # Toujours KO → étape manuelle (jamais d'échec silencieux).
  # La TUI Claude Code n'expose pas de flag de scope : on indique le scope visé en commentaire.
  err "L'auto-install Superpowers a échoué (directe + marketplace)."
  log "Étape manuelle Superpowers (dans la TUI Claude Code, scope visé : $SUPERPOWERS_SCOPE) :"
  log "  /plugin install superpowers@claude-plugins-official"
  return 0
}

# ---------- Garde-fou init (BOOT-04) ----------

# Détecte un codebase dans le cwd (fichiers de code courants à la racine ou un niveau sous src/).
detect_codebase() {
  find . -maxdepth 2 \
    \( -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.py' \
    -o -name '*.go' -o -name '*.swift' -o -name '*.rs' -o -name '*.java' \) \
    2>/dev/null | grep -q .
}

# IMPORTANT : ne lance JAMAIS gsd-new-project (interactif). Se contente d'inviter à confirmer.
guard_init() {
  if detect_codebase; then
    if [ -n "$AUTO_MAP" ]; then
      log "Codebase détecté + VF_ENSURE_AUTO_MAP=1 → gsd-map-codebase est lançable (non-interactif)."
    else
      log "Projet dev détecté — l'agent proposera l'init (gsd-new-project sur confirmation seulement)."
    fi
  fi
}

# ---------- Main ----------
main() {
  log "Bootstrap dépendances (mode=$([ -n "$DRY_RUN" ] && echo dry-run || echo apply))"
  ensure_gsd
  ensure_superpowers
  guard_init

  # Résumé final clair de l'état des deux piliers.
  local gsd_state sp_state
  gsd_state=$(detect_gsd && echo "présent" || echo "manquant (étape manuelle affichée)")
  sp_state=$(detect_superpowers && echo "présent" || echo "manquant (étape manuelle affichée)")
  log "Résumé : GSD=$gsd_state ; Superpowers=$sp_state"
  return 0
}

main "$@"
