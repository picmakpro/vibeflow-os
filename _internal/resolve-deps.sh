#!/usr/bin/env bash
# resolve-deps.sh — Résolveur de fermeture transitive des `requires` des module.json.
#
# Usage : resolve-deps.sh <module> [<module> ...]
#   Donné une ou plusieurs racines, suit récursivement le champ `requires` de chaque
#   module.json, et émet sur stdout la fermeture transitive (entrées d'origine + toutes
#   leurs deps), triée alphabétiquement et dédupliquée, un module par ligne.
#
# Racine des modules : ${VF_MODULES_ROOT:-<parent du dossier du script>}.
#   Surchargeable via VF_MODULES_ROOT pour injecter des fixtures de test.
#
# Erreurs : module.json absent (module inconnu) → message sur stderr + exit non-zéro.
# Sécurité : marquage « vu » avant enfilage des deps → terminaison garantie même en cas de cycle.
set -euo pipefail

log() { echo "[resolve-deps] $*" >&2; }
err() { echo "[resolve-deps] ERROR: $*" >&2; exit 1; }

ROOT="${VF_MODULES_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"

[ "$#" -ge 1 ] || err "usage: resolve-deps.sh <module> [<module> ...]"

# File de travail (BFS) + set des modules vus.
queue=("$@")
seen=""

is_seen() { case " $seen " in *" $1 "*) return 0 ;; *) return 1 ;; esac; }

while [ "${#queue[@]}" -gt 0 ]; do
  mod="${queue[0]}"
  queue=("${queue[@]:1}")

  is_seen "$mod" && continue
  seen="$seen $mod"

  manifest="$ROOT/$mod/module.json"
  [ -f "$manifest" ] || err "module inconnu : '$mod' (manifeste absent : $manifest)"

  # Enfiler les requires non encore vus.
  while IFS= read -r dep; do
    [ -n "$dep" ] || continue
    is_seen "$dep" || queue+=("$dep")
  done < <(jq -r '.requires[]?' "$manifest")
done

# Émettre la fermeture : un par ligne, triée, dédupliquée.
printf '%s\n' $seen | sort -u
