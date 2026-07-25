#!/usr/bin/env bash
# check-release-tag.sh — Guard de discipline de release (repo vibeflow-os).
#
# Règle : toute valeur de la VERSION racine DOIT correspondre à un tag git annoté vX.Y.Z.
# Une release sans tag n'est ni traçable ni installable par référence — c'est ce qui a fait
# diverger main en juillet 2026 (v2.10→v2.16 publiées mais non taggées).
#
# Usage :
#   check-release-tag.sh            # la VERSION courante est-elle taggée localement ? · exit 1 sinon
#   check-release-tag.sh --remote   # vérifie AUSSI que le tag est poussé sur origin
#   check-release-tag.sh --help
#
# Codes de sortie : 0 = conforme · 1 = tag manquant · 2 = usage/erreur
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "[check-release-tag] pas un repo git" >&2; exit 2; }
VERSION_FILE="$ROOT/VERSION"
[ -f "$VERSION_FILE" ] || { echo "[check-release-tag] VERSION introuvable à la racine du repo" >&2; exit 2; }

REMOTE=false
for a in "$@"; do
  case "$a" in
    --remote)  REMOTE=true ;;
    -h|--help) grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
    *) echo "[check-release-tag] argument inconnu : $a" >&2; exit 2 ;;
  esac
done

raw="$(tr -d '[:space:]' < "$VERSION_FILE")"
[ -n "$raw" ] || { echo "[check-release-tag] VERSION vide" >&2; exit 2; }
# Tag canonique = vX.Y.Z (préfixe v garanti quel que soit le contenu du fichier).
case "$raw" in v*) tag="$raw" ;; *) tag="v$raw" ;; esac

if ! git rev-parse -q --verify "refs/tags/$tag" >/dev/null; then
  echo "[check-release-tag] ✗ VERSION=$raw mais AUCUN tag local $tag." >&2
  echo "  → git tag -a $tag -m \"$tag — <résumé>\" <commit> && git push origin $tag" >&2
  exit 1
fi

if $REMOTE && [ -z "$(git ls-remote --tags origin "refs/tags/$tag" 2>/dev/null)" ]; then
  echo "[check-release-tag] ✗ tag $tag présent en local mais PAS poussé sur origin." >&2
  echo "  → git push origin $tag" >&2
  exit 1
fi

# Cohérence inter-fichiers (ADR-054) : la fiche marketplace et les badges README avaient dérivé
# de 2 releases (fiche 2.26.0 / installé 2.27.1, vécu terrain). Délégué à check-version-sync.sh.
# F23 : l'absence du script délégué désactivait silencieusement la moitié du gate — désormais
# c'est une erreur d'intégrité (exit 2), pas un skip.
SYNC="$ROOT/scripts/check-version-sync.sh"
if [ ! -f "$SYNC" ]; then
  echo "[check-release-tag] ✗ scripts/check-version-sync.sh introuvable — gate de synchro non exécutable (intégrité du repo)" >&2
  exit 2
fi
bash "$SYNC" >/dev/null 2>&1 || { bash "$SYNC" >&2 || true; exit 1; }

suffix=""; $REMOTE && suffix=" (poussé sur origin)"
echo "[check-release-tag] ✓ VERSION=$raw ↔ tag $tag${suffix}"
exit 0
