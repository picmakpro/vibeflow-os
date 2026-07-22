#!/usr/bin/env bash
# vibeflow-update.sh — Installeur/updateur scope-aware des modules vibeflow-os.
#
# Usage:
#   ./vibeflow-update.sh [--scope user|project|local] install <module>      # Installe un module
#   ./vibeflow-update.sh [--scope ...] install --with-deps <module>         # Installe la fermeture transitive
#   ./vibeflow-update.sh [--scope ...] install --all                        # Installe tous les modules dispo
#   ./vibeflow-update.sh [--scope ...] update <module>                      # Met à jour un module installé
#   ./vibeflow-update.sh [--scope ...] update --all                         # Met à jour tous les modules installés
#   ./vibeflow-update.sh [--scope ...] uninstall <module>                   # Désinstalle un module
#   ./vibeflow-update.sh [--scope ...] uninstall --all                      # Désinstalle TOUS les modules installés (lit le registre)
#   ./vibeflow-update.sh [--scope ...] rollback <module>                    # Restore depuis backup
#   ./vibeflow-update.sh [--scope ...] status                               # Liste modules installés + versions
#   ./vibeflow-update.sh sync                                               # No-op (source = cache, plus de git)
#
# Source : le cache local fourni par l'appelant (VIBEFLOW_CACHE, défaut .vibeflow-cache).
#   Plus de clone/pull git : le cache DOIT exister (sinon erreur). En prod, c'est le skill
#   /vibeflow-install (Phase 4) qui prépare le cache à partir du plugin packagé (Phase 5).
#
# Scope (cible d'install, spec §3) :
#   --scope user            → $HOME/.claude
#   --scope project | local → ./.claude   (local ajoute en plus les chemins au ./.gitignore)
#   env VF_SCOPE            → idem ; --scope l'emporte sur VF_SCOPE.
#
# Pré-requis : $VIBEFLOW_CACHE existe (dossier des modules + leurs module.json).

set -euo pipefail

# ---------- Helpers (définis tôt : utilisés dès le parsing) ----------
log() { echo "[vibeflow-update] $*" >&2; }
err() { echo "[vibeflow-update] ERROR: $*" >&2; exit 1; }

# ---------- Résolution du scope → TARGET_ROOT (SCOPE-01) ----------
# Défaut LEGACY = `project` (cible historique ./.claude). C'est un fallback APPEL-DIRECT
# (debug, run manuel, tests). EN PROD le skill /vibeflow-install (Phase 4) passe TOUJOURS un
# VF_SCOPE explicite à l'engine ET à ensure-deps.sh (un seul scope partout — cohérence ID4,
# spec §3/§8). Ce défaut engine `project` ne co-occurre donc JAMAIS en prod avec le défaut
# LEGACY `user` de ensure-deps.sh : pas de contradiction entre 03-01 et 03-02.
VF_SCOPE="${VF_SCOPE:-project}"

# Détecter `--scope <val>` AVANT cmd="$1" : on filtre les positionnels et on override VF_SCOPE.
_positional=()
while [ "$#" -gt 0 ]; do
  case "$1" in
    --scope)
      [ "$#" -ge 2 ] || err "--scope nécessite une valeur (user|project|local)"
      VF_SCOPE="$2"
      shift 2
      ;;
    --scope=*)
      VF_SCOPE="${1#--scope=}"
      shift
      ;;
    *)
      _positional+=("$1")
      shift
      ;;
  esac
done
# Restaurer les positionnels nettoyés (set -u : guard tableau vide).
if [ "${#_positional[@]}" -gt 0 ]; then
  set -- "${_positional[@]}"
else
  set --
fi

# Validation stricte : rejette tôt toute valeur incohérente.
case "$VF_SCOPE" in
  user|project|local) : ;;
  *) err "scope invalide : $VF_SCOPE (attendu user|project|local)" ;;
esac

# Résolution TARGET_ROOT depuis le scope.
case "$VF_SCOPE" in
  user)            TARGET_ROOT="$HOME/.claude" ;;
  project|local)   TARGET_ROOT="./.claude" ;;
esac
export VF_SCOPE

# ---------- Variables (toutes les cibles rebasées sur TARGET_ROOT) ----------
CACHE_DIR="${VIBEFLOW_CACHE:-.vibeflow-cache}"   # SEULE source (plus de clone)
INSTALLED_REGISTRY="$TARGET_ROOT/scripts/.vibeflow-installed"
BACKUP_DIR="$TARGET_ROOT/.backups"

# ---------- Cache (SCOPE-02 : plus de clone/pull, le cache doit exister) ----------
require_cache() {
  [ -d "$CACHE_DIR" ] || err "Cache introuvable : $CACHE_DIR (fournir VIBEFLOW_CACHE)"
}

list_available_modules() {
  require_cache
  for d in "$CACHE_DIR"/*/; do
    name=$(basename "$d")
    [ "$name" = "_internal" ] && continue
    if [ -f "${d}VERSION" ]; then
      echo "$name"
    fi
  done
}

module_version_available() {
  local mod="$1"
  cat "$CACHE_DIR/$mod/VERSION" 2>/dev/null || echo "—"
}

module_version_installed() {
  local mod="$1"
  if [ -f "$INSTALLED_REGISTRY" ]; then
    grep "^$mod=" "$INSTALLED_REGISTRY" 2>/dev/null | cut -d= -f2 || echo "—"
  else
    echo "—"
  fi
}

mark_installed() {
  local mod="$1"
  local version="$2"
  mkdir -p "$(dirname "$INSTALLED_REGISTRY")"
  touch "$INSTALLED_REGISTRY"
  # Remove old entry if exists
  grep -v "^$mod=" "$INSTALLED_REGISTRY" > "${INSTALLED_REGISTRY}.tmp" 2>/dev/null || true
  echo "$mod=$version" >> "${INSTALLED_REGISTRY}.tmp"
  mv "${INSTALLED_REGISTRY}.tmp" "$INSTALLED_REGISTRY"
}

mark_uninstalled() {
  local mod="$1"
  if [ -f "$INSTALLED_REGISTRY" ]; then
    grep -v "^$mod=" "$INSTALLED_REGISTRY" > "${INSTALLED_REGISTRY}.tmp" || true
    mv "${INSTALLED_REGISTRY}.tmp" "$INSTALLED_REGISTRY"
  fi
}

# ---------- Résolveur de fermeture transitive (intégration Phase 2) ----------
# Localise resolve-deps.sh : d'abord dans le cache (prod, bundlé par Phase 5/PLUG-02),
# sinon à côté de l'engine (dev/source). Renvoie le chemin du résolveur, ou vide si absent.
find_resolver() {
  local candidate
  candidate="$CACHE_DIR/_internal/resolve-deps.sh"
  if [ -f "$candidate" ]; then echo "$candidate"; return 0; fi
  candidate="$(dirname "$0")/resolve-deps.sh"
  if [ -f "$candidate" ]; then echo "$candidate"; return 0; fi
  echo ""
}

# resolve_closure <mod...> : émet sur stdout la fermeture transitive (1 module/ligne).
# Si le résolveur est ABSENT, fallback best-effort = renvoie les args bruts, MAIS loue
# un AVERTISSEMENT BRUYANT (warning visible) — closure incomplète = install possiblement cassée.
resolve_closure() {
  local resolver
  resolver="$(find_resolver)"
  if [ -z "$resolver" ]; then
    # Fallback résolveur-absent : warning BRUYANT (sur stderr, sans exit) — T-03-08.
    echo "[vibeflow-update] ERROR: ATTENTION : résolveur introuvable — fermeture transitive NON calculée. Les dépendances de $* ne seront PAS installées ; l'install peut être incomplète/cassée. (Phase 5/PLUG-02 doit bundler resolve-deps.sh dans le cache.)" >&2
    printf '%s\n' "$@"
    return 0
  fi
  # VF_MODULES_ROOT pointe sur le CACHE (les module.json y vivent), pas sur le repo.
  VF_MODULES_ROOT="$CACHE_DIR" bash "$resolver" "$@"
}

# ---------- Gitignore local (SCOPE-04) ----------
# Ajoute les chemins installés du module au ./.gitignore (cwd projet) UNIQUEMENT en scope local.
# Idempotent : pas de doublon (grep -qxF avant ajout). Crée .gitignore s'il manque.
gitignore_add_one() {
  local path="$1"
  # Création paresseuse du .gitignore au premier ajout.
  [ -f .gitignore ] || : > .gitignore
  if ! grep -qxF "$path" .gitignore; then
    echo "$path" >> .gitignore
    log "  gitignore += $path"
  fi
}

gitignore_add_paths() {
  local mod="$1"
  # Scope local seulement : user/project ne touchent JAMAIS au .gitignore.
  [ "$VF_SCOPE" = "local" ] || return 0

  local module_dir="$CACHE_DIR/$mod"

  # Skill racine.
  [ -f "$module_dir/SKILL.md" ] && gitignore_add_one ".claude/skills/$mod/"
  # Skills imbriqués.
  if [ -d "$module_dir/skills" ]; then
    for skill_dir in "$module_dir/skills/"*/; do
      [ -d "$skill_dir" ] || continue
      gitignore_add_one ".claude/skills/$(basename "$skill_dir")/"
    done
  fi
  # Agent module (D7) : AGENT.md + dossier references.
  if [ -f "$module_dir/AGENT.md" ]; then
    gitignore_add_one ".claude/agents/${mod}.md"
    gitignore_add_one ".claude/commands/${mod}.md"
    [ -d "$module_dir/references" ] && gitignore_add_one ".claude/agents/${mod}-references/"
  fi
  # Multi-agents module : agents/<name>.md.
  if [ -d "$module_dir/agents" ]; then
    for f in "$module_dir/agents/"*.md; do
      [ -f "$f" ] && gitignore_add_one ".claude/agents/$(basename "$f")"
    done
    [ -d "$module_dir/references" ] && [ ! -f "$module_dir/SKILL.md" ] && gitignore_add_one ".claude/agents/${mod}-references/"
  fi
  # Rules réellement posées.
  if [ -d "$module_dir/rules" ]; then
    for f in "$module_dir/rules/"*.md; do
      [ -f "$f" ] && gitignore_add_one ".claude/rules/$(basename "$f")"
    done
  fi
  # Scripts réellement posés (shell + Node).
  if [ -d "$module_dir/scripts" ]; then
    for f in "$module_dir/scripts/"*.sh "$module_dir/scripts/"*.mjs "$module_dir/scripts/"*.js; do
      [ -f "$f" ] && gitignore_add_one ".claude/scripts/$(basename "$f")"
    done
  fi
  # Config template posé à côté d'un SKILL.md racine.
  [ -d "$module_dir/config" ] && [ -f "$module_dir/SKILL.md" ] && gitignore_add_one ".claude/skills/$mod/config/"
}

# ---------- Commande d'incarnation (ADR-042) ----------
# Après pose d'un agent, générer sa commande slash `/agent` (incarnation FENÊTRE PRINCIPALE).
# Best-effort : ne JAMAIS faire échouer l'install si le générateur est absent. Idempotent
# (le générateur n'écrase jamais une commande existante).
find_command_generator() {
  local c
  c="$TARGET_ROOT/scripts/generate-agent-commands.sh"; [ -f "$c" ] && { echo "$c"; return 0; }
  c="$CACHE_DIR/conductor/scripts/generate-agent-commands.sh"; [ -f "$c" ] && { echo "$c"; return 0; }
  echo ""
}

generate_agent_command_for() {
  local mod="$1" gen
  gen="$(find_command_generator)"
  if [ -z "$gen" ]; then
    log "  (commande d'incarnation non générée — generate-agent-commands.sh absent, best-effort)"
    return 0
  fi
  if VF_TARGET_ROOT="$TARGET_ROOT" bash "$gen" --agent "$mod" >/dev/null 2>&1; then
    log "  commande d'incarnation → $TARGET_ROOT/commands/${mod}.md"
  else
    log "  (commande d'incarnation non générée pour $mod — best-effort)"
  fi
}

# ---------- Injection MCP dérivée du lab (ADR-051) ----------
# Un sous-agent (Task) n'hérite PAS des serveurs MCP de la session : il ne voit, côté MCP, que ce
# que son `tools:` autorise (`mcp__<serveur>__*`). Les agents exécutants (flag vf-mcp-consumer:true)
# doivent donc recevoir les serveurs que le LAB déclare dans son ./.mcp.json. Data-driven (aucun nom
# de serveur ni d'agent en dur) ; best-effort (jamais faire échouer l'install). Idempotent.
find_mcp_injector() {
  local c
  c="$TARGET_ROOT/scripts/inject-mcp-tools.sh"; [ -f "$c" ] && { echo "$c"; return 0; }
  c="$CACHE_DIR/dev-orchestrator/scripts/inject-mcp-tools.sh"; [ -f "$c" ] && { echo "$c"; return 0; }
  c="$(dirname "$0")/inject-mcp-tools.sh"; [ -f "$c" ] && { echo "$c"; return 0; }
  echo ""
}

inject_lab_mcp_into_agents() {
  local injector
  injector="$(find_mcp_injector)"
  if [ -z "$injector" ]; then
    log "  (injection MCP non exécutée — inject-mcp-tools.sh absent, best-effort)"
    return 0
  fi
  # Source = ./.mcp.json du LAB (cwd projet), quel que soit le scope (les serveurs MCP du projet y
  # vivent, pas dans TARGET_ROOT). Absent → le script no-op de lui-même.
  if bash "$injector" --target "$TARGET_ROOT/agents" --mcp-json "./.mcp.json" >/dev/null 2>&1; then
    log "  serveurs MCP du lab injectés dans les agents exécutants flaggés (vf-mcp-consumer, ADR-051)"
  else
    log "  (injection MCP best-effort — voir inject-mcp-tools.sh)"
  fi
}

# ---------- Hooks de gouvernance (ADR-043) ----------
# Un module peut déclarer hooks/hooks.json (format Claude Code, placeholder {{VF_SCRIPTS}}).
# L'install MERGE le fragment dans le settings.json du scope ; l'uninstall le retire.
# La gouvernance est posée par la machine — plus jamais un snippet à copier-coller.
find_hooks_merger() {
  local c
  c="$CACHE_DIR/_internal/merge-hooks.sh"; [ -f "$c" ] && { echo "$c"; return 0; }
  c="$(dirname "$0")/merge-hooks.sh"; [ -f "$c" ] && { echo "$c"; return 0; }
  echo ""
}

scripts_prefix_for_scope() {
  # Chemins LITTÉRAUX dans settings.json (expansés par le harness à l'exécution du hook).
  case "$VF_SCOPE" in
    user) printf '%s' '"$HOME"/.claude/scripts' ;;
    *)    printf '%s' '"$CLAUDE_PROJECT_DIR"/.claude/scripts' ;;
  esac
}

merge_module_hooks() {
  local mod="$1"
  local fragment="$CACHE_DIR/$mod/hooks/hooks.json"
  [ -f "$fragment" ] || return 0
  local merger
  merger="$(find_hooks_merger)"
  if [ -z "$merger" ]; then
    log "  ERROR: merge-hooks.sh introuvable — hooks de $mod NON câblés (gouvernance absente !)"
    return 0
  fi
  # Backup du settings avant toute écriture.
  if [ -f "$TARGET_ROOT/settings.json" ]; then
    mkdir -p "$BACKUP_DIR"
    cp "$TARGET_ROOT/settings.json" "$BACKUP_DIR/settings-$(date +%Y%m%d-%H%M%S).json"
  fi
  if bash "$merger" merge "$fragment" --settings "$TARGET_ROOT/settings.json" --scripts-prefix "$(scripts_prefix_for_scope)"; then
    log "  hooks mergés → $TARGET_ROOT/settings.json"
  else
    log "  ERROR: merge hooks ÉCHOUÉ pour $mod — gouvernance NON câblée (corriger settings.json puis réinstaller)"
  fi
}

remove_module_hooks() {
  local mod="$1"
  local fragment="$CACHE_DIR/$mod/hooks/hooks.json"
  [ -f "$fragment" ] || return 0
  [ -f "$TARGET_ROOT/settings.json" ] || return 0
  local merger
  merger="$(find_hooks_merger)"
  [ -n "$merger" ] || { log "  (retrait hooks impossible — merge-hooks.sh absent)"; return 0; }
  if bash "$merger" remove "$fragment" --settings "$TARGET_ROOT/settings.json"; then
    log "  hooks retirés de $TARGET_ROOT/settings.json"
  else
    log "  (retrait hooks échoué pour $mod — best-effort, nettoyer settings.json à la main)"
  fi
}

# ---------- Scripts (posés au TARGET_ROOT/scripts) ----------
# Copie les scripts d'un module (shell + Node) + le sous-dossier tests/. Extrait d'install_module
# pour être réutilisable par la resync gouvernance (update version inchangée).
copy_module_scripts() {
  local mod="$1"
  local module_dir="$CACHE_DIR/$mod"
  [ -d "$module_dir/scripts" ] || return 0
  mkdir -p "$TARGET_ROOT/scripts"
  for f in "$module_dir/scripts/"*.sh "$module_dir/scripts/"*.mjs "$module_dir/scripts/"*.js; do
    [ -f "$f" ] && cp "$f" "$TARGET_ROOT/scripts/" && chmod +x "$TARGET_ROOT/scripts/$(basename "$f")"
  done
  if [ -d "$module_dir/scripts/tests" ]; then
    mkdir -p "$TARGET_ROOT/scripts/tests/fixtures"
    cp -r "$module_dir/scripts/tests/"*.sh "$TARGET_ROOT/scripts/tests/" 2>/dev/null || true
    cp -r "$module_dir/scripts/tests/fixtures/"* "$TARGET_ROOT/scripts/tests/fixtures/" 2>/dev/null || true
    chmod +x "$TARGET_ROOT"/scripts/tests/*.sh 2>/dev/null || true
  fi
  log "  copied scripts/ → $TARGET_ROOT/scripts/"
}

# Resync gouvernance légère (Fix B) : re-pose les scripts + re-merge les hooks d'un module SANS
# backup ni re-copie complète. Appelée quand la version est INCHANGÉE — rend /vf-update
# auto-réparateur si un hooks.json a dérivé (nouveau hook posé sans bump de VERSION du module).
# Idempotent : merge-hooks dédup par basename, la copie de scripts écrase à l'identique.
sync_module_governance() {
  local mod="$1"
  copy_module_scripts "$mod"
  merge_module_hooks "$mod"
}

# ---------- Baseline obligatoire (INST-02a) ----------
# Un module module.json avec "mandatory": true est un INVARIANT du lab (aujourd'hui : conductor,
# le socle de gouvernance). Data-driven, AUCUN nom de module en dur.
module_is_mandatory() {
  local mod="$1"
  local mj="$CACHE_DIR/$mod/module.json"
  [ -f "$mj" ] || return 1
  grep -Eq '"mandatory"[[:space:]]*:[[:space:]]*true' "$mj"
}

# ensure_mandatory_baseline : garantit que tout module `mandatory` est présent dans le lab.
# Corrige la lacune où `update --all` n'itère que sur le registre : un module mandatory publié
# APRÈS la config d'un lab (ex. conductor arrivé en v2.7.0) n'y atterrissait jamais — donc ni ses
# scripts ni ses hooks (bandeau de mise à jour). Installe la fermeture transitive des manquants.
ensure_mandatory_baseline() {
  require_cache
  local mod m
  for mod in $(list_available_modules); do
    module_is_mandatory "$mod" || continue
    [ "$(module_version_installed "$mod")" = "—" ] || continue
    log "Baseline (INST-02a) : module obligatoire '$mod' absent du lab → installation"
    while IFS= read -r m; do
      m="${m%$'\r'}"   # ceinture ADR-052 : jamais de nom de module \r-suffixé (résolveur sous jq Windows)
      [ -n "$m" ] || continue
      [ "$(module_version_installed "$m")" = "—" ] && install_module "$m"
    done < <(resolve_closure "$mod")
  done
}

# ---------- Modules retirés (convergence, CONS-01) ----------
# Un module supprimé du parc (ex. feature-dev-gates, fusionné dans software-architecture) laisse des
# artefacts ORPHELINS dans les labs qui l'avaient installé. uninstall_module lit les artefacts DEPUIS
# le cache — absent pour un module retiré — donc le nettoyage s'appuie sur un manifeste EN DUR :
# _internal/retired-modules.txt (format `module:artefact` relatif à TARGET_ROOT, une ligne/artefact ;
# `#` = commentaire). Idempotent : ne retire que ce qui existe encore. Appelé à `update --all`.
find_retired_manifest() {
  local c
  c="$CACHE_DIR/_internal/retired-modules.txt"; [ -f "$c" ] && { echo "$c"; return 0; }
  c="$(dirname "$0")/retired-modules.txt"; [ -f "$c" ] && { echo "$c"; return 0; }
  echo ""
}

cleanup_retired_modules() {
  local manifest
  manifest="$(find_retired_manifest)"
  [ -n "$manifest" ] || return 0
  local line mod artifact target in_registry
  while IFS= read -r line; do
    case "$line" in ''|\#*) continue ;; esac
    mod="${line%%:*}"
    artifact="${line#*:}"
    [ -n "$mod" ] && [ -n "$artifact" ] || continue
    target="$TARGET_ROOT/$artifact"
    in_registry="no"
    [ "$(module_version_installed "$mod")" = "—" ] || in_registry="yes"
    # Rien à faire si ni artefact orphelin ni entrée de registre pour ce module.
    if [ ! -e "$target" ] && [ "$in_registry" = "no" ]; then
      continue
    fi
    log "Module retiré '$mod' détecté dans ce lab → nettoyage (convergence)"
    [ -e "$target" ] && rm -rf "$target" && log "  removed $target"
    [ "$in_registry" = "yes" ] && mark_uninstalled "$mod"
  done < "$manifest"
}

# ---------- Install ----------
install_module() {
  local mod="$1"
  require_cache

  local module_dir="$CACHE_DIR/$mod"
  [ -d "$module_dir" ] || err "Module $mod introuvable dans $CACHE_DIR"

  local version
  version=$(module_version_available "$mod")
  log "Installation $mod $version (scope=$VF_SCOPE → $TARGET_ROOT)..."

  # Backup if existing install
  local installed
  installed=$(module_version_installed "$mod")
  if [ "$installed" != "—" ]; then
    log "  Module déjà installé ($installed). Backup avant overwrite..."
    backup_module "$mod"
  fi

  # Type 1 — Single-skill module : SKILL.md at module root
  if [ -f "$module_dir/SKILL.md" ]; then
    mkdir -p "$TARGET_ROOT/skills/$mod"
    cp "$module_dir/SKILL.md" "$TARGET_ROOT/skills/$mod/SKILL.md"
    log "  copied SKILL.md → $TARGET_ROOT/skills/$mod/"
  fi

  # Type 2 — Multi-skills module : skills/<name>/SKILL.md (e.g., skill-creator with 2 nested skills)
  if [ -d "$module_dir/skills" ]; then
    for skill_dir in "$module_dir/skills/"*/; do
      [ -d "$skill_dir" ] || continue
      skill_name=$(basename "$skill_dir")
      mkdir -p "$TARGET_ROOT/skills/$skill_name"
      cp -r "$skill_dir"* "$TARGET_ROOT/skills/$skill_name/" 2>/dev/null || true
      log "  copied nested skill → $TARGET_ROOT/skills/$skill_name/"
    done
  fi

  # Type 3 — Agent module : AGENT.md → $TARGET_ROOT/agents/<mod>.md
  if [ -f "$module_dir/AGENT.md" ]; then
    mkdir -p "$TARGET_ROOT/agents"
    cp "$module_dir/AGENT.md" "$TARGET_ROOT/agents/${mod}.md"
    log "  copied AGENT.md → $TARGET_ROOT/agents/${mod}.md"
  fi

  # Type 3b — Multi-agents module : agents/<name>.md → $TARGET_ROOT/agents/<name>.md (chacun)
  # Symétrique du multi-skills (skills/<name>/). Un module peut livrer plusieurs agents.
  if [ -d "$module_dir/agents" ]; then
    mkdir -p "$TARGET_ROOT/agents"
    for agent_md in "$module_dir/agents/"*.md; do
      [ -f "$agent_md" ] || continue
      cp "$agent_md" "$TARGET_ROOT/agents/$(basename "$agent_md")"
      log "  copied agent → $TARGET_ROOT/agents/$(basename "$agent_md")"
    done
  fi

  # Type 4 — Doc-only module : content/ → docs/<mod>/
  # EXCEPTION scope : la doc reste relative au cwd PROJET (ce n'est pas du .claude),
  # donc PAS rebasée sur TARGET_ROOT même en scope user.
  if [ -d "$module_dir/content" ]; then
    local doc_target="docs/$mod"
    mkdir -p "$doc_target"
    cp -r "$module_dir/content/"* "$doc_target/" 2>/dev/null || true
    log "  copied content/ → $doc_target/ (doc module, hors TARGET_ROOT)"
  fi

  # Type 5 — Rules : rules/*.md → $TARGET_ROOT/rules/ (rules path-scopées auto-chargées)
  if [ -d "$module_dir/rules" ]; then
    mkdir -p "$TARGET_ROOT/rules"
    cp "$module_dir/rules/"*.md "$TARGET_ROOT/rules/" 2>/dev/null || true
    log "  copied rules/ → $TARGET_ROOT/rules/"
  fi

  # References folder at module root (companion to root SKILL.md)
  if [ -d "$module_dir/references" ] && [ -f "$module_dir/SKILL.md" ]; then
    mkdir -p "$TARGET_ROOT/skills/$mod/references"
    cp -r "$module_dir/references/"* "$TARGET_ROOT/skills/$mod/references/" 2>/dev/null || true
    log "  copied references/ → $TARGET_ROOT/skills/$mod/references/"
  fi

  # References folder for AGENT modules (D7) : un module agent (AGENT.md ou agents/ sans SKILL.md
  # racine) embarque ses references sous $TARGET_ROOT/agents/<mod>-references/ (chargées on-demand).
  if [ -d "$module_dir/references" ] && { [ -f "$module_dir/AGENT.md" ] || [ -d "$module_dir/agents" ]; } && [ ! -f "$module_dir/SKILL.md" ]; then
    mkdir -p "$TARGET_ROOT/agents/${mod}-references"
    cp -r "$module_dir/references/"* "$TARGET_ROOT/agents/${mod}-references/" 2>/dev/null || true
    log "  copied references/ → $TARGET_ROOT/agents/${mod}-references/"
  fi

  # Config folder at module root (companion to root SKILL.md) : templates de config projet.
  # Posé sous le dossier skill du module ; l'utilisateur copie le .example.json vers son projet.
  if [ -d "$module_dir/config" ] && [ -f "$module_dir/SKILL.md" ]; then
    mkdir -p "$TARGET_ROOT/skills/$mod/config"
    cp -r "$module_dir/config/"* "$TARGET_ROOT/skills/$mod/config/" 2>/dev/null || true
    log "  copied config/ → $TARGET_ROOT/skills/$mod/config/"
  fi

  # Scripts (top-level + tests subdir) : shell (.sh) et Node (.mjs/.js).
  copy_module_scripts "$mod"

  # Hook post-install (IDX-02 / D7) : si le module fournit build-gsd-index.sh, régénérer
  # l'index factuel in-place dans le dossier references agent. Best-effort : ne JAMAIS
  # faire échouer l'install si GSD est absent (l'index sera régénéré plus tard).
  if [ -f "$module_dir/scripts/build-gsd-index.sh" ] && [ -f "$TARGET_ROOT/scripts/build-gsd-index.sh" ]; then
    if VF_INDEX_OUT="$TARGET_ROOT/agents/${mod}-references/gsd-skills-index.md" \
       bash "$TARGET_ROOT/scripts/build-gsd-index.sh" >/dev/null 2>&1; then
      log "  index régénéré → $TARGET_ROOT/agents/${mod}-references/gsd-skills-index.md"
    else
      log "  (index non régénéré — GSD absent, best-effort)"
    fi
  fi

  # Commande d'incarnation (ADR-042) : tout agent posé devient invocable nativement via `/<mod>`
  # dans la fenêtre principale. Après la copie des scripts ci-dessus, le générateur est dispo.
  if [ -f "$module_dir/AGENT.md" ]; then
    generate_agent_command_for "$mod"
  fi

  # Injection MCP dérivée du lab (ADR-051) : si ce module a posé des agents, injecter dans les
  # exécutants flaggés (vf-mcp-consumer) les serveurs MCP que le lab déclare dans ./.mcp.json.
  # Le balayage est filtré par le flag → les agents planif/revue/audit restent inchangés.
  if [ -f "$module_dir/AGENT.md" ] || [ -d "$module_dir/agents" ]; then
    inject_lab_mcp_into_agents
  fi

  # Hooks de gouvernance (ADR-043) : fragment hooks/hooks.json → mergé dans settings.json.
  merge_module_hooks "$mod"

  # SCOPE-04 : en scope local seulement, ajouter les chemins installés au ./.gitignore.
  gitignore_add_paths "$mod"

  mark_installed "$mod" "$version"
  log "✓ $mod $version installé"
}

# ---------- Backup / Rollback ----------
backup_module() {
  local mod="$1"
  local ts
  ts=$(date +%Y%m%d-%H%M%S)
  local bdir="$BACKUP_DIR/$mod-$ts"
  mkdir -p "$bdir"
  [ -d "$TARGET_ROOT/skills/$mod" ] && cp -r "$TARGET_ROOT/skills/$mod" "$bdir/skills"
  # Agent module : AGENT.md installé + son dossier references (D7)
  [ -f "$TARGET_ROOT/agents/${mod}.md" ] && { mkdir -p "$bdir/agents"; cp "$TARGET_ROOT/agents/${mod}.md" "$bdir/agents/"; }
  [ -d "$TARGET_ROOT/agents/${mod}-references" ] && cp -r "$TARGET_ROOT/agents/${mod}-references" "$bdir/agent-references"
  # Scripts (les scripts du module sont mélangés avec les autres — backup uniquement les nommés dans le module)
  if [ -d "$CACHE_DIR/$mod/scripts" ]; then
    mkdir -p "$bdir/scripts"
    for f in "$CACHE_DIR/$mod/scripts/"*.sh; do
      name=$(basename "$f")
      [ -f "$TARGET_ROOT/scripts/$name" ] && cp "$TARGET_ROOT/scripts/$name" "$bdir/scripts/"
    done
  fi
  log "  backup → $bdir"
}

rollback_module() {
  local mod="$1"
  # Find latest backup
  local latest
  latest=$(ls -1dt "$BACKUP_DIR/$mod"-* 2>/dev/null | head -1)
  [ -z "$latest" ] && err "Aucun backup trouvé pour $mod dans $BACKUP_DIR"

  log "Rollback $mod depuis $latest..."
  if [ -d "$latest/skills" ]; then
    rm -rf "$TARGET_ROOT/skills/$mod"
    cp -r "$latest/skills" "$TARGET_ROOT/skills/$mod"
    log "  restored $TARGET_ROOT/skills/$mod"
  fi
  if [ -d "$latest/scripts" ]; then
    for f in "$latest/scripts/"*; do
      [ -f "$f" ] && cp "$f" "$TARGET_ROOT/scripts/" && chmod +x "$TARGET_ROOT/scripts/$(basename "$f")"
    done
    log "  restored scripts"
  fi
  log "✓ $mod rollback OK"
}

# ---------- Uninstall ----------
uninstall_module() {
  local mod="$1"
  log "Désinstallation $mod (scope=$VF_SCOPE → $TARGET_ROOT)..."
  backup_module "$mod"

  # Remove skill dir
  if [ -d "$TARGET_ROOT/skills/$mod" ]; then
    rm -rf "$TARGET_ROOT/skills/$mod"
    log "  removed $TARGET_ROOT/skills/$mod"
  fi

  # Remove agent module (AGENT.md installé + dossier references D7)
  if [ -f "$TARGET_ROOT/agents/${mod}.md" ]; then
    rm -f "$TARGET_ROOT/agents/${mod}.md"
    log "  removed $TARGET_ROOT/agents/${mod}.md"
  fi
  # Remove multi-agents (only those owned by this module)
  if [ -d "$CACHE_DIR/$mod/agents" ]; then
    for f in "$CACHE_DIR/$mod/agents/"*.md; do
      [ -f "$f" ] || continue
      name=$(basename "$f")
      [ -f "$TARGET_ROOT/agents/$name" ] && rm "$TARGET_ROOT/agents/$name" && log "  removed $TARGET_ROOT/agents/$name"
    done
  fi
  if [ -d "$TARGET_ROOT/agents/${mod}-references" ]; then
    rm -rf "$TARGET_ROOT/agents/${mod}-references"
    log "  removed $TARGET_ROOT/agents/${mod}-references"
  fi

  # Commande d'incarnation générée (ADR-042) : la retirer avec l'agent.
  if [ -f "$TARGET_ROOT/commands/${mod}.md" ]; then
    rm -f "$TARGET_ROOT/commands/${mod}.md"
    log "  removed $TARGET_ROOT/commands/${mod}.md"
  fi

  # Remove scripts (only those owned by this module : shell + Node)
  if [ -d "$CACHE_DIR/$mod/scripts" ]; then
    for f in "$CACHE_DIR/$mod/scripts/"*.sh "$CACHE_DIR/$mod/scripts/"*.mjs "$CACHE_DIR/$mod/scripts/"*.js; do
      [ -f "$f" ] || continue
      name=$(basename "$f")
      [ -f "$TARGET_ROOT/scripts/$name" ] && rm "$TARGET_ROOT/scripts/$name" && log "  removed $TARGET_ROOT/scripts/$name"
    done
  fi

  # Remove rules (only those owned by this module)
  if [ -d "$CACHE_DIR/$mod/rules" ]; then
    for f in "$CACHE_DIR/$mod/rules/"*.md; do
      name=$(basename "$f")
      [ -f "$TARGET_ROOT/rules/$name" ] && rm "$TARGET_ROOT/rules/$name" && log "  removed $TARGET_ROOT/rules/$name"
    done
  fi

  # Hooks de gouvernance (ADR-043) : retirer les entrées du module de settings.json.
  remove_module_hooks "$mod"

  mark_uninstalled "$mod"
  log "✓ $mod désinstallé"
}

# ---------- Status ----------
show_status() {
  require_cache
  printf "%-30s %-15s %-15s %s\n" "Module" "Installed" "Available" "Status"
  printf "%-30s %-15s %-15s %s\n" "------" "---------" "---------" "------"
  for mod in $(list_available_modules); do
    installed=$(module_version_installed "$mod")
    available=$(module_version_available "$mod")
    if [ "$installed" = "—" ]; then
      status="Not installed"
    elif [ "$installed" = "$available" ]; then
      status="Up to date"
    else
      status="Update available ($installed → $available)"
    fi
    printf "%-30s %-15s %-15s %s\n" "$mod" "$installed" "$available" "$status"
  done
}

# ---------- Update ----------
update_module() {
  local mod="$1"
  require_cache
  local installed available
  installed=$(module_version_installed "$mod")
  available=$(module_version_available "$mod")

  if [ "$installed" = "—" ]; then
    log "$mod n'est pas installé. Use 'install' au lieu de 'update'."
    return 1
  fi

  if [ "$installed" = "$available" ]; then
    # Version inchangée : pas de re-copie complète, mais on RE-SYNCHRONISE la gouvernance
    # (scripts + hooks). Rend /vf-update auto-réparateur si un hooks.json a dérivé sans bump
    # de VERSION — idempotent, best-effort.
    log "$mod déjà à jour ($installed) — resync gouvernance (scripts + hooks)"
    sync_module_governance "$mod"
    return 0
  fi

  log "Update $mod : $installed → $available"
  install_module "$mod"
}

# ---------- Main ----------
[ "$#" -lt 1 ] && {
  grep '^# ' "$0" | sed 's/^# //'
  exit 0
}

cmd="$1"
arg="${2:-}"

case "$cmd" in
  install)
    if [ "$arg" = "--all" ]; then
      require_cache
      for m in $(list_available_modules); do install_module "$m"; done
    elif [ "$arg" = "--with-deps" ]; then
      # install --with-deps <mod> : installe la fermeture transitive (résolveur câblé).
      deps_target="${3:-}"
      [ -n "$deps_target" ] || err "Usage: install --with-deps <module>"
      require_cache
      while IFS= read -r m; do
        m="${m%$'\r'}"   # ceinture ADR-052 : jamais de nom de module \r-suffixé (résolveur sous jq Windows)
        [ -n "$m" ] && install_module "$m"
      done < <(resolve_closure "$deps_target")
    elif [ -n "$arg" ]; then
      install_module "$arg"
    else
      err "Usage: install <module> | install --with-deps <module> | install --all"
    fi
    ;;
  update)
    if [ "$arg" = "--all" ]; then
      require_cache
      # Convergence AVANT la boucle : désenregistrer + nettoyer les modules retirés du parc
      # (CONS-01). Sinon la boucle tenterait d'`update_module` un module absent du cache
      # (install_module → err → abort) avant d'atteindre le nettoyage.
      cleanup_retired_modules
      if [ -f "$INSTALLED_REGISTRY" ]; then
        while IFS='=' read -r mod ver; do
          [ -n "$mod" ] && update_module "$mod"
        done < "$INSTALLED_REGISTRY"
        # Lab initialisé : garantir la baseline obligatoire (INST-02a). Un module `mandatory`
        # publié après la config du lab (conductor) est ainsi rattrapé au lieu d'être ignoré
        # à vie — c'est ce qui posait ses scripts + hooks manquants (bandeau /vf-update).
        ensure_mandatory_baseline
      else
        log "Aucun module installé"
      fi
    elif [ -n "$arg" ]; then
      update_module "$arg"
    else
      err "Usage: update <module> | update --all"
    fi
    ;;
  uninstall)
    if [ "$arg" = "--all" ]; then
      # uninstall --all : retire TOUS les modules listés dans le registre.
      # On fige la liste AVANT la boucle : uninstall_module → mark_uninstalled réécrit le
      # registre à chaque itération, donc on itère sur un snapshot, pas sur le fichier muté.
      if [ -f "$INSTALLED_REGISTRY" ]; then
        _to_remove=()
        while IFS='=' read -r mod _ver; do
          [ -n "$mod" ] && _to_remove+=("$mod")
        done < "$INSTALLED_REGISTRY"
        if [ "${#_to_remove[@]}" -eq 0 ]; then
          log "Aucun module installé (registre vide) — rien à désinstaller."
        else
          for mod in "${_to_remove[@]}"; do uninstall_module "$mod"; done
          log "✓ ${#_to_remove[@]} module(s) désinstallé(s)"
        fi
      else
        log "Aucun module installé (pas de registre) — rien à désinstaller."
      fi
    elif [ -n "$arg" ]; then
      uninstall_module "$arg"
    else
      err "Usage: uninstall <module> | uninstall --all"
    fi
    ;;
  rollback)
    [ -n "$arg" ] || err "Usage: rollback <module>"
    rollback_module "$arg"
    ;;
  status)
    show_status
    ;;
  sync)
    # No-op explicite (SCOPE-02) : la source est le cache fourni, plus de sync git.
    log "source = cache fourni (VIBEFLOW_CACHE=$CACHE_DIR), plus de sync git"
    ;;
  *)
    grep '^# ' "$0" | sed 's/^# //'
    exit 1
    ;;
esac
