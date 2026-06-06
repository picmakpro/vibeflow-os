#!/usr/bin/env bash
# build-module-catalog.sh — Catalogue nom + description agrégé depuis les module.json.
#
# Pour chaque sous-dossier de la racine modules qui contient un `module.json`, émet sur
# stdout une ligne au format :   <name>\t<description>
#   (séparateur = TABULATION ; un module par ligne, trié alphabétiquement par nom).
#
# Source EXCLUSIVE = `jq -r` sur les champs `.name` et `.description` de chaque module.json.
# AUCUN nom de module n'est codé en dur (anti-hallucination, cf. build-gsd-index.sh) : la
# liste sort entièrement des fichiers présents sur le disque. Les dossiers sans module.json
# (ex. `_internal`, `docs`, `installer`) sont naturellement exclus.
#
# Ce catalogue est consommé par le skill /vibeflow-install pour peupler le toggle modules
# (INST-02). C'est une brique de DONNÉES (pas d'UX) : on la garde minimale.
#
# Racine des modules : ${VF_MODULES_ROOT:-<racine repo = parent de installer/scripts>}.
#   Surchargeable via VF_MODULES_ROOT pour injecter des fixtures de test (cohérent avec
#   resolve-deps.sh). Le défaut pointe sur la racine du repo, où vivent les 8 module.json.
set -euo pipefail

log() { echo "[build-module-catalog] $*" >&2; }
err() { echo "[build-module-catalog] ERROR: $*" >&2; exit 1; }

command -v jq >/dev/null 2>&1 || err "jq introuvable (requis pour parser les module.json)"

ROOT="${VF_MODULES_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
[ -d "$ROOT" ] || err "racine modules introuvable : $ROOT"

# Parcourt chaque module.json, émet "name<TAB>description", puis trie par nom.
for manifest in "$ROOT"/*/module.json; do
  [ -f "$manifest" ] || continue
  name=$(jq -r '.name // empty' "$manifest")
  description=$(jq -r '.description // empty' "$manifest")
  [ -n "$name" ] || continue
  printf '%s\t%s\n' "$name" "$description"
done | sort
