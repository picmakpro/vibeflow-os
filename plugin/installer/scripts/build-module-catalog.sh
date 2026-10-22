#!/usr/bin/env bash
# build-module-catalog.sh — Catalogue nom + description + statut agrégé depuis les module.json.
#
# Pour chaque sous-dossier de la racine modules qui contient un `module.json`, émet sur
# stdout une ligne au format :   <name>\t<description>\t<statut>
#   (séparateur = TABULATION ; un module par ligne, trié alphabétiquement par nom).
#   statut ∈ { "mandatory", "optional" } — dérivé du champ `.mandatory` (défaut false).
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
# POSTE (Phase 58, P58-D-17) : `--role <poste>` (ou `--role=<poste>`), à défaut `VF_ROLE`, le
#   drapeau l'emportant. Postes admis : solo | product | dev ; toute autre valeur est refusée sans
#   être réimprimée. `product` et `dev` filtrent le catalogue par `module-roles.sh list <poste>`
#   (source UNIQUE du prédicat, jamais recopiée, atteinte par un chemin relatif à ce script) ;
#   `solo` et « sans poste » ne lancent rien : la sortie reste identique à l'octet. Un poste est
#   une vue, pas un droit : rien n'est désinstallé ni interdit.
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

POSTE="${VF_ROLE:-}"
while [ "$#" -gt 0 ]; do
  case "$1" in
    --role)
      [ "$#" -ge 2 ] && [ -n "$2" ] || err "--role nécessite une valeur"
      POSTE="$2"; shift 2 ;;
    --role=*)
      POSTE="${1#--role=}"
      [ -n "$POSTE" ] || err "--role nécessite une valeur"
      shift ;;
    *) err "argument inconnu" ;;
  esac
done
case "$POSTE" in
  ""|solo|product|dev) ;;
  *) err "poste invalide (attendu solo|product|dev ; valeur non réimprimée)" ;;
esac

ROOT="${VF_MODULES_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
[ -d "$ROOT" ] || err "racine modules introuvable : $ROOT"

# Filtre du poste : les noms visibles sont calculés AVANT la boucle, par le validateur unique.
FILTRE=0
VISIBLES=""
case "$POSTE" in
  product|dev)
    FILTRE=1
    ROLES_SH="$(cd "$(dirname "$0")" && pwd)/../../_internal/module-roles.sh"
    [ -f "$ROLES_SH" ] || err "module-roles.sh introuvable : $ROLES_SH"
    VISIBLES="$(VF_MODULES_ROOT="$ROOT" bash "$ROLES_SH" list "$POSTE")" \
      || err "filtre du poste $POSTE impossible (voir le message de module-roles.sh ci-dessus)" ;;
esac
NL="
"

# Parcourt chaque module.json, émet "name<TAB>description<TAB>statut", puis trie par nom.
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
  # Poste product/dev : un module absent de la liste visible est sauté (ligne entière, jamais sous-chaîne).
  if [ "$FILTRE" = "1" ]; then
    case "$NL$VISIBLES$NL" in
      *"$NL$name$NL"*) ;;
      *) continue ;;
    esac
  fi
  description=$(jqx -r '.description // empty' "$manifest")
  mandatory=$(jqx -r '.mandatory // false' "$manifest")
  statut="optional"; [ "$mandatory" = "true" ] && statut="mandatory"
  printf '%s\t%s\t%s\n' "$name" "$description" "$statut"
done | sort
