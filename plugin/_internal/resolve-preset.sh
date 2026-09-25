#!/usr/bin/env bash
# resolve-preset.sh — Presets d'installation : un nom stable → la fermeture de modules à poser.
#
# Usage :
#   resolve-preset.sh list            émet `name<TAB>titre<TAB>description<TAB>modules racines`
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

[ "$#" -eq 1 ] || err "usage: resolve-preset.sh list | resolve-preset.sh <preset>"
[ -f "$PRESETS" ] || err "fichier de presets introuvable : $PRESETS"
[ -f "$RESOLVE_DEPS" ] || err "résolveur de deps introuvable : $RESOLVE_DEPS"

# Validation de forme : un JSON avec un tableau `presets` — bruyant si le fichier est cassé.
jqx -e '.presets | type == "array"' "$PRESETS" >/dev/null 2>&1 \
  || err "presets.json invalide (tableau .presets attendu) : $PRESETS"

if [ "$1" = "list" ]; then
  jqx -r '.presets[] | [.name, .titre, .description, (.modules | join(" "))] | @tsv' "$PRESETS"
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
