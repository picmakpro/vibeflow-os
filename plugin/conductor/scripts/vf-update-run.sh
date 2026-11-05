#!/usr/bin/env bash
# vf-update-run.sh — Re-matérialise les modules installés depuis le cache plugin le PLUS RÉCENT.
#
# À lancer APRÈS la mise à jour du plugin sur le runtime actif (ex. `claude plugin update
# vibeflow`, ou son équivalent sur un autre runtime supporté) : ce geste pose la nouvelle version
# dans un nouveau dossier de cache, mais la session courante garde encore l'ancien
# ${CLAUDE_PLUGIN_ROOT}.
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

# Mode `offer <user|project> [module ...]` : suite de la proposition des modules nouveaux (étape 4d du
# skill). Ordre fixe : (1) calcule l'ensemble PRÉSENTÉ à l'humain (= `new-modules`, avant toute pose, sinon
# le registre a déjà bougé), (2) pose les modules ACCEPTÉS (fermeture de dépendances), (3) inscrit les seuls
# modules présentés — accord ou refus, un module présenté n'est proposé qu'une fois ; un module accepté puis
# désinstallé ne revient pas. Sans module : tout est refusé. `new-modules` en échec = rien n'est posé ni inscrit.
# Exception (BL35-A1, arbitrage Samuel, AskUserQuestion session principale, 2026-11-05) : un module dont la pose
# échoue est dé-marqué (`unmark-offered`) et revient au prochain /vf-update. Code de sortie non nul (BL35-A3,
# même arbitrage) sur nom refusé, module non présenté, pose en échec, inscription ou dé-marquage en échec.
# Pose vide (BL35-A3, « Échec dans les deux cas », Samuel, AskUserQuestion session principale, 2026-11-05) : un
# `install --with-deps` en rc 0 qui n'a pas inscrit le module au registre du scope est un échec (dé-marqué, rc≠0).
if [ "${1:-}" = "offer" ]; then
  scope="${2:-}"
  case "$scope" in user|project) ;; *) echo "usage : vf-update-run.sh offer <user|project> [module ...]" >&2; exit 64 ;; esac
  shift 2
  presented=()
  if ! listed="$(VIBEFLOW_CACHE="$NEW" bash "$ENGINE" --scope "$scope" new-modules)"; then
    echo "[vf-update-run] modules nouveaux illisibles (scope $scope) : rien n'est posé ni inscrit" >&2; exit 1
  fi
  while IFS= read -r l; do
    [[ "$l" =~ ^([a-z0-9-]+)=[A-Za-z0-9._+-]+$ ]] && presented+=("${BASH_REMATCH[1]}")
  done <<< "$listed"
  rc=0; failed=()
  if [ "$scope" = user ]; then regroot="$HOME/.claude"; else regroot="./.claude"; fi
  for m in "$@"; do
    case "$m" in ''|*[!a-z0-9-]*) echo "[vf-update-run] nom de module refusé : $m" >&2; rc=1; continue ;; esac
    # Seuls les modules PRÉSENTÉS (calculés en tête de mode) se posent : un module hors de cet ensemble
    # (non proposable, déjà posé, écarté du poste…) est refusé, jamais installé.
    case " ${presented[*]-} " in *" $m "*) ;; *) echo "[vf-update-run] module non présenté, refusé (rien posé) : $m" >&2; rc=1; continue ;; esac
    if ! VIBEFLOW_CACHE="$NEW" bash "$ENGINE" --scope "$scope" install --with-deps "$m"; then
      echo "[vf-update-run] pose en échec : $m (scope $scope)" >&2; rc=1; failed+=("$m")
    elif ! grep -q "^$m=" "$regroot/scripts/.vibeflow-installed" 2>/dev/null; then
      # `install --with-deps` rend rc=0 sur une dépendance inconnue sans rien poser : pose vide = échec.
      echo "[vf-update-run] pose vide : $m absent du registre $scope après install (dépendance inconnue ?)" >&2; rc=1; failed+=("$m")
    fi
  done
  VIBEFLOW_CACHE="$NEW" bash "$ENGINE" --scope "$scope" mark-offered ${presented[@]+"${presented[@]}"} || rc=1
  # BL35-A1 (arbitrage Samuel, AskUserQuestion session principale, 2026-11-05 : « Le reproposer ») : un module
  # dont la pose a échoué n'est pas « déjà proposé » — sa marque est retirée, il revient au prochain /vf-update.
  # BL35-A3 : le code de sortie reste non nul (pose en échec, mark-offered ou dé-marquage en échec).
  if [ "${#failed[@]}" -gt 0 ]; then
    VIBEFLOW_CACHE="$NEW" bash "$ENGINE" --scope "$scope" unmark-offered "${failed[@]}" || rc=1
  fi
  exit "$rc"
fi

run_scope() {
  local scope="$1" root="$2" l m d deps closure listed
  [ -f "$root/scripts/.vibeflow-installed" ] || return 1
  echo "[vf-update-run] scope $scope → update --all ($root)"
  VIBEFLOW_CACHE="$NEW" bash "$ENGINE" --scope "$scope" update --all
  # Modules du catalogue absents du registre et jamais proposés : listés, JAMAIS posés d'office (ADR-031).
  # Format stable : `NOUVEAU_MODULE scope=<s> <module>=<version> deps=<a,b|->` ; deps = fermeture des `requires`
  # moins le module et moins ce que le registre de CE scope porte déjà (ce que `install --with-deps` posera aussi).
  # `deps=?` si la fermeture n'est pas calculable : jamais un `-` qui dirait « rien de plus ».
  # Un échec du calcul se DISTINGUE de « rien à proposer » : ligne stable NOUVEAUX_MODULES_ERREUR, la mise à jour
  # déjà faite n'est pas remise en cause (la skill le signale à l'humain).
  if ! listed="$(VIBEFLOW_CACHE="$NEW" bash "$ENGINE" --scope "$scope" new-modules)"; then
    echo "[vf-update-run] NOUVEAUX_MODULES_ERREUR scope=$scope"
    return 0
  fi
  while IFS= read -r l; do
    [[ "$l" =~ ^([a-z0-9-]+)=[A-Za-z0-9._+-]+$ ]] || continue
    m="${BASH_REMATCH[1]}"; deps=""
    if closure="$(VF_MODULES_ROOT="$NEW" bash "$NEW/_internal/resolve-deps.sh" "$m" 2>/dev/null)"; then
      while IFS= read -r d; do
        [ -n "$d" ] && [ "$d" != "$m" ] && ! grep -q "^${d}=" "$root/scripts/.vibeflow-installed" && deps="${deps:+$deps,}$d"
      done <<< "$closure"
      [ -n "$deps" ] || deps="-"
    else
      deps="?"
    fi
    echo "[vf-update-run] NOUVEAU_MODULE scope=$scope $l deps=$deps"
  done <<< "$listed"
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
# la version POST-mise-à-jour parce que l'étape 4a du skill (mise à jour du plugin sur le runtime
# actif) tourne avant ce script et a déjà réécrit installed_plugins.json, source de "installed".
# Appelée même quand
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
