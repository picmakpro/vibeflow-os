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

## Suite : rechargement (correctif ciblé demandé par le manager, écart relevé par 70-08)

### Rouge — tête 34b58f61 + témoins O6.9 et O5.6

Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-projet.sh` — 89 PASS / 3 FAIL, tous dans O6.9 ; O6.5 (Chrome neuf par largeur) gardé, vert. La sonde mesure chaque largeur deux fois dans le même profil (option `recharge`).

- FAIL — O6.9 [r390] : attendu `[]` ; obtenu `[1]` (étape 1 de la visite Projet, une carte, mal centrée au rechargement).
- FAIL — O6.9 [l1440] : attendu `[]` ; obtenu `[1]` (page déjà chargée à 390 px dans le même profil).
- FAIL — O6.9 [r1440] : attendu `[]` ; obtenu `[1]`.
- O6.9 [l390] (premier chargement du profil) vert : c'est le seul cas que O6.5 mesurait.
- O5.6 (onglet Code, 1 440 et 390 px, rechargé) vert avant correction : la première étape y est la racine (`#context`), pas une carte.

### Cause et vert

Cause : à l'ouverture, `show(0)` programmait toujours `SC.fit(true)` à 450 ms. Quand la première étape est une carte (onglet Projet, 70-08), le centrage de la carte (mesuré à 60 ms si la carte est déjà posée) était défait par ce fit ; sur un profil neuf la page se pose plus lentement, la carte était mesurée à 650 ms, après le fit, et le cas était masqué. Correctif : le fit d'ouverture ne se programme que si la première étape est la vue d'ensemble (`ref` racine). Patch P25 mis à jour (`assets__ui__40-tour.js.diff`, ligne de `VENDORED.txt`).

Vert : `test-cockpit-projet.sh` 92 PASS / 0 FAIL (O6.9 aux quatre passes, O5.6 Code à 1 440 et 390 px, O6.5 conservé) ; `test-cockpit-vendor.sh` et `test-cockpit-chrome-fr.sh` 79 PASS / 0 FAIL et 59 PASS / 0 FAIL ; `synchro.sh verifier` : amont retrouvé à l'octet.

## Suite : grandes cartes (REG-70-01 de `70-VERIFICATION.md`)

### Rouge — tête 779bee45 + témoin O6.10

Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-projet.sh` — 93 PASS / 2 FAIL, les deux dans O6.10 (lab à jalon et à mission, nom long, visite Projet active au premier chargement ; sonde `chrome-visite-etapes.mjs`, champs `dansZone` et `toutLibre`, ce dernier reprenant le critère de R1).

- FAIL — O6.10 [1024 px] : attendu `[]` ; obtenu `[1]` (étape 1, la carte du jalon : une carte du graphe sort de la zone libre à gauche du panneau).
- FAIL — O6.10 [1920 px] : attendu `[]` ; obtenu `[1]`.

Mécanisme mesuré : `aim()` centre et zoome sur la carte ciblée sans regarder le reste du graphe, qui déborde alors sous le panneau (R1 mesure l'union de toutes les cartes) ; il ne dézoome jamais, donc une carte plus large que sa zone y déborde aussi.
