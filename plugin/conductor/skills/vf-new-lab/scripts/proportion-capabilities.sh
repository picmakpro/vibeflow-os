#!/usr/bin/env bash
# proportion-capabilities.sh — Plafond conseillé de capacités P0 à fabriquer au fan-out, selon le profil.
#
# Rôle (anti-sur-ingénierie, déterministe) : borne le nombre de skills fabriqués à l'init pour éviter
# le "20 skills parce qu'on peut". Le fan-out ne traite que les P0 ; le reste va en backlog.
# Cf. references/capability-manifest.md et references/skill-fanout.md.
#
# Usage:
#   proportion-capabilities.sh --profile <leger|standard|complet> [--count <N>]
#     --count N : nombre de capacités P0 envisagées ; le script dit si c'est dans le plafond.
#
# Sortie : "min max [VERDICT]" sur stdout.
# Exit codes : 0 = dans le plafond (ou pas de --count)  ·  1 = au-dessus du plafond (prioriser)
#              64 = usage invalide
set -uo pipefail

PROFILE=""
COUNT=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --profile) PROFILE="${2:?--profile nécessite une valeur}"; shift 2 ;;
    --count) COUNT="${2:?--count nécessite une valeur}"; shift 2 ;;
    -h|--help) grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
    *) echo "[proportion] argument inconnu : $1" >&2; exit 64 ;;
  esac
done

case "$PROFILE" in
  leger)    MIN=1; MAX=3 ;;
  standard) MIN=4; MAX=8 ;;
  complet)  MIN=9; MAX=20 ;;
  *) echo "[proportion] profil invalide : '$PROFILE' (attendu : leger|standard|complet)" >&2; exit 64 ;;
esac

if [ -z "$COUNT" ]; then
  echo "$MIN $MAX"
  exit 0
fi

case "$COUNT" in
  ''|*[!0-9]*) echo "[proportion] --count doit être un entier : '$COUNT'" >&2; exit 64 ;;
esac

if [ "$COUNT" -gt "$MAX" ]; then
  echo "$MIN $MAX AU-DESSUS (${COUNT} > ${MAX}) — prioriser P0/P1/P2, fan-out sur les P0 seulement"
  exit 1
fi
echo "$MIN $MAX OK (${COUNT} ≤ ${MAX})"
exit 0
