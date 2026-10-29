#!/usr/bin/env bash
# ci-shard-suites.sh — partition déterministe des suites de tests entre les shards du job de tests de la CI
# (Phase 65, arbitrage Samuel, message session principale, 2026-10-29 : « on corrige le maximum » sur la durée de la CI).
#
# Usage : ci-shard-suites.sh <shard> <n>      liste les suites du shard <shard> (0 ≤ shard < n), une par ligne
#         ci-shard-suites.sh --all            liste toutes les suites (même découverte que les shards)
#
# Découverte : `find plugin scripts -type f -path '*/tests/test-*.sh' | sort`, identique à l'ancienne étape unique —
# aucune suite n'est ajoutée ni retirée par le découpage.
#
# Répartition : les suites LOURDES (mesurées sur le runner le 2026-10-29) ont chacune un shard réservé, dans l'ordre
# de HEAVY (shard 0, 1, …) ; les autres sont distribuées en tourniquet sur les shards restants. Une suite lourde
# absente du disque ne réserve rien. Le job d'agrégation rejoue la partition pour TOUS les shards et vérifie que
# l'union est exactement la découverte et que les shards sont disjoints et non vides : une suite oubliée rougit.
#
# Sorties : 0 = liste rendue · 64 = usage.
set -u

# Séparées par des espaces (les chemins de suites n'en contiennent pas ; l'awk de macOS refuse un saut de ligne dans -v).
HEAVY="plugin/conductor/scripts/tests/test-driver-lock-ws.sh plugin/conductor/scripts/tests/test-guard-driver-lock-ws.sh"

discover() { find plugin scripts -type f -path '*/tests/test-*.sh' | LC_ALL=C sort; }

usage() { echo "usage : ci-shard-suites.sh <shard> <n> | --all" >&2; exit 64; }

if [ "${1:-}" = --all ] && [ "$#" -eq 1 ]; then discover; exit 0; fi
[ "$#" -eq 2 ] || usage
case "$1$2" in *[!0-9]*|'') usage ;; esac
shard=$1; n=$2
[ "$n" -ge 1 ] && [ "$shard" -lt "$n" ] || usage

# Une seule passe : la liste HEAVY est lue d'abord (variable), puis la découverte. Les lourdes présentes sur le disque
# prennent les shards 0..nh-1 dans l'ordre de HEAVY ; le reste tourne sur nh..n-1.
discover | LC_ALL=C awk -v shard="$shard" -v n="$n" -v heavy="$HEAVY" '
  BEGIN { nh_decl = split(heavy, H, " "); for (i = 1; i <= nh_decl; i++) if (H[i] != "") want[H[i]] = i }
  { all[++na] = $0; if ($0 in want) present[want[$0]] = $0 }
  END {
    nh = 0
    for (i = 1; i <= nh_decl; i++) if (i in present) { slot[present[i]] = nh; nh++ }
    if (nh >= n) { printf "ci-shard-suites : %d suite(s) lourde(s) pour %d shard(s) — il faut au moins un shard de plus que de suites lourdes\n", nh, n > "/dev/stderr"; exit 64 }
    rest = n - nh; k = 0
    for (j = 1; j <= na; j++) {
      t = all[j]
      if (t in slot) { s = slot[t] } else { s = nh + k % rest; k++ }
      if (s == shard) print t
    }
  }'
