#!/usr/bin/env bash
# verify-runtime-reversibility.sh — preuve fichier à fichier qu'une bascule de runtime est
# réversible (MIGR-04, Phase 38, D-38-C). Ne compte JAMAIS des fichiers — compare deux ENSEMBLES
# via `comm -3` sur des listes triées, la seule preuve que deux arbres sont identiques (un compte
# égal peut masquer un fichier différent au même total).
#
# Hypothèse d'entrée : <chemin> est une cible DÉJÀ installée (au moins un module posé, registre
# `scripts/.vibeflow-installed` présent) — c'est l'état réel d'un lab qu'un opérateur envisage de
# faire basculer. Ce script prouve UNIQUEMENT le cycle bascule -> retour (l'installation initiale
# est un geste antérieur, hors périmètre de cette preuve — `vf-calibrate` l'invoque sur une cible
# déjà peuplée, jamais sur une cible vierge).
#
# Cycle :
#   1. Capture l'arbre AVANT (état courant de la cible).
#   2. Bascule simulée : `vibeflow-update.sh --target <chemin> install --all` (RÉUTILISE l'
#      injection de cible du lot 4, jamais une 2e implémentation de pose — D-38-C).
#   3. Capture l'arbre APRÈS-BASCULE.
#   4. Retour : `rollback <mod>` pour CHAQUE module du registre de la cible (lot 3, ROLL).
#   5. Capture l'arbre APRÈS-RETOUR.
#   6. `comm -3 <avant> <après-retour>` — vide -> réversibilité prouvée ; non vide -> la diff est
#      imprimée en clair, jamais un succès masqué.
#
# Usage:
#   verify-runtime-reversibility.sh --target <chemin> [--cache <chemin>]
#   verify-runtime-reversibility.sh -h|--help
#
# --cache <chemin> : surcharge VIBEFLOW_CACHE pour l'appel `install --all` de l'étape 2 (sinon la
#   variable d'env VIBEFLOW_CACHE déjà exportée par l'appelant est utilisée telle quelle).
#
# Exit codes:
#   0 = réversibilité prouvée (comm -3 vide).
#   1 = réversibilité NON prouvée (comm -3 non vide, diff imprimée).
#   2 = erreur d'usage (--target manquant, VIBEFLOW_CACHE absent des deux sources).
#   3 = INDÉTERMINÉ — installer introuvable, cible sans registre installé (précondition non
#       remplie), ou une étape du cycle (install/rollback) a échoué avant toute mesure.
set -uo pipefail

TARGET=""
CACHE_OVERRIDE=""

usage() {
  grep '^# ' "$0" | sed 's/^# //'
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --target)
      [ "$#" -ge 2 ] || { echo "[verify-runtime-reversibility] --target nécessite une valeur" >&2; exit 2; }
      TARGET="$2"
      shift 2
      ;;
    --cache)
      [ "$#" -ge 2 ] || { echo "[verify-runtime-reversibility] --cache nécessite une valeur" >&2; exit 2; }
      CACHE_OVERRIDE="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "[verify-runtime-reversibility] argument inconnu : $1" >&2
      exit 2
      ;;
  esac
done

[ -n "$TARGET" ] || { echo "[verify-runtime-reversibility] usage : verify-runtime-reversibility.sh --target <chemin> [--cache <chemin>]" >&2; exit 2; }
[ -n "$CACHE_OVERRIDE" ] && export VIBEFLOW_CACHE="$CACHE_OVERRIDE"
[ -n "${VIBEFLOW_CACHE:-}" ] || { echo "[verify-runtime-reversibility] VIBEFLOW_CACHE requis (--cache ou variable d'env déjà exportée)" >&2; exit 2; }

log() { echo "[verify-runtime-reversibility] $*" >&2; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# plugin/conductor/scripts -> racine du dépôt -> plugin/_internal/vibeflow-update.sh (même
# patron de résolution que find_fidelity_gate dans check-artifact-fidelity.sh voisin).
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
INSTALLER="$REPO_ROOT/plugin/_internal/vibeflow-update.sh"
[ -f "$INSTALLER" ] || { echo "[verify-runtime-reversibility] installer introuvable : $INSTALLER" >&2; exit 3; }

[ -d "$TARGET" ] || { echo "[verify-runtime-reversibility] cible introuvable : $TARGET" >&2; exit 3; }
REGISTRY="$TARGET/scripts/.vibeflow-installed"
[ -f "$REGISTRY" ] || { echo "[verify-runtime-reversibility] cible '$TARGET' sans registre installé ($REGISTRY absent) — précondition non remplie, aucun module à basculer/rollback" >&2; exit 3; }

capture_tree() {
  # `.backups/` est exclu (D-31-03 : le contenu d'un backup n'est jamais un artefact de pose) —
  # sans cette exclusion, la bascule elle-même écrit un NOUVEAU répertoire de backup à chaque
  # passage, et la preuve échouerait systématiquement sur cet artefact du MÉCANISME plutôt que
  # sur l'état réel du module basculé/restauré (celui que MIGR-04 doit prouver).
  find "$TARGET" -type f -not -path "$TARGET/.backups/*" 2>/dev/null | LC_ALL=C sort
}

BEFORE_FILE="$(mktemp)"
AFTER_RETOUR_FILE="$(mktemp)"
trap 'rm -f "$BEFORE_FILE" "$AFTER_RETOUR_FILE"' EXIT

log "1/3 capture de l'arbre AVANT"
capture_tree > "$BEFORE_FILE"

log "2/3 bascule simulée : install --all sur '$TARGET'"
if ! bash "$INSTALLER" --target "$TARGET" install --all >&2; then
  echo "[verify-runtime-reversibility] échec de la bascule simulée (install --all) — aucune mesure produite" >&2
  exit 3
fi

log "3/3 retour : rollback module par module (registre '$REGISTRY')"
while IFS='=' read -r mod _version; do
  [ -n "$mod" ] || continue
  case "$mod" in \#*) continue ;; esac
  log "  rollback $mod"
  if ! bash "$INSTALLER" --target "$TARGET" rollback "$mod" >&2; then
    echo "[verify-runtime-reversibility] échec du rollback de '$mod' — cycle incomplet, aucune mesure fiable" >&2
    exit 3
  fi
done < "$REGISTRY"

capture_tree > "$AFTER_RETOUR_FILE"

DIFF="$(comm -3 "$BEFORE_FILE" "$AFTER_RETOUR_FILE")"
if [ -z "$DIFF" ]; then
  N="$(wc -l < "$BEFORE_FILE" | tr -d ' ')"
  echo "[verify-runtime-reversibility] ✓ réversibilité prouvée ($N fichiers comparés, ensembles identiques)"
  exit 0
else
  echo "[verify-runtime-reversibility] ✗ réversibilité NON prouvée — différence (comm -3, colonne 1 = seulement AVANT, colonne 2 = seulement APRÈS-RETOUR) :" >&2
  echo "$DIFF" >&2
  exit 1
fi
