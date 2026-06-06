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
    [ -d "$module_dir/references" ] && gitignore_add_one ".claude/agents/${mod}-references/"
  fi
  # Rules réellement posées.
  if [ -d "$module_dir/rules" ]; then
    for f in "$module_dir/rules/"*.md; do
      [ -f "$f" ] && gitignore_add_one ".claude/rules/$(basename "$f")"
    done
  fi
  # Scripts réellement posés.
  if [ -d "$module_dir/scripts" ]; then
    for f in "$module_dir/scripts/"*.sh; do
      [ -f "$f" ] && gitignore_add_one ".claude/scripts/$(basename "$f")"
    done
  fi
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

  # References folder for AGENT modules (D7) : un module agent (AGENT.md sans SKILL.md racine)
  # embarque ses references sous $TARGET_ROOT/agents/<mod>-references/ (chargées on-demand).
  if [ -d "$module_dir/references" ] && [ -f "$module_dir/AGENT.md" ]; then
    mkdir -p "$TARGET_ROOT/agents/${mod}-references"
    cp -r "$module_dir/references/"* "$TARGET_ROOT/agents/${mod}-references/" 2>/dev/null || true
    log "  copied references/ → $TARGET_ROOT/agents/${mod}-references/"
  fi

  # Scripts (top-level + tests subdir)
  if [ -d "$module_dir/scripts" ]; then
    mkdir -p "$TARGET_ROOT/scripts"
    for f in "$module_dir/scripts/"*.sh; do
      [ -f "$f" ] && cp "$f" "$TARGET_ROOT/scripts/" && chmod +x "$TARGET_ROOT/scripts/$(basename "$f")"
    done
    if [ -d "$module_dir/scripts/tests" ]; then
      mkdir -p "$TARGET_ROOT/scripts/tests/fixtures"
      cp -r "$module_dir/scripts/tests/"*.sh "$TARGET_ROOT/scripts/tests/" 2>/dev/null || true
      cp -r "$module_dir/scripts/tests/fixtures/"* "$TARGET_ROOT/scripts/tests/fixtures/" 2>/dev/null || true
      chmod +x "$TARGET_ROOT"/scripts/tests/*.sh 2>/dev/null || true
    fi
    log "  copied scripts/ → $TARGET_ROOT/scripts/"
  fi

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
  if [ -d "$TARGET_ROOT/agents/${mod}-references" ]; then
    rm -rf "$TARGET_ROOT/agents/${mod}-references"
    log "  removed $TARGET_ROOT/agents/${mod}-references"
  fi

  # Remove scripts (only those owned by this module)
  if [ -d "$CACHE_DIR/$mod/scripts" ]; then
    for f in "$CACHE_DIR/$mod/scripts/"*.sh; do
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
    log "$mod déjà à jour ($installed)"
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
      if [ -f "$INSTALLED_REGISTRY" ]; then
        while IFS='=' read -r mod ver; do
          [ -n "$mod" ] && update_module "$mod"
        done < "$INSTALLED_REGISTRY"
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
