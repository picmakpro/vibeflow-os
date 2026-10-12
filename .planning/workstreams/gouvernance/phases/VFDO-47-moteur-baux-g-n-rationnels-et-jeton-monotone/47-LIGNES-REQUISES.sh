#!/usr/bin/env bash
# 47-LIGNES-REQUISES.sh — contrôle des lignes requises d'une sortie de suite, par IDENTIFIANT ENTIER (Phase 47).
# Pourquoi : `index($0, "✓ R-BAUX-11")` accepte aussi `✓ R-BAUX-11b` ; une ligne requise « satisfaite » par la ligne d'un
# autre identifiant est un vert à tort. Ici un identifiant n'est reconnu que s'il est précédé de `✓ ` ET suivi d'un
# délimiteur : un espace, `:`, `·` ou la fin de ligne.
# Usage : <sortie de la suite> | 47-LIGNES-REQUISES.sh '<ID>|<ID>|…'      |      47-LIGNES-REQUISES.sh --autotest
# Sortie : une ligne `MANQUE <ID>` par identifiant absent, puis `LIGNES-REQUISES requis=<n> manquants=<m>`.
# Codes : 0 tous présents ; 1 au moins un manque, ou liste vide, ou entrée vide (jamais un vert à vide) ; 64 usage.
# Une seule fonction awk (`trouve`) : les plans l'appellent, ils ne la réécrivent pas.
set -uo pipefail

verifier() {
  LC_ALL=C awk -v req="$1" '
    function trouve(ligne, id,    aiguille, reste, p, suite) {
      aiguille = "\342\234\223 " id          # « ✓ » (U+2713, octets E2 9C 93) puis une espace puis l identifiant
      reste = ligne
      while ((p = index(reste, aiguille)) > 0) {
        suite = substr(reste, p + length(aiguille))
        if (suite == "" || substr(suite, 1, 1) == " " || substr(suite, 1, 1) == ":" || substr(suite, 1, 2) == "\302\267") return 1
        reste = substr(reste, p + 1)
      }
      return 0
    }
    BEGIN { n = split(req, r, "|") }
    { lues++; for (i = 1; i <= n; i++) if (r[i] != "" && trouve($0, r[i])) vu[i] = 1 }
    END {
      requis = 0; manque = 0
      for (i = 1; i <= n; i++) if (r[i] != "") { requis++; if (!vu[i]) { print "MANQUE " r[i]; manque++ } }
      printf "LIGNES-REQUISES requis=%d manquants=%d\n", requis, manque
      exit (requis == 0 || lues == 0 || manque > 0)
    }'
}

autotest() {
  ko=0; n=0
  cas() { # <nom> <attendu 0|1> <ids> <entrée>
    sortie=$(printf '%s\n' "$4" | verifier "$3"); rc=$?; n=$((n + 1))
    if [ "$rc" -eq "$2" ]; then echo "✓ AUTOTEST $1 (attendu $2, obtenu $rc)"
    else echo "✗ AUTOTEST $1 : attendu $2, obtenu $rc ($sortie)"; ko=$((ko + 1)); fi
  }
  cas present-espace 0 'R-A-11' '✓ R-A-11 : texte'
  cas present-fin 0 'R-A-11' '✓ R-A-11'
  cas present-point-median 0 'R-A-11' '✓ R-A-11· détail'
  cas suffixe-b-ne-satisfait-pas 1 'R-A-11' '✓ R-A-11b : autre identifiant'
  cas suffixe-b-puis-vrai 0 'R-A-11|R-A-11b' "$(printf '✓ R-A-11b : x\n✓ R-A-11 : y')"
  cas prefixe-ne-satisfait-pas 1 'MUT-A' '✓ MUT-A-LONG : x'
  cas sans-coche-ne-satisfait-pas 1 'R-A-11' 'R-A-11 : sans coche'
  cas entree-vide 1 'R-A-11' ''
  cas liste-vide 1 '' '✓ R-A-11'
  # mutation : la fonction sans la contrainte du délimiteur doit être TUÉE par le cas suffixe-b-ne-satisfait-pas
  copie=$(mktemp "${TMPDIR:-/tmp}/lignes-requises.XXXXXX") || exit 64
  awk '{ if (index($0, "if (suite == \"\" ||") > 0) print "        return 1"; else print }' "$0" > "$copie"
  sortie=$(printf '%s\n' '✓ R-A-11b : autre identifiant' | bash "$copie" 'R-A-11'); rc=$?; n=$((n + 1))
  rm -f "$copie"
  if [ "$rc" -eq 0 ]; then echo "✓ AUTOTEST MUTANT-SANS-DELIMITEUR tué (le mutant accepte R-A-11b pour R-A-11, l'original le refuse)"
  else echo "✗ AUTOTEST MUTANT-SANS-DELIMITEUR non tué : le mutant refuse aussi (rc=$rc)"; ko=$((ko + 1)); fi
  echo "AUTOTEST cas=$n ko=$ko"
  [ "$ko" -eq 0 ]
}

case "${1:-}" in
  --autotest) autotest; exit $? ;;
  '') echo "usage : <sortie> | $0 '<ID>|<ID>…'   |   $0 --autotest" >&2; exit 64 ;;
  *) verifier "$1"; exit $? ;;
esac
