#!/usr/bin/env bash
# rejouer-suites.sh <avant|apres> <dossier de sorties> [dossier de suites] — joue chaque suite test-*.sh du dossier de suites (par défaut : le dossier de ce lanceur)
# et dit si l'ensemble JOUÉ est l'ensemble PRÉSENT (76-08, P76-D-39 : jamais de vert à vide, jamais de suite oubliée).
# Chaque suite est jouée sous CI=1 SANS variable de simulation (un saut Chrome est un rouge : vf_chrome_saut échoue au lieu de rendre 0), sa sortie standard
# ET d'erreur est gardée dans <sorties>/<nom>.out ; APRÈS le retour de l'invocation une ligne `FINI <nom> rc=<n>` est ajoutée à <sorties>/journal.txt.
# L'ensemble joué se lit dans ce journal, l'ensemble présent vient d'un `find` séparé fait APRÈS les lancements ; le `comm -3` est ICI (une suite qui en crée
# une autre pendant sa course est vue). Une suite qui lance Chrome se joue sous le jeton commun du poste : `jeton-chrome.sh run -- bash rejouer-suites.sh …`.
# Codes de sortie, par ordre de priorité (le premier qui s'applique gagne) :
#   3  Chrome absent : une sortie porte la ligne d'échec `❌ FAIL — AM7 aucun navigateur` (jamais « AM7 » seul : une suite imprime toujours `=== AM7 — en CI…`) ;
#      un vert obtenu sans navigateur ne prouve rien, ce code passe donc avant tout autre
#   1  au moins une suite est rouge (rc non nul) ; passe avant le code 4 : un rouge est un fait établi, qu'il reste aussi des suites hors du journal ou non
#   4  joué différent de présent (`JOUE-DIFFERENT-PRESENT`, imprimé même quand le code 1 s'applique) : le journal ne couvre pas l'ensemble des suites
#   0  toutes les suites sont vertes ET joué = présent
# Imprime `PRESENTES=<n>`.
set -uo pipefail
QUAND="${1:-}"; SORTIES="${2:-}"; ICI="$(cd "$(dirname "$0")" && pwd)"; SUITES="${3:-$ICI}"
case "$QUAND" in avant | apres) ;; *) echo "usage : rejouer-suites.sh <avant|apres> <dossier de sorties> [dossier de suites]" >&2; exit 64 ;; esac
[ -n "$SORTIES" ] && [ -d "$SUITES" ] || { echo "usage : rejouer-suites.sh <avant|apres> <dossier de sorties> [dossier de suites]" >&2; exit 64; }
mkdir -p "$SORTIES"; : > "$SORTIES/journal.txt"

for s in $(find "$SUITES" -maxdepth 1 -name 'test-*.sh' | sort); do
  nom="$(basename "$s")"
  env -u VF_CHROME_OPTIONNEL -u CHAINE_SANS_NAVIGATEUR -u SIGNAL_SANS_NAVIGATEUR CI=1 bash "$s" > "$SORTIES/$nom.out" 2>&1
  rc=$?
  echo "FINI $nom rc=$rc" >> "$SORTIES/journal.txt"
done

find "$SUITES" -maxdepth 1 -name 'test-*.sh' | sed 's#.*/##' | sort > "$SORTIES/presentes.txt"
sed -n 's/^FINI \([^ ]*\) rc=.*$/\1/p' "$SORTIES/journal.txt" | sort > "$SORTIES/jouees.txt"
echo "PRESENTES=$(wc -l < "$SORTIES/presentes.txt" | tr -d ' ')"
ECART="$(comm -3 "$SORTIES/presentes.txt" "$SORTIES/jouees.txt")"
[ -s "$SORTIES/presentes.txt" ] || ECART="aucune suite dans $SUITES" # un dossier sans suite ne passe pas à vide
[ -z "$ECART" ] || { echo "JOUE-DIFFERENT-PRESENT"; echo "$ECART"; }

if grep -qF '❌ FAIL — AM7 aucun navigateur' "$SORTIES"/*.out 2> /dev/null; then echo "CHROME-ABSENT"; exit 3; fi
if grep -qv ' rc=0$' "$SORTIES/journal.txt"; then grep -v ' rc=0$' "$SORTIES/journal.txt"; exit 1; fi
[ -z "$ECART" ] || exit 4
exit 0
