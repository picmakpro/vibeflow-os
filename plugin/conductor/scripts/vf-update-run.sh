#!/usr/bin/env bash
# vf-update-run.sh — Re-matérialise les modules installés depuis le cache plugin le PLUS RÉCENT.
#
# À lancer APRÈS `claude plugin update vibeflow` : ce dernier pose la nouvelle version dans un
# nouveau dossier de cache, mais la session courante garde encore l'ancien ${CLAUDE_PLUGIN_ROOT}.
# Ce script localise LUI-MÊME le cache le plus récent, puis relance l'engine `update --all` pour
# chaque scope ayant un registre d'install (.vibeflow-installed). Idempotent, best-effort.
#
# Usage : vf-update-run.sh [--scope user|project]   (défaut : détecte les deux)
set -uo pipefail

CACHE_BASE="${VF_CACHE_BASE:-$HOME/.claude/plugins/cache/vibeflow-os/vibeflow}"
ONLY_SCOPE="${2:-}"
[ "${1:-}" = "--scope" ] || ONLY_SCOPE=""

[ -d "$CACHE_BASE" ] || { echo "[vf-update-run] cache plugin introuvable ($CACHE_BASE) — le plugin vibeflow est-il installé ?" >&2; exit 1; }

# Version la plus récente présente dans le cache (tri semver sur le nom de dossier).
NEW="$(ls -d "$CACHE_BASE"/*/ 2>/dev/null | sed 's:/*$::' | sort -V | tail -1)"
[ -n "$NEW" ] || { echo "[vf-update-run] aucune version dans le cache $CACHE_BASE" >&2; exit 1; }
ENGINE="$NEW/_internal/vibeflow-update.sh"
[ -f "$ENGINE" ] || { echo "[vf-update-run] engine introuvable : $ENGINE" >&2; exit 1; }
echo "[vf-update-run] cache le plus récent : $(basename "$NEW")"

run_scope() {
  local scope="$1" root="$2"
  [ -f "$root/scripts/.vibeflow-installed" ] || return 1
  echo "[vf-update-run] scope $scope → update --all ($root)"
  VIBEFLOW_CACHE="$NEW" bash "$ENGINE" --scope "$scope" update --all
  return 0
}

updated=0
if [ -z "$ONLY_SCOPE" ] || [ "$ONLY_SCOPE" = "user" ]; then
  run_scope user "$HOME/.claude" && updated=1
fi
if [ -z "$ONLY_SCOPE" ] || [ "$ONLY_SCOPE" = "project" ]; then
  run_scope project "./.claude" && updated=1
fi

[ "$updated" -eq 1 ] || echo "[vf-update-run] aucun module installé (pas de registre user/project) — rien à re-matérialiser."

# Rafraîchit (inconditionnellement) le cache lu par le bandeau SessionStart. Le bandeau
# (update-banner.sh) lit un cache écrit en TÂCHE DE FOND par la session précédente — /vf-update ne
# le touchait jamais, d'où un faux positif « mise à jour disponible » qui survivait un redémarrage
# entier. On invalide AVANT de régénérer, jamais l'inverse : check-plugin-update.sh garde
# délibérément l'ancien cache quand le réseau est KO, donc régénérer seul laisserait le faux
# positif intact exactement là où on ne peut pas le corriger. La relecture est synchrone et donne
# la version POST-mise-à-jour parce que l'étape 4a du skill (claude plugin update) tourne avant ce
# script et a déjà réécrit installed_plugins.json, source de "installed". Appelée même quand
# updated=0 : la péremption vient de la version du plugin, pas de la présence d'un registre de
# modules. Si un rafraîchissement de fond tient déjà .check.lock, le vérificateur sort
# immédiatement sans rien écrire — le cache reste absent, ce qui est le bon état de repli (pas de
# bandeau plutôt qu'un faux positif), pas une régression.
refresh_update_banner_cache() {
  local cache="${XDG_CACHE_HOME:-$HOME/.cache}/vibeflow/update-check.json"
  rm -f "$cache" 2>/dev/null || true

  local checker="$NEW/conductor/scripts/check-plugin-update.sh"
  if [ ! -f "$checker" ]; then
    checker="$(cd "$(dirname "$0")" && pwd)/check-plugin-update.sh"
  fi
  if [ ! -f "$checker" ]; then
    echo "[vf-update-run] vérificateur de bandeau introuvable — cache invalidé, le prochain démarrage le régénérera."
    return 0
  fi

  bash "$checker" >/dev/null 2>&1 || true
  if [ -f "$cache" ]; then
    echo "[vf-update-run] cache du bandeau invalidé puis régénéré."
  else
    echo "[vf-update-run] cache du bandeau invalidé, régénération indisponible — le prochain démarrage le régénérera."
  fi
}
refresh_update_banner_cache

exit 0
