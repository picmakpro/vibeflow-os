# 70-07 — trace rouge / vert (P70-D-08, méthode allégée selon le risque)

## Rouge — code d'avant le patch de `40-tour.js` (tête ca05484f)

Date : 2026-11-04. Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-projet.sh` (lab jetable de 3 dossiers à cartes de premier niveau, servi par le vrai lanceur, onglet Code, 3 étapes à chaque largeur).
Résultat : 61 PASS / 6 FAIL ; aucune autre suite touchée, O4 non sautée, O5.0, O5.4 et O5.5 verts (témoin posé ; repère et français déjà bons depuis 70-03).

- FAIL — O5.1 [1440 px] : attendu `[]` ; obtenu `[1,2,3]` (étape 1 sans cible ; étapes 2 et 3 : carte sélectionnée mais ni centrée ni zoomée).
- FAIL — O5.2 [1440 px] : attendu `[]` ; obtenu `[1,2,3]` (résumé de plus de 230 caractères coupé à la première phrase : la fin « FINDETEXTE » n'est pas dans le texte).
- FAIL — O5.3 [1440 px] : attendu `[]` ; obtenu `[2,3]` (« Passer » n'existe qu'à l'étape 1 ; ailleurs, seule une icône « Retour »).
- FAIL — O5.1 [390 px] : attendu `[]` ; obtenu `[1,2,3]`.
- FAIL — O5.2 [390 px] : attendu `[]` ; obtenu `[1,2,3]`.
- FAIL — O5.3 [390 px] : attendu `[]` ; obtenu `[2,3]`.

## Vert — après le patch P25 (commits fix(70-07))

`test-cockpit-projet.sh` 67 PASS / 0 FAIL (O5.0 à O5.5 aux deux largeurs). Premier rejeu : O5.5 [390 px] rouge à l'étape 3 (obtenu `[3]`, mot « Start ») : le texte de la dernière étape, sur téléphone, cite « ⋯ › Start here » ; entrée ajoutée à `79-vf-fr-dict-b.js`, puis vert.
`test-cockpit-vendor.sh` 79/0 (V6 : amont retrouvé à l'octet, V7 : diff présent) · `test-cockpit-chrome-fr.sh` 59/0 · `test-cockpit-onglet-code.sh` 21/0 · `test-cockpit-marque-blanche.sh` et `test-cockpit-assemblage.sh` exit 0.
`test-cockpit-responsive.sh` non rejoué ici (consigne du mandat : le manager le rejoue à l'intégration) ; la carte de visite a changé de structure (colonne flex, hauteur bornée, contour `.tour-target`), c'est la surface à surveiller.
