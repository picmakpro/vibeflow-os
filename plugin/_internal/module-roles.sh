#!/usr/bin/env bash
# module-roles.sh — Source UNIQUE du prédicat « un module est-il visible à un poste ? » (P58-D-03).
#
# Usage :
#   module-roles.sh validate [<module>...]   rien sur stdout, 0 si tout est valide (sans argument : tous les modules)
#   module-roles.sh visible <module> <poste> imprime `yes` ou `no`
#   module-roles.sh list <poste>             noms visibles, un par ligne, tri LC_ALL=C
#
# Contrat de la clé `roles` d'un module.json :
#   - absente        => visible à tous les postes ;
#   - présente       => liste NON VIDE de valeurs parmi `product`, `dev` ;
#   - `solo`         => sur-ensemble implicite : voit tout, n'apparaît JAMAIS dans une liste ;
#   - tout le reste (`[]`, valeur inconnue, chaîne, null) => refus BRUYANT (code 1, module nommé sur stderr),
#     jamais traité comme « visible ».
# Postes admis : solo | product | dev. Codes : 0 ok, 1 toute erreur (roles invalide, module/poste inconnu,
# JSON illisible, usage). Racine des modules : ${VF_MODULES_ROOT:-<parent du dossier du script>}.
# Le prédicat n'existe qu'ici : le catalogue et l'engine l'appellent par `list` et `visible`, jamais par recopie.
set -euo pipefail

log() { echo "[module-roles] $*" >&2; }
err() { echo "[module-roles] ERROR: $*" >&2; exit 1; }

command -v jq >/dev/null 2>&1 || err "jq introuvable — prérequis de l'engine (parse des module.json).
  Installer : macOS 'brew install jq' (natif depuis macOS 15) · Windows (Git Bash) 'winget install jqlang.jq' · Debian/Ubuntu 'sudo apt-get install jq'"

# jqx — wrapper jq OBLIGATOIRE (ADR-054) : le jq Windows natif écrit en \r\n.
jqx() ( set -o pipefail; command jq "$@" | tr -d '\r'; )

ROOT="${VF_MODULES_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"

USAGE="usage: module-roles.sh validate [<module>…] | visible <module> <poste> | list <poste>"

check_poste() {
  case "${1-}" in
    solo|product|dev) ;;
    *) err "poste invalide (attendu solo|product|dev ; valeur non réimprimée)" ;;
  esac
}

check_name() {
  case "${1-}" in
    ''|*[!A-Za-z0-9._-]*) err "nom de module invalide" ;;
  esac
}

# verdict <manifeste> <poste> -> yes | no | invalid (sur stdout)
verdict() {
  jqx -r --arg r "$2" 'def roles_verdict($r):
  if has("roles")|not then "yes"
  elif (.roles|type)!="array" or (.roles|length)==0 or (.roles|any(.[]; (.=="product" or .=="dev")|not)) then "invalid"
  elif $r=="solo" then "yes"
  elif (.roles|any(.[]; .==$r)) then "yes" else "no" end;
roles_verdict($r)' "$1" || err "lecture de module.json impossible (échec du parseur JSON) : $1"
}

# manifest_of <module> -> chemin ; erreur si inconnu
manifest_of() {
  check_name "$1"
  local m="$ROOT/$1/module.json"
  [ -f "$m" ] || err "module inconnu : $1"
  printf '%s\n' "$m"
}

# Sans état-poste : un verdict calculé sous le poste `dev` suffit à détecter `invalid`.
module_names() {
  local f n
  for f in "$ROOT"/*/module.json; do
    [ -f "$f" ] || continue
    n="$(jqx -r '.name | strings' "$f")" || err "lecture de module.json impossible (échec du parseur JSON) : $f"
    [ -n "$n" ] && printf '%s\n' "$n"
  done | LC_ALL=C sort
}

verb="${1-}"
[ -n "$verb" ] || err "$USAGE"
shift
case "$verb" in
  visible)
    [ "$#" -eq 2 ] || err "$USAGE"
    m="$(manifest_of "$1")"
    check_poste "$2"
    v="$(verdict "$m" "$2")"
    case "$v" in
      yes|no) printf '%s\n' "$v" ;;
      *) err "roles invalide dans $1 : attendu une liste non vide de product|dev" ;;
    esac
    ;;
  validate)
    if [ "$#" -eq 0 ]; then
      mods="$(module_names)"
    else
      mods="$(printf '%s\n' "$@")"
    fi
    bad=0
    while IFS= read -r mod; do
      [ -n "$mod" ] || continue
      m="$(manifest_of "$mod")"
      v="$(verdict "$m" dev)"
      if [ "$v" = "invalid" ]; then
        echo "[module-roles] roles invalide dans $mod : attendu une liste non vide de product|dev" >&2
        bad=1
      fi
    done <<< "$mods"
    [ "$bad" -eq 0 ] || exit 1
    ;;
  list)
    [ "$#" -eq 1 ] || err "$USAGE"
    check_poste "$1"
    out=""
    mods="$(module_names)"
    while IFS= read -r mod; do
      [ -n "$mod" ] || continue
      m="$(manifest_of "$mod")"
      v="$(verdict "$m" "$1")"
      case "$v" in
        yes) out="$out$mod"$'\n' ;;
        no) ;;
        *) err "roles invalide dans $mod : attendu une liste non vide de product|dev" ;;
      esac
    done <<< "$mods"
    printf '%s' "$out"
    ;;
  *) err "$USAGE" ;;
esac
