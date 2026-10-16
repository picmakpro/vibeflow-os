#!/usr/bin/env bash
# phase-base.sh — base de branche DERIVEE (jamais un sha fige) pour la Phase 40.1.
#
# Imprime `git merge-base HEAD <ref-main-choisie>` sur stdout. Aucun litteral de sha dans ce
# script : la ref main et la base se resolvent a l'execution, robuste a un hotfix fusionne
# apres coup (v2.63.1) et a un `main` local rebase en avance sur un `origin/main` non pousse.
#
# Choix de la ref (W-C, revision 3) :
#   1. --main-ref <ref> fourni : PRIORITAIRE en toute situation (rc 2 si elle ne se resout pas).
#   2. sinon, origin/main ET main resolues toutes les deux :
#      - main est ancetre de origin/main (ou egale)  -> origin/main (distante en avance)
#      - origin/main est ancetre de main (ou egale)   -> main (locale en avance, rebase local)
#      - ni l'une ni l'autre                          -> rc 2, message "diverge" sur stderr
#   3. sinon, une seule des deux resolue -> celle-la.
#   4. sinon, aucune -> rc 2.
#
# Usage: phase-base.sh [--main-ref <ref>] [--root <dir>]
# Exit codes: 0 = base imprimee ; 2 = usage invalide, refs manquantes/divergees, --root non-git,
#             ou aucune base commune.
set -uo pipefail

ROOT="."
MAIN_REF=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --main-ref)
      [ "$#" -ge 2 ] || { echo "[phase-base] --main-ref necessite une valeur" >&2; exit 2; }
      MAIN_REF="$2"; shift 2 ;;
    --root)
      [ "$#" -ge 2 ] || { echo "[phase-base] --root necessite une valeur" >&2; exit 2; }
      ROOT="$2"; shift 2 ;;
    -h|--help) grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
    *) echo "[phase-base] argument inconnu : $1" >&2; exit 2 ;;
  esac
done

git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  echo "[phase-base] --root n'est pas un depot git : $ROOT" >&2
  exit 2
}

resolve() { # <ref> -> sha sur stdout, rc 0/1
  git -C "$ROOT" rev-parse -q --verify "$1^{commit}" 2>/dev/null
}

is_ancestor() { # <maybe-ancestor> <descendant>
  git -C "$ROOT" merge-base --is-ancestor "$1" "$2" 2>/dev/null
}

CHOSEN=""

if [ -n "$MAIN_REF" ]; then
  CHOSEN="$(resolve "$MAIN_REF")" || true
  if [ -z "$CHOSEN" ]; then
    echo "[phase-base] --main-ref '$MAIN_REF' ne se resout pas" >&2
    exit 2
  fi
else
  ORIGIN_SHA="$(resolve "origin/main")" || true
  LOCAL_SHA="$(resolve "main")" || true
  if [ -n "$ORIGIN_SHA" ] && [ -n "$LOCAL_SHA" ]; then
    if is_ancestor "$LOCAL_SHA" "$ORIGIN_SHA"; then
      CHOSEN="$ORIGIN_SHA"
    elif is_ancestor "$ORIGIN_SHA" "$LOCAL_SHA"; then
      CHOSEN="$LOCAL_SHA"
    else
      echo "[phase-base] origin/main et main ont diverge (aucune ne descend de l'autre) — passer --main-ref explicitement" >&2
      exit 2
    fi
  elif [ -n "$ORIGIN_SHA" ]; then
    CHOSEN="$ORIGIN_SHA"
  elif [ -n "$LOCAL_SHA" ]; then
    CHOSEN="$LOCAL_SHA"
  else
    echo "[phase-base] aucune ref main resolue (ni origin/main, ni main) — passer --main-ref explicitement" >&2
    exit 2
  fi
fi

BASE="$(git -C "$ROOT" merge-base HEAD "$CHOSEN" 2>/dev/null)" || true
if [ -z "$BASE" ]; then
  echo "[phase-base] aucune base commune entre HEAD et '$CHOSEN'" >&2
  exit 2
fi

printf '%s\n' "$BASE"
exit 0
