# 75-09c — SUMMARY : dictionnaires et suites voisines, fin du retrait de la couche « Travail récent » (ACTV-12)

Rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale). Les deux mutants du plan (Q12, Q13) sont levés.

## Livré

- Dictionnaires : `Recent work`, `Highlight recent work`, `Recent work inside` (dictionnaire A) et `Changed@pastille` (dictionnaire B, seule entrée « Récent », exigée par le grep final) retirés ; `80-vf-fr.js` : commentaire du repli `X: X` réécrit. Baseline des colonnes abaissée (`78-vf-fr-dict-a.js` 43 -> 42).
- `test-cockpit-moteur-carte.sh` (73 -> 74) et `chrome-moteur-carte.mjs` : la coupe à 24 cartes et les homonymes se mesurent sur un tableau de genre neutre ; `test-cockpit-chrome-fr.sh` (141 -> 142) : F13.3 sur « Health: Health », F19.5 sur une autre valeur, Q13.1 ; `test-cockpit-ecrans-recent.sh` (18 -> 21) : inventaire final Q14.0 à Q14.2 (zéro hors exceptions nommées, avec témoin et contrôle positif). `mesures-pied.mjs` : propriété `p.recent` renommée `p.vert`.
- Aucune suite supprimée : 112 `test-*.sh` du module avant et après. Table avant / après / intention et exceptions du grep : `75-09c-RED-TRACE.md`.

## Écarts

- Écart : `Changed@pastille` retirée du dictionnaire B alors que le plan le dit « pas touché » (le grep final exige zéro « Récent » ; l'entrée n'a plus de lecteur). `Changed · {}`, `{} changed inside · {}` et `{} changed` NE sont PAS retirées : F14.7 et F14.9 les exercent (un premier jet les retirait : 2 FAIL, rétablies).
- Écart : K17.4 (« le panneau d'une partie liste deux modifications dedans », propre à la section retirée) devient « le tableau des deux README porte deux cartes » ; K17.5 inchangé, lu sur les cartes du tableau. Q14 vit dans `test-cockpit-ecrans-recent.sh` (assertion), non en commande finale.
- Constat hors lot : `test-cockpit-coquille.sh` rend 3 FAIL (C6.1 « ids », M-ECOUTEURS, M-HEAD « balises ») avant et après le retrait : régression antérieure (75-07/75-08), à reprendre. Détail en 75-09b.

## Suites jouées (têtes commitées)

`test-cockpit-moteur-carte.sh` vert (74 PASS ; un premier jeu sous quatre suites Chrome en parallèle : 70 FAIL par délai dépassé, rejoué seul : vert) ; `test-cockpit-chrome-fr.sh` vert (142) ; `test-cockpit-equipe.sh` vert (217, EK10 et mutant d'équipe compris) ; `test-cockpit-ecrans-recent.sh` vert (21). Fin de lot : `test-cockpit-responsive.sh` 380 PASS / 0 FAIL (R13.3, R19, R20, Q9.1 ; 1 299 s), `test-cockpit-vendor.sh` 253 PASS, `test-cockpit-activite-carte.sh` 91 PASS (134 s), `test-cockpit-activite-lentilles.sh` 110 PASS (144 s), `check-machine-paths.sh` vert, cliquet de colonnes OK.
