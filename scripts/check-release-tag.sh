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
#                                   # ET qu'une release GitHub existe pour ce tag
#   check-release-tag.sh --help
#
# Fenêtre de grâce (ADR-073) : le tag et la release GitHub sont posés quelques minutes APRÈS
# le merge (CLAUDE.md § Règle non négociable, étape 2), alors que ce gate tourne au push sur
# main, c'est-à-dire au moment du merge. Si le tag est absent ET que le commit HEAD est récent
# (< VF_RELEASE_TAG_GRACE_SECONDS, défaut 900s = 15 min), le gate rend un verdict d'ATTENTE non
# bloquant (exit 3) plutôt qu'un échec — au-delà de la fenêtre, il échoue comme avant (exit 1).
# Le mode --remote garde son exigence actuelle inchangée sur le tag poussé et la release GitHub :
# la fenêtre de grâce ne couvre QUE l'absence totale du tag local.
#
# Codes de sortie : 0 = conforme · 1 = tag manquant (hors fenêtre de grâce) · 2 = usage/erreur
#                    · 3 = tag manquant mais release récente (fenêtre de grâce, non bloquant)
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
  grace="${VF_RELEASE_TAG_GRACE_SECONDS:-900}"
  head_ts="$(git log -1 --format=%ct HEAD 2>/dev/null || echo 0)"
  now_ts="$(date +%s)"
  if [ "$head_ts" -gt 0 ] 2>/dev/null; then
    age=$(( now_ts - head_ts ))
  else
    age=-1
  fi
  if [ "$age" -ge 0 ] && [ "$age" -lt "$grace" ]; then
    remaining=$(( grace - age ))
    echo "[check-release-tag] … VERSION=$raw sans tag $tag pour l'instant — fenêtre de grâce (commit vieux de ${age}s, fenêtre ${grace}s, ${remaining}s restantes)." >&2
    echo "  → pose le tag maintenant (git tag -a $tag -m \"$tag — <résumé>\" <commit> && git push origin $tag), ou relance ce job une fois le tag poussé." >&2
    exit 3
  fi
  echo "[check-release-tag] ✗ VERSION=$raw mais AUCUN tag local $tag (hors fenêtre de grâce de ${grace}s)." >&2
  echo "  → git tag -a $tag -m \"$tag — <résumé>\" <commit> && git push origin $tag" >&2
  exit 1
fi

if $REMOTE && [ -z "$(git ls-remote --tags origin "refs/tags/$tag" 2>/dev/null)" ]; then
  echo "[check-release-tag] ✗ tag $tag présent en local mais PAS poussé sur origin." >&2
  echo "  → git push origin $tag" >&2
  exit 1
fi

# Release GitHub (2026-07-26) : les tags v2.29.0→v2.39.0 existaient tous mais la page Releases
# s'était arrêtée à v2.28.0 — le gate ne vérifiait que le tag. Sous --remote, une release GitHub
# DOIT exister pour le tag. gh en voie principale, repli API publique via curl ; aucun des deux
# disponible = erreur d'intégrité (pas de skip silencieux, même doctrine que F23).
if $REMOTE; then
  if command -v gh >/dev/null 2>&1; then
    if ! gh release view "$tag" >/dev/null 2>&1; then
      echo "[check-release-tag] ✗ tag $tag poussé mais AUCUNE release GitHub associée." >&2
      echo "  → gh release create $tag --title \"$tag — <résumé>\" --notes \"<résumé + commits couverts>\"" >&2
      exit 1
    fi
  elif command -v curl >/dev/null 2>&1; then
    origin_url="$(git remote get-url origin 2>/dev/null)"
    slug="$(printf '%s' "$origin_url" | sed -E 's#^(https://github\.com/|git@github\.com:)##; s#\.git$##')"
    case "$slug" in
      */*) : ;;
      *) echo "[check-release-tag] ✗ origin non-GitHub ($origin_url) — release invérifiable" >&2; exit 2 ;;
    esac
    http_code="$(curl -s -o /dev/null -w '%{http_code}' "https://api.github.com/repos/$slug/releases/tags/$tag")"
    if [ "$http_code" != "200" ]; then
      echo "[check-release-tag] ✗ tag $tag poussé mais AUCUNE release GitHub associée (API HTTP $http_code)." >&2
      echo "  → gh release create $tag --title \"$tag — <résumé>\" --notes \"<résumé + commits couverts>\"" >&2
      exit 1
    fi
  else
    echo "[check-release-tag] ✗ ni gh ni curl disponibles — release GitHub invérifiable (intégrité du gate)" >&2
    exit 2
  fi
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
