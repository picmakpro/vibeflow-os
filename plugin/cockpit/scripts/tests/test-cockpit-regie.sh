#!/usr/bin/env bash
# test-cockpit-regie.sh — suite UNIQUE de la régie (page « Équipe » gouvernée : À vous, impact, alerte du watchdog, agents attendus…).
# Phase 73 « Gouvernance au cockpit », exigences REGI-01 à REGI-16 ; décision P73-D-05 : une seule suite neuve, faite de ce lanceur et de
# fragments `regie-rg-*.sh` SOURCÉS, hors du motif tests/test-*.sh (même régime que projet-commun.sh) : les plans d'une même vague ajoutent
# leurs témoins sans toucher le même fichier.
# Usage : bash test-cockpit-regie.sh [SECTION…]. Une section est une fonction `rg_<NOM>` d'un fragment, <NOM> = `RG<n>_<couche>` (ex. RG13_route, RG0_socle) ;
#   un argument A retient les sections dont le nom vaut A ou commence par `A_` (RG1 ne retient pas RG10_x). Sans argument : toutes, ordre trié.
#   Un argument qui ne retient rien : `❌ FAIL — section inconnue : A`. Dossier des fragments : VF_REGIE_FRAGMENTS (réservé à l'autotest RG0).
# Fragments attendus, par plan : regie-rg-gouvernance.sh (73-01) · regie-rg-ailleurs.sh (73-02) · regie-rg-collecte.sh (73-03) · regie-rg-modele.sh (73-04) ·
#   regie-rg-page.sh (73-05) · regie-rg-titre.sh (73-06) · regie-rg-pied.sh (73-07) · regie-rg-retrait.sh (73-08) · regie-rg-tiroir.sh (73-10).
# Les fragments ne font que DÉFINIR des fonctions (aucun effet au chargement). Bilan : `Résultats : N PASS / M FAIL` ; exit 1 si M > 0 ou si N = 0.
# Fixtures écrites par la suite dans mktemp ; aucun serveur de fond.

set -uo pipefail
TESTS_DIR_LANCEUR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=regie-commun.sh
. "$TESTS_DIR_LANCEUR/regie-commun.sh"

FRAG_DIR="${VF_REGIE_FRAGMENTS:-$TESTS_DIR}"
for f in $(ls "$FRAG_DIR"/regie-rg-*.sh 2>/dev/null | sort); do
  # shellcheck disable=SC1090
  . "$f"
done

TOUTES="$(declare -F | sed -n 's/^declare -f rg_\(RG[0-9][0-9]*_[A-Za-z0-9_]*\)$/\1/p' | sort)"
SELECTION=""
if [ "$#" -eq 0 ]; then
  SELECTION="$TOUTES"
else
  for a in "$@"; do
    trouve=""
    for s in $TOUTES; do
      case "$s" in "$a"|"$a"_*) trouve=1; case " $SELECTION " in *" $s "*) ;; *) SELECTION="$SELECTION $s";; esac;; esac
    done
    if [ -z "$trouve" ]; then echo "  ❌ FAIL — section inconnue : $a"; FAIL=$((FAIL+1)); fi
  done
fi

for s in $SELECTION; do
  echo "=== $s ==="
  "rg_$s"
done

echo ""
echo "=================================="
echo "  Résultats : $PASS PASS / $FAIL FAIL"
echo "=================================="
if [ $((PASS+FAIL)) -eq 0 ] || [ "$PASS" -eq 0 ]; then
  echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE — zéro assertion verte exécutée, résultat non fiable"
  exit 1
fi
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
