#!/usr/bin/env bash
# resolve-preset.sh — Presets d'installation : un nom stable → la fermeture de modules à poser.
#
# Usage :
#   resolve-preset.sh list [--role <poste>]
#                                     émet `name<TAB>titre<TAB>description<TAB>modules racines`
#                                     (un preset par ligne, ordre du fichier)
#   resolve-preset.sh <preset>        émet la fermeture transitive des modules du preset
#                                     (un module par ligne, triée, dédupliquée) — même format
#                                     que resolve-deps.sh, donc directement consommable par
#                                     `vibeflow-update.sh install --with-deps`.
#
# Délégation (jamais de réimplémentation) : la fermeture est calculée par resolve-deps.sh, à
# côté de ce script. Ce script ne connaît AUCUN nom de module en dur : tout sort de
# presets.json et des module.json.
#
# Refus (exit non-zéro, message sur stderr) :
#   - preset inconnu ;
#   - preset qui référence un module sans module.json (relayé par resolve-deps.sh) ;
#   - preset qui référence un module `proposable: false` — un preset n'expose JAMAIS un module
#     WIP que le catalogue cache (INST-02bis) ; on refuse le preset entier, on ne l'élague pas
#     en silence.
#
# POSTE (Phase 58, P58-D-21) : `list --role <poste>` (ou `--role=<poste>`), à défaut `VF_ROLE`
# (le drapeau l'emporte), avec `product` ou `dev`, retire de la liste tout preset dont la
# fermeture de dépendances (resolve-deps.sh) contient un module que `module-roles.sh` déclare
# invisible à ce poste. Le prédicat n'existe que dans module-roles.sh : appelé, jamais recopié.
# `solo` et « sans poste » : le code d'avant, sortie identique à l'octet. Poste invalide, option
# sans valeur, argument inconnu, `roles` invalide, fermeture irrésoluble : erreur bruyante (code 1),
# jamais un preset élagué en silence. La résolution NOMMÉE ne lit jamais le poste : c'est le CHOIX
# qui se filtre. Un poste est une vue, pas un droit (ADR-077).
#
# Racine des modules : ${VF_MODULES_ROOT:-<parent du dossier du script>} (cohérent avec
# resolve-deps.sh). Fichier de presets : ${VF_PRESETS_FILE:-<dossier du script>/presets.json}
# — surchargeable pour injecter des fixtures de test.
set -euo pipefail

log() { echo "[resolve-preset] $*" >&2; }
err() { echo "[resolve-preset] ERROR: $*" >&2; exit 1; }

command -v jq >/dev/null 2>&1 || err "jq introuvable — prérequis de l'engine (parse de presets.json).
  Installer : macOS 'brew install jq' (natif depuis macOS 15) · Windows (Git Bash) 'winget install jqlang.jq' · Debian/Ubuntu 'sudo apt-get install jq'"

# jqx — wrapper jq OBLIGATOIRE (ADR-054) : le jq Windows natif écrit en mode texte (\n → \r\n).
jqx() ( set -o pipefail; command jq "$@" | tr -d '\r'; )

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="${VF_MODULES_ROOT:-$(cd "$HERE/.." && pwd)}"
PRESETS="${VF_PRESETS_FILE:-$HERE/presets.json}"
RESOLVE_DEPS="$HERE/resolve-deps.sh"

USAGE="usage: resolve-preset.sh list [--role <poste>] | resolve-preset.sh <preset>"
[ "$#" -ge 1 ] || err "$USAGE"
POSTE=""
if [ "$1" = "list" ]; then
  POSTE="${VF_ROLE:-}"
  shift
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
  set -- list
else
  [ "$#" -eq 1 ] || err "$USAGE"
fi
[ -f "$PRESETS" ] || err "fichier de presets introuvable : $PRESETS"
[ -f "$RESOLVE_DEPS" ] || err "résolveur de deps introuvable : $RESOLVE_DEPS"

# Validation de forme : un JSON avec un tableau `presets` — bruyant si le fichier est cassé.
jqx -e '.presets | type == "array"' "$PRESETS" >/dev/null 2>&1 \
  || err "presets.json invalide (tableau .presets attendu) : $PRESETS"

if [ "$1" = "list" ]; then
  case "$POSTE" in
    product|dev) ;;
    *)
      jqx -r '.presets[] | [.name, .titre, .description, (.modules | join(" "))] | @tsv' "$PRESETS"
      exit 0 ;;
  esac
  # Filtre du poste : visibles calculés AVANT la boucle par le prédicat unique, puis la fermeture de
  # chaque preset (même délégation que la résolution nommée) doit y figurer tout entière.
  ROLES_SH="$HERE/module-roles.sh"
  [ -f "$ROLES_SH" ] || err "module-roles.sh introuvable : $ROLES_SH"
  VISIBLES="$(VF_MODULES_ROOT="$ROOT" bash "$ROLES_SH" list "$POSTE")" \
    || err "filtre du poste $POSTE impossible (voir le message de module-roles.sh ci-dessus)"
  count="$(jqx -r '.presets | length' "$PRESETS")" || err "lecture de presets.json impossible"
  # Sortie accumulée puis émise d'un bloc : une erreur en cours de route ne laisse aucune liste partielle.
  res=""
  i=0
  while [ "$i" -lt "$count" ]; do
    pname="$(jqx -r --argjson i "$i" '.presets[$i].name' "$PRESETS")" || err "lecture de presets.json impossible"
    pmods="$(jqx -r --argjson i "$i" '.presets[$i].modules[]?' "$PRESETS")" || err "lecture de presets.json impossible"
    closure=""
    if [ -n "$pmods" ]; then
      closure="$(printf '%s\n' "$pmods" | xargs bash "$RESOLVE_DEPS")" \
        || err "preset '$pname' : fermeture de dépendances irrésoluble (voir le message ci-dessus)"
    fi
    keep=1
    while IFS= read -r mod; do
      [ -n "$mod" ] || continue
      printf '%s\n' "$VISIBLES" | grep -qxF -- "$mod" || { keep=0; break; }
    done <<< "$closure"
    if [ "$keep" -eq 1 ]; then
      line="$(jqx -r --argjson i "$i" '.presets[$i] | [.name, .titre, .description, (.modules | join(" "))] | @tsv' "$PRESETS")" \
        || err "lecture de presets.json impossible"
      res="$res$line"$'\n'
    fi
    i=$((i+1))
  done
  printf '%s' "$res"
  exit 0
fi

name="$1"
# Existence du preset (exit 1 si absent — `-e` rend 1 quand la sortie est null/false).
jqx -e --arg n "$name" '.presets[] | select(.name == $n)' "$PRESETS" >/dev/null 2>&1 \
  || err "preset inconnu : '$name' (presets disponibles : $(jqx -r '[.presets[].name] | join(", ")' "$PRESETS"))"

modules="$(jqx -r --arg n "$name" '.presets[] | select(.name == $n) | .modules[]?' "$PRESETS")"
[ -n "$modules" ] || err "preset '$name' sans module"

# Refus d'un module WIP : le catalogue le cache (proposable:false), un preset ne le ressuscite pas.
# NB : test `== false` explicite — `.proposable // true` serait piégé par `//` qui traite false
# comme vide (même piège que build-module-catalog.sh).
while IFS= read -r mod; do
  [ -n "$mod" ] || continue
  manifest="$ROOT/$mod/module.json"
  [ -f "$manifest" ] || err "preset '$name' : module inconnu '$mod' (manifeste absent : $manifest)"
  hidden="$(jqx -r '.proposable == false' "$manifest")"
  [ "$hidden" = "true" ] && err "preset '$name' : le module '$mod' est marqué proposable:false (WIP) — preset refusé"
done <<< "$modules"

# Fermeture transitive — déléguée. xargs, PAS l'expansion non quotée : word-splitting sous
# IFS altéré collerait les noms en un seul argument (piège déjà vécu en CI).
printf '%s\n' "$modules" | xargs bash "$RESOLVE_DEPS"
