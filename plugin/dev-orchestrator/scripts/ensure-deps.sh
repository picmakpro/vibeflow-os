#!/usr/bin/env bash
# ensure-deps.sh — Bootstrap auto-install non-interactif des dépendances (dev-orchestrator)
#
# Vision §1 / D3 : rendre les deux dépendances invisibles et auto-installées.
#   - GSD          → via npm (npx @opengsd/gsd-core), flag --claude + flag de scope dérivé (non-interactif).
#                    Dual-layout pendant la fenêtre de compat : détection VERSION file gsd-core
#                    prioritaire, get-shit-done legacy en repli (jamais de test PATH — piège #1).
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
#   VF_ENSURE_MIGRATE_ENGINE (défaut vide) — 1 → équivaut au flag --migrate-engine (voir Usage) :
#                      autorise l'install npx sur un état `legacy` détecté (D-06). SANS cette
#                      variable ni le flag, un état `legacy` est SIGNALÉ (message explicite) mais
#                      JAMAIS migré (P-07) — la confirmation humaine appartient à l'appelant
#                      (/vf-update, ADR-031), jamais à ce script.
#
# Flags CLI (rétro-compat : historiquement "$@" n'était jamais lu, les arguments inconnus sont
# donc IGNORÉS avec une ligne log plutôt que rejetés — un rejet strict casserait un appelant
# non recensé) :
#   --migrate-engine   Équivalent à VF_ENSURE_MIGRATE_ENGINE=1 (voir ci-dessus).
#   -h | --help        Affiche cet en-tête (grep '^# ') et exit 0.
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
# 1 → autorise l'install npx sur un état `legacy` détecté (D-06). Sans elle (ni le flag
# --migrate-engine, réglé plus bas au parsing des arguments), un état `legacy` est SIGNALÉ mais
# JAMAIS migré (P-07, ADR-031) — la confirmation humaine vit dans l'appelant (/vf-update), jamais
# dans ce script.
MIGRATE_ENGINE="${VF_ENSURE_MIGRATE_ENGINE:-}"
# Fenêtre de compat dual-layout (D-01/D3, 11-CONTEXT.md) : le VERSION file du nouveau layout est
# DÉRIVÉ de la même cascade que GSD_HOME (detect-gsd-engine.sh/build-gsd-index.sh), jamais une
# constante $HOME figée — un chemin $HOME-only raterait le scope --local de gsd-core 1.8.0, qui
# dépose le payload sous <projet>/.claude/gsd-core/. Pas de variante projet-local pour le legacy
# (D-01 : antérieur au scope --local).
default_gsd_home_new() {
  local root claude_home
  root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  claude_home="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
  if [ -d "$root/.claude/gsd-core" ]; then
    echo "$root/.claude/gsd-core"
  else
    echo "$claude_home/gsd-core"
  fi
}
GSD_HOME_NEW="$(default_gsd_home_new)"
GSD_VERSION_FILE_NEW="$GSD_HOME_NEW/VERSION"                                    # D3 : dérivé, pas figé
GSD_VERSION_FILE_LEGACY="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/get-shit-done/VERSION"
# État legacy capturé UNE SEULE FOIS en tête de ensure_gsd() (D-08.3) — source unique du
# message de nettoyage : l'installeur amont supprime lui-même ce VERSION file à l'install
# réussie, donc une re-détection après coup le rendrait définitivement inatteignable, sans
# aucune erreur visible.
GSD_LEGACY_DETECTED=""
GSD_LEGACY_VERSION=""
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

# Détecte l'état à 3 valeurs du moteur GSD (D-03) : source UNIQUE, réutilisée par detect_gsd()
# ci-dessous — cascade fichier VERSION UNIQUEMENT (jamais de test PATH — piège n°1). Un shim
# legacy (ex. gsd-sdk) peut rester sur le PATH après migration : un `command -v` ferait toujours
# renvoyer vrai et gsd-core ne serait jamais installé (panne silencieuse et durable).
detect_gsd_state() {
  if [ -f "$GSD_VERSION_FILE_NEW" ]; then
    echo "gsd-core"
  elif [ -f "$GSD_VERSION_FILE_LEGACY" ]; then
    echo "legacy"
  else
    echo "absent"
  fi
}

# Détecte GSD : booléen DÉRIVÉ de detect_gsd_state() — les états gsd-core ET legacy comptent
# tous deux comme « présent » (tolérance dual-layout, D-01/D3 Phase 10). Ne refait plus le test
# elle-même : l'ancien `||` a disparu de son corps.
detect_gsd() {
  [ "$(detect_gsd_state)" != "absent" ]
}

# Legacy détecté = le VERSION file de l'ancien layout existe (le nouveau peut coexister ou non —
# la coexistence n'est pas garantie propre, Phase 10). Sert à déclencher l'affichage du nettoyage
# manuel (ADR-031), indépendamment du succès de l'install gsd-core.
detect_gsd_legacy() {
  [ -f "$GSD_VERSION_FILE_LEGACY" ]
}

ensure_gsd() {
  # D-08.3 : capturer l'état legacy UNE SEULE FOIS, tout en haut, avant toute garde et tout
  # run_cmd — l'installeur amont supprime lui-même le VERSION legacy à l'install réussie ; une
  # capture après coup rendrait log_legacy_cleanup_if_needed() définitivement muette, sans aucun
  # signal d'erreur (le piège de séquencement, preuve directe en T2k).
  if detect_gsd_legacy; then
    GSD_LEGACY_DETECTED=1
    GSD_LEGACY_VERSION="$(cat "$GSD_VERSION_FILE_LEGACY" 2>/dev/null || echo '?')"
  fi

  local state dry_run_forced
  state="$(detect_gsd_state)"
  dry_run_forced=0
  { [ -n "$DRY_RUN" ] && [ -n "$FORCE" ]; } && dry_run_forced=1

  # État gsd-core : skip historique mot pour mot, y compris son exception dry-run forcé —
  # comportement strictement inchangé (D-03).
  if [ "$state" = "gsd-core" ] && [ "$dry_run_forced" -eq 0 ]; then
    log "GSD déjà présent (skip)."
    log_legacy_cleanup_if_needed
    return 0
  fi

  # État legacy SANS autorisation de migration (ni --migrate-engine, ni VF_ENSURE_MIGRATE_ENGINE,
  # ni le court-circuit dry-run forcé) : SIGNALÉ, jamais migré (P-07, D-06). Le skip silencieux
  # historique ne s'applique plus à cet état — c'est le trou identifié par le rapport d'audit.
  if [ "$state" = "legacy" ] && [ -z "$MIGRATE_ENGINE" ] && [ "$dry_run_forced" -eq 0 ]; then
    log "Moteur GSD legacy détecté (version ${GSD_LEGACY_VERSION:-?}) — migration disponible vers @opengsd/gsd-core, ce run ne migre pas."
    log "  Pour migrer : ./ensure-deps.sh --migrate-engine (ou VF_ENSURE_MIGRATE_ENGINE=1)."
    log_legacy_cleanup_if_needed
    return 0
  fi

  # Ici : état absent, OU legacy autorisé (--migrate-engine / VF_ENSURE_MIGRATE_ENGINE=1), OU
  # dry-run forcé (observabilité T2b/T2g) — suite inchangée de la fonction.

  # Prérequis : Node/npm sur le PATH. Absent → étapes manuelles, jamais d'échec silencieux.
  if ! command -v npm >/dev/null 2>&1; then
    err "Node/npm introuvable — GSD ne peut pas être auto-installé."
    log "Étape manuelle GSD :"
    log "  1. Installer Node.js (https://nodejs.org) puis vérifier : npm --version"
    log "  2. Relancer ce script : ./ensure-deps.sh"
    log_legacy_cleanup_if_needed
    return 0
  fi

  # Garde Node ≥ 22 (BOOT-01) : gsd-core cible Node 22+, une install sur un Node trop ancien
  # échouerait côté paquet — mieux vaut basculer tôt sur l'étape manuelle avec un message clair.
  local node_major
  node_major="$(node -e 'process.stdout.write(String(process.versions.node.split(".")[0]))' 2>/dev/null || echo 0)"
  if [ "${node_major:-0}" -lt 22 ] 2>/dev/null; then
    err "Node $(node --version 2>/dev/null || echo '?') détecté — @opengsd/gsd-core requiert Node ≥ 22."
    log "Étape manuelle GSD :"
    log "  1. Mettre à jour Node.js vers 22+ (https://nodejs.org) puis vérifier : node --version"
    log "  2. Relancer ce script : ./ensure-deps.sh"
    log_legacy_cleanup_if_needed
    return 0
  fi

  log "GSD absent — installation via npx (non-interactif, scope=$SCOPE → $GSD_SCOPE_FLAG)..."
  # Plafond semver "^1" (arbitrage 2026-07-26, audit Phase 11) : toujours le dernier 1.x —
# fraîcheur sans pin figé — mais un saut de MAJEURE (breaking ou compromission d'un fork
# jeune) ne s'installe jamais seul : il redevient une décision humaine.
if run_cmd npx -y "@opengsd/gsd-core@^1" --claude "$GSD_SCOPE_FLAG"; then
    log "GSD installé via npx."
    log_legacy_cleanup_if_needed
    return 0
  fi

  # Échec de l'install → bascule sur étapes manuelles (pas d'échec silencieux).
  err "L'auto-install GSD a échoué."
  log "Étape manuelle GSD :"
  log "  npx -y \"@opengsd/gsd-core@^1\" --claude $GSD_SCOPE_FLAG"
  log_legacy_cleanup_if_needed
  return 0
}

# Vérifie, en LECTURE SEULE, si <pkg> est installé en global via npm (npm ls -g --depth=0). Seul
# appel npm réellement EXÉCUTÉ dans tout ce chemin (P-01) — jamais un uninstall. Retourne faux
# (1) si npm est absent du PATH ou si le paquet n'est pas listé en global.
npm_pkg_installed_globally() {
  local pkg="$1"
  command -v npm >/dev/null 2>&1 || return 1
  npm ls -g --depth=0 "$pkg" >/dev/null 2>&1
}

# Affiche (jamais n'exécute — ADR-031) le nettoyage manuel de l'ancien layout quand des artefacts
# legacy ont été CAPTURÉS en tête de ensure_gsd() (D-08.3 — jamais une re-détection ici, l'install
# amont peut avoir déjà supprimé le témoin). L'installeur amont de gsd-core nettoie
# hooks/commands/skills legacy à l'install, mais PAS les paquets npm globaux ni l'arbre
# ~/.claude/get-shit-done/ — cette responsabilité reste manuelle.
#
# D-08.1 : les deux lignes `npm uninstall -g` ne sont proposées QUE si npm_pkg_installed_globally()
# confirme le paquet réellement présent en global (sur le poste audité, aucun des deux ne l'était —
# install faite en npx — donc deux lignes sur trois étaient des no-op trompeurs).
# D-08.2 : le retrait de l'arborescence vide laissée debout par l'installeur amont est proposé,
# jamais exécuté — même forme "afficher, jamais lancer" que le reste de cette fonction.
log_legacy_cleanup_if_needed() {
  [ -n "$GSD_LEGACY_DETECTED" ] || return 0

  log "Artefacts legacy détectés (~/.claude/get-shit-done/, version ${GSD_LEGACY_VERSION:-?}) — nettoyage manuel recommandé :"
  if npm_pkg_installed_globally "get-shit-done-cc"; then
    log "  npm uninstall -g get-shit-done-cc"
  fi
  if npm_pkg_installed_globally "@gsd-build/sdk"; then
    log "  npm uninstall -g @gsd-build/sdk"
  fi
  log "  rm -rf ~/.claude/get-shit-done"
  log "  find ~/.claude/get-shit-done -type d -empty -delete"
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

# ---------- Patch MCP de gsd-executor (ADR-051) ----------
# gsd-executor N'APPARTIENT PAS au plugin VibeFlow : il est fourni par GSD et posé dans
# ~/.claude/agents/gsd-executor.md (ou ./.claude/agents en scope local). Son `tools:` ne liste,
# côté MCP, que `mcp__context7__*` — donc, dispatché en sous-agent, il est aveugle au serveur MCP
# du projet (XcodeBuildMCP, etc.). VibeFlow le PATCHE après l'install de GSD, dans le même esprit
# que build-gsd-index.sh post-traite déjà GSD. Idempotent + best-effort + re-jouable : rejoué à
# chaque run, il ré-affirme l'injection même après qu'une réinstall GSD a réécrit le fichier.
patch_gsd_executor_mcp() {
  local injector
  injector="$(dirname "$0")/inject-mcp-tools.sh"
  if [ ! -f "$injector" ]; then
    log "gsd-executor : inject-mcp-tools.sh introuvable à côté de ce script — patch MCP sauté (best-effort)."
    return 0
  fi

  # Chercher gsd-executor.md aux emplacements connus (global d'abord, puis local projet).
  local candidates=("$HOME/.claude/agents/gsd-executor.md" "./.claude/agents/gsd-executor.md")
  local found=""
  local c
  for c in "${candidates[@]}"; do
    [ -f "$c" ] && found="$c" && break
  done
  if [ -z "$found" ]; then
    log "gsd-executor.md introuvable (GSD pas encore posé ?) — patch MCP différé (best-effort)."
    return 0
  fi

  # --force : gsd-executor ne porte pas le flag vf-mcp-consumer (fichier hors plugin). Source des
  # serveurs = ./.mcp.json du lab. En dry-run ensure-deps, propager --dry-run (aucune écriture).
  # (Pas de tableau d'args : incompatible bash 3.2/macOS sous set -u quand il est vide.)
  local rc
  if [ -n "$DRY_RUN" ]; then
    bash "$injector" --target "$found" --mcp-json "./.mcp.json" --force --dry-run
    rc=$?
  else
    bash "$injector" --target "$found" --mcp-json "./.mcp.json" --force
    rc=$?
  fi
  if [ "$rc" -eq 0 ]; then
    log "gsd-executor : serveurs MCP du lab injectés dans son tools: (ADR-051) → $found"
  else
    log "gsd-executor : injection MCP best-effort (voir inject-mcp-tools.sh)."
  fi
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
  # ADR-051 : après l'install GSD, patcher le tools: de gsd-executor avec les serveurs MCP du lab.
  patch_gsd_executor_mcp
  guard_init

  # Résumé final clair de l'état des deux piliers.
  local gsd_state sp_state
  gsd_state=$(detect_gsd && echo "présent" || echo "manquant (étape manuelle affichée)")
  sp_state=$(detect_superpowers && echo "présent" || echo "manquant (étape manuelle affichée)")
  log "Résumé : GSD=$gsd_state ; Superpowers=$sp_state"
  return 0
}

# ---------- Parsing minimal des arguments ----------
# Historique : ce script recevait "$@" sans jamais le lire — un rejet strict casserait un
# appelant non recensé (choix délibéré de rétro-compat, cf. en-tête). Seuls --migrate-engine et
# -h/--help sont reconnus ; tout le reste est IGNORÉ avec une ligne log, jamais un exit non-zéro.
for arg in "$@"; do
  case "$arg" in
    --migrate-engine) MIGRATE_ENGINE=1 ;;
    -h | --help)
      grep '^# ' "$0" | sed 's/^# //'
      exit 0
      ;;
    *) log "argument ignoré (rétro-compat, non reconnu) : $arg" ;;
  esac
done

main "$@"
