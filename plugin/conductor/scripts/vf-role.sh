#!/usr/bin/env bash
# vf-role.sh — lecteur UNIQUE du poste de l'humain (P58-D-15). Un poste est une vue, pas un droit.
#
# Usage : vf-role.sh get [--path <dir>]
#   Imprime sur stdout exactement UNE ligne : solo | product | dev.
#   Priorité : VF_ROLE (non vide) > <racine>/.claude/vibeflow-role > solo (fichier absent).
#   Racine : --path > CLAUDE_PROJECT_DIR > git rev-parse --show-toplevel > "." (jamais un comptage de ../).
#   Lecture seule : aucun écrivain ici, l'engine pose le fichier (verbe `role`, P58-PL-06).
#   Tolère un BOM UTF-8 de tête et des fins de ligne CRLF. Le contenu brut n'est jamais réimprimé.
#
# Codes de sortie (contrat lu par les Phases 59 à 61) :
#   0  = poste rendu sur stdout
#   1  = valeur invalide (variable ou fichier, fichier vide compris) ; stdout vide
#   5  = fichier de poste illisible (lien symbolique, non régulier, illisible, > 64 octets, plusieurs lignes) ; stdout vide
#   64 = usage
set -uo pipefail

usage() { echo "[vf-role] usage : vf-role.sh get [--path <dir>]" >&2; exit 64; }

# valide <valeur> : imprime la valeur si elle est dans l'ensemble fermé (code 0), sinon code 1.
valide() {
  case "$1" in
    solo|product|dev) printf '%s\n' "$1"; return 0 ;;
    *) return 1 ;;
  esac
}
die1() { echo "[vf-role] valeur invalide (attendu solo|product|dev ; valeur non réimprimée)" >&2; exit 1; }
die5() { echo "[vf-role] fichier de poste illisible : $1" >&2; exit 5; }

verb="${1-}"
case "$verb" in
  -h|--help) grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
  get) shift ;;
  *) usage ;;
esac

ROOT=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --path)
      [ "$#" -ge 2 ] && [ -n "$2" ] || { echo "[vf-role] --path nécessite une valeur" >&2; exit 64; }
      ROOT="$2"; shift 2 ;;
    --path=*)
      ROOT="${1#--path=}"
      [ -n "$ROOT" ] || { echo "[vf-role] --path nécessite une valeur" >&2; exit 64; }
      shift ;;
    *) echo "[vf-role] argument inconnu" >&2; exit 64 ;;
  esac
done

if [ -z "$ROOT" ]; then
  if [ -n "${CLAUDE_PROJECT_DIR:-}" ]; then
    ROOT="$CLAUDE_PROJECT_DIR"
  else
    export GIT_CONFIG_NOSYSTEM=1 GIT_TERMINAL_PROMPT=0 GIT_OPTIONAL_LOCKS=0
    ROOT="$(git -c core.fsmonitor= -c core.hooksPath=/dev/null rev-parse --show-toplevel 2>/dev/null)" || ROOT=""
    [ -n "$ROOT" ] || ROOT="."
  fi
fi

file="$ROOT/.claude/vibeflow-role"

if [ -n "${VF_ROLE:-}" ]; then
  valide "$VF_ROLE" || die1
  exit 0
fi

if [ ! -e "$file" ] && [ ! -L "$file" ]; then
  echo solo; exit 0
fi
if [ -L "$file" ]; then die5 "lien symbolique"; fi
[ -f "$file" ] || die5 "non régulier"
[ -r "$file" ] || die5 "illisible"
size="$(wc -c < "$file" 2>/dev/null | tr -d '[:space:]')"
case "$size" in ''|*[!0-9]*) die5 "illisible" ;; esac
[ "$size" -le 64 ] || die5 "au-delà de 64 octets"

content="$(LC_ALL=C cat "$file" 2>/dev/null)" || die5 "illisible"
bom="$(printf '\357\273\277')"
content="${content#"$bom"}"
content="$(printf '%s' "$content" | tr -d '\r')"
# rognage des blancs aux bords (espaces, tabulations, sauts de ligne)
while :; do
  case "$content" in [[:space:]]*) content="${content#?}" ;; *) break ;; esac
done
while :; do
  case "$content" in *[[:space:]]) content="${content%?}" ;; *) break ;; esac
done
nl="
"
case "$content" in
  *"$nl"*) die5 "plusieurs lignes" ;;
esac

valide "$content" || die1
exit 0
