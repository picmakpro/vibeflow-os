# Changelog — product-team-bundle

## [v1.0.0] — 2026-10-27 (naissance du bundle produit)

- Composition : manager `vf-product-manager`, workers internes `vf-product-analyst` (BRIEF) et `vf-product-pm` (PRD), juge interne `prd-gate` (rubric /100, seuil 80), gate déterministe `scripts/check-prd.sh`.
- Visibilité : `roles: ["product"]` — visible aux postes `product` et `solo`, invisible au poste `dev`.
- `proposable: false` jusqu'à un run réel complet sur un lab désigné par Samuel (P59-D-11).
- Aucune release racine.
- Correction ciblée de la revue 59 (F2 à F5, pas de nouveau bump) : `check-prd.sh` rougit les marqueurs de remplissage français en mots entiers (« à définir », « à préciser », « à compléter », « à venir », `n/a`, `TBA`, `FIXME`, accents et casse indifférents), mesure la longueur du critère en caractères (awk pur, vérifié sous awk BSD, mawk et gawk), retire les commentaires HTML aussi dans la passe exigences, rend INDÉTERMINÉ (code 3) un bloc de code non fermé en fin de fichier et signale par numéro de ligne (stdout et stderr) toute ligne à case non reconnue (compteur `non_reconnues` au BILAN). `test-check-prd.sh` : onze sondes et dix-huit mutants de plus (CPRD-MUT-9..26). `test-product-team-bundle.sh` : chaque occurrence d'une clause de seuil a son ancre propre.
