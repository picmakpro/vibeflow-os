#!/bin/bash
# verdict.sh — lit le verdict d'UN test dans la sortie de `claude plugin test` (68-04 ; P68-D-14).
# Usage : verdict.sh <fichier-de-sortie> <identifiant> succes|echec
# Exit 0 si une ligne de la sortie porte le verdict demandé pour le test dont le titre commence par l'identifiant ;
# 1 sinon ; 2 sur usage invalide, ou si les deux motifs trouvent la même ligne (motifs devenus ambigus).
# Forme mesurée le 2026-11-04, Claude Code 2.1.318 (68-04-RED-TRACE.md § « Forme mesurée de claude plugin test ») :
# une ligne par test, « (pass) <titre> [<durée>] » ou « (fail) <titre> [<durée>] ». Deux motifs constants, jamais à vide.
# Le titre est comparé comme chaîne (awk index), jamais comme expression régulière : un identifiant n'injecte rien.
PASS_PREFIX='(pass) '
FAIL_PREFIX='(fail) '
[ "$#" -eq 3 ] && [ -f "$1" ] && [ -n "$2" ] || { echo "usage : verdict.sh <sortie> <identifiant> succes|echec" >&2; exit 2; }
case "$3" in succes) want="$PASS_PREFIX"; other="$FAIL_PREFIX" ;; echec) want="$FAIL_PREFIX"; other="$PASS_PREFIX" ;; *) echo "usage : verdict.sh <sortie> <identifiant> succes|echec" >&2; exit 2 ;; esac
# lignes portant l'identifiant derrière un préfixe de verdict ; l'identifiant doit finir au mot (espace ou fin de titre)
hits() { # $1 = préfixe ; $ID = identifiant, $OUT = sortie
  awk -v p="$1" -v id="$ID" '
    index($0, p) == 1 { t = substr($0, length(p) + 1); if (index(t, id) == 1) { r = substr(t, length(id) + 1, 1); if (r == "" || r == " ") n++ } }
    END { print n + 0 }' "$OUT"
}
OUT="$1"; ID="$2"
w=$(hits "$want"); o=$(hits "$other")
[ "$w" -gt 0 ] && [ "$o" -gt 0 ] && { echo "verdict.sh : $2 apparaît à la fois en succès et en échec" >&2; exit 2; }
[ "$w" -gt 0 ]
