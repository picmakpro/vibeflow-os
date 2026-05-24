#!/usr/bin/env bash
# vibeflow-update.sh — Installeur/updateur des modules vibeflow-os dans un lab
#
# Usage:
#   ./vibeflow-update.sh install <module>          # Installe un module
#   ./vibeflow-update.sh install --all             # Installe tous les modules dispo
#   ./vibeflow-update.sh update <module>           # Met à jour un module installé
#   ./vibeflow-update.sh update --all              # Met à jour tous les modules installés
#   ./vibeflow-update.sh uninstall <module>        # Désinstalle un module
#   ./vibeflow-update.sh rollback <module>         # Restore depuis backup
#   ./vibeflow-update.sh status                    # Liste modules installés + versions
#   ./vibeflow-update.sh sync                      # Re-tire le cache depuis le repo central
#
# Pré-requis : .vibeflow-cache/ existe (git clone du repo picmakpro/vibeflow-os)
# Sinon : git clone --depth 1 https://github.com/picmakpro/vibeflow-os.git .vibeflow-cache

set -euo pipefail

CACHE_DIR="${VIBEFLOW_CACHE:-.vibeflow-cache}"
INSTALLED_REGISTRY=".claude/scripts/.vibeflow-installed"
BACKUP_DIR=".claude/.backups"
REPO_URL="https://github.com/picmakpro/vibeflow-os.git"

# ---------- Helpers ----------
log() { echo "[vibeflow-update] $*" >&2; }
err() { echo "[vibeflow-update] ERROR: $*" >&2; exit 1; }

ensure_cache() {
  if [ ! -d "$CACHE_DIR" ]; then
    log "Cache $CACHE_DIR absent. Clone du repo..."
    git clone --depth 1 "$REPO_URL" "$CACHE_DIR" 2>&1 | tail -5
  fi
}

sync_cache() {
  ensure_cache
  log "Sync cache $CACHE_DIR..."
  (cd "$CACHE_DIR" && git pull --depth 1 origin main 2>&1 | tail -3)
}

list_available_modules() {
  ensure_cache
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

# ---------- Install ----------
install_module() {
  local mod="$1"
  ensure_cache

  local module_dir="$CACHE_DIR/$mod"
  [ -d "$module_dir" ] || err "Module $mod introuvable dans $CACHE_DIR"

  local version
  version=$(module_version_available "$mod")
  log "Installation $mod $version..."

  # Backup if existing install
  local installed
  installed=$(module_version_installed "$mod")
  if [ "$installed" != "—" ]; then
    log "  Module déjà installé ($installed). Backup avant overwrite..."
    backup_module "$mod"
  fi

  # Skill files
  if [ -f "$module_dir/SKILL.md" ]; then
    mkdir -p ".claude/skills/$mod"
    cp "$module_dir/SKILL.md" ".claude/skills/$mod/SKILL.md"
    log "  copied SKILL.md → .claude/skills/$mod/"
  fi

  if [ -d "$module_dir/references" ]; then
    mkdir -p ".claude/skills/$mod/references"
    cp -r "$module_dir/references/"* ".claude/skills/$mod/references/" 2>/dev/null || true
    log "  copied references/ → .claude/skills/$mod/references/"
  fi

  # Scripts (top-level + tests subdir)
  if [ -d "$module_dir/scripts" ]; then
    mkdir -p ".claude/scripts"
    for f in "$module_dir/scripts/"*.sh; do
      [ -f "$f" ] && cp "$f" ".claude/scripts/" && chmod +x ".claude/scripts/$(basename "$f")"
    done
    if [ -d "$module_dir/scripts/tests" ]; then
      mkdir -p ".claude/scripts/tests/fixtures"
      cp -r "$module_dir/scripts/tests/"*.sh ".claude/scripts/tests/" 2>/dev/null || true
      cp -r "$module_dir/scripts/tests/fixtures/"* ".claude/scripts/tests/fixtures/" 2>/dev/null || true
      chmod +x .claude/scripts/tests/*.sh 2>/dev/null || true
    fi
    log "  copied scripts/ → .claude/scripts/"
  fi

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
  [ -d ".claude/skills/$mod" ] && cp -r ".claude/skills/$mod" "$bdir/skills"
  # Scripts (les scripts du module sont mélangés avec les autres — backup uniquement les nommés dans le module)
  if [ -d "$CACHE_DIR/$mod/scripts" ]; then
    mkdir -p "$bdir/scripts"
    for f in "$CACHE_DIR/$mod/scripts/"*.sh; do
      name=$(basename "$f")
      [ -f ".claude/scripts/$name" ] && cp ".claude/scripts/$name" "$bdir/scripts/"
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
    rm -rf ".claude/skills/$mod"
    cp -r "$latest/skills" ".claude/skills/$mod"
    log "  restored .claude/skills/$mod"
  fi
  if [ -d "$latest/scripts" ]; then
    for f in "$latest/scripts/"*; do
      [ -f "$f" ] && cp "$f" ".claude/scripts/" && chmod +x ".claude/scripts/$(basename "$f")"
    done
    log "  restored scripts"
  fi
  log "✓ $mod rollback OK"
}

# ---------- Uninstall ----------
uninstall_module() {
  local mod="$1"
  log "Désinstallation $mod..."
  backup_module "$mod"

  # Remove skill dir
  if [ -d ".claude/skills/$mod" ]; then
    rm -rf ".claude/skills/$mod"
    log "  removed .claude/skills/$mod"
  fi

  # Remove scripts (only those owned by this module)
  if [ -d "$CACHE_DIR/$mod/scripts" ]; then
    for f in "$CACHE_DIR/$mod/scripts/"*.sh; do
      name=$(basename "$f")
      [ -f ".claude/scripts/$name" ] && rm ".claude/scripts/$name" && log "  removed .claude/scripts/$name"
    done
  fi

  mark_uninstalled "$mod"
  log "✓ $mod désinstallé"
}

# ---------- Status ----------
show_status() {
  ensure_cache
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
  sync_cache
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
      ensure_cache
      for m in $(list_available_modules); do install_module "$m"; done
    elif [ -n "$arg" ]; then
      install_module "$arg"
    else
      err "Usage: install <module> | install --all"
    fi
    ;;
  update)
    if [ "$arg" = "--all" ]; then
      sync_cache
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
    [ -n "$arg" ] || err "Usage: uninstall <module>"
    uninstall_module "$arg"
    ;;
  rollback)
    [ -n "$arg" ] || err "Usage: rollback <module>"
    rollback_module "$arg"
    ;;
  status)
    show_status
    ;;
  sync)
    sync_cache
    ;;
  *)
    grep '^# ' "$0" | sed 's/^# //'
    exit 1
    ;;
esac
