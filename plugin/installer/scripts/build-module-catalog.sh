#!/usr/bin/env bash
# build-module-catalog.sh — Catalogue nom + description + rôle agrégé depuis les module.json.
#
# Pour chaque sous-dossier de la racine modules qui contient un `module.json`, émet sur
# stdout une ligne au format :   <name>\t<description>\t<role>
#   (séparateur = TABULATION ; un module par ligne, trié alphabétiquement par nom).
#   role ∈ { "mandatory", "optional" } — dérivé du champ `.mandatory` (défaut false).
#
# FILTRE (INST-02bis) : un module avec `"proposable": false` est EXCLU du catalogue (WIP,
# pas prêt à être proposé — ex. bundles métier incomplets). Ses fichiers restent sur le
# disque ; il sera reproposé en repassant `proposable` à true (ou en l'omettant).
#
# Source EXCLUSIVE = `jq -r` sur `.name` / `.description` / `.mandatory` / `.proposable` de
# chaque module.json. AUCUN nom de module n'est codé en dur (anti-hallucination, cf.
# build-gsd-index.sh) : la liste sort entièrement des fichiers présents sur le disque. Les
# dossiers sans module.json (ex. `_internal`, `docs`, `installer`) sont naturellement exclus.
#
# Ce catalogue est consommé par le skill /vibeflow-install :
#   - les entrées `mandatory` sont posées d'office (baseline, hors toggle) ;
#   - les entrées `optional` alimentent le choix utilisateur (toggle / à-la-carte).
#
# Racine des modules : ${VF_MODULES_ROOT:-<racine repo = parent de installer/scripts>}.
#   Surchargeable via VF_MODULES_ROOT pour injecter des fixtures de test (cohérent avec
#   resolve-deps.sh). Le défaut pointe sur la racine du repo, où vivent les 8 module.json.
set -euo pipefail

log() { echo "[build-module-catalog] $*" >&2; }
err() { echo "[build-module-catalog] ERROR: $*" >&2; exit 1; }

command -v jq >/dev/null 2>&1 || err "jq introuvable (requis pour parser les module.json).
  Installer : macOS 'brew install jq' (natif depuis macOS 15) · Windows (Git Bash) 'winget install jqlang.jq' · Debian/Ubuntu 'sudo apt-get install jq'"

# jqx — wrapper jq OBLIGATOIRE (ADR-054) : le jq Windows natif écrit en mode texte (\n → \r\n).
# Un \r résiduel casse les comparaisons `= "true"` ci-dessous : conductor serait dégradé en
# `optional` et les bundles WIP (`proposable:false`) fuiraient dans le catalogue — silencieusement.
# Subshell + pipefail locaux : propage le code retour de jq sans imposer pipefail à l'appelant.
jqx() ( set -o pipefail; command jq "$@" | tr -d '\r'; )

ROOT="${VF_MODULES_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
[ -d "$ROOT" ] || err "racine modules introuvable : $ROOT"

# Parcourt chaque module.json, émet "name<TAB>description<TAB>role", puis trie par nom.
# Exclut les modules non proposables (proposable == false).
for manifest in "$ROOT"/*/module.json; do
  [ -f "$manifest" ] || continue
  name=$(jqx -r '.name // empty' "$manifest")
  [ -n "$name" ] || continue
  # Filtre : proposable défaut true ; false => exclu du catalogue.
  # NB : on teste `== false` explicitement — `.proposable // true` serait piégé par
  # l'opérateur `//` de jq qui traite `false` comme vide (renverrait true à tort).
  hidden=$(jqx -r '.proposable == false' "$manifest")
  [ "$hidden" = "true" ] && continue
  description=$(jqx -r '.description // empty' "$manifest")
  mandatory=$(jqx -r '.mandatory // false' "$manifest")
  role="optional"; [ "$mandatory" = "true" ] && role="mandatory"
  printf '%s\t%s\t%s\n' "$name" "$description" "$role"
done | sort
