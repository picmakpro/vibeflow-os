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

## Suite : « Passer » et contour (juge Playwright de la recette)

### Rouge — arbre de la correction O6.10 (centrage borné, sans sélection) + témoins O6.11 et O6.12

Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-projet.sh` — 95 PASS / 5 FAIL. H0 rougit par un Chrome d'une autre suite lancée en même temps dans un autre worktree (bruit de concurrence, absent d'un rejeu isolé).

- FAIL — O6.11 [1440 px] : attendu `[true]` ; obtenu `[false]` (lab à quatorze phases : avant la visite k 1,1, x 106, y 244, 4 cartes dans la fenêtre ; après « Passer » à l'étape 3 : k 1,1, x 315, y 296, 1 carte).
- FAIL — O6.11 [390 px] : attendu `[true]` ; obtenu `[false]` (avant k 0,448, x 25, y 326, 4 cartes ; après k 0,852, x 33, y 260, 1 carte).
- FAIL — O6.12 [1440 px] : attendu `[]` ; obtenu `[4]` (le contour de l'étape « au travail » disparaît quand le className de `#vf-lock` est réécrit, comme le fait `70-vf-live.js`).
- FAIL — O6.12 [390 px] : attendu `[]` ; obtenu `[4]`.

### Causes et vert (grandes cartes, « Passer », contour)

- REG-70-01 : `aim()` centrait et zoomait sans regarder le reste du graphe. Il borne maintenant le zoom pour que toutes les cartes restent dans la zone libre, dézoome une carte plus large que sa zone, et recentre au plus près du milieu de la zone sans sortir une autre carte (le centrage reste dans le tiers central, ou aussi central que le permet le graphe : la sonde le dit, `centre`). R5.3 rougissait pour une autre raison : la visite sélectionnait la carte, donc le panneau montrait son détail au lieu de la vue d'ensemble ; la visite n'en sélectionne plus, elle l'éclaire avec la mise en évidence du viewer (`hl` sur la carte, `dim` sur le reste). Témoin O6.10 (carte dans la zone libre, aucune carte hors zone libre, aucune sélection) rouge sur 779bee45 (étape 1 aux deux largeurs), vert après.
- « Passer » : l'étape sur une carte d'un groupe ouvre ce groupe (`go(parent)`) ; `end()` ne rendait la vue d'ensemble que depuis la racine. Toute sortie (Passer, croix, Échap, Terminé) revient maintenant à la racine et ajuste (`go('root')` puis `fit`), sauf le lancement d'un parcours guidé, qui reprend la main.
- Contour : posé sur la cible par un élément propre (`.tour-target`, `position: fixed`), retrouvé par son sélecteur toutes les 250 ms : il ne dépend plus du `className` de la cible, que `70-vf-live.js` réécrit. `70-vf-live.js` n'a pas été touché.
- Vert : `test-cockpit-projet.sh` 100 PASS / 0 FAIL (O6.10, O6.11, O6.12 aux largeurs mesurées) ; `test-cockpit-vendor.sh` 79/0 ; `test-cockpit-chrome-fr.sh` 70/0 ; `test-cockpit-responsive.sh` 255 PASS / 6 FAIL, les six R13.4 connus seuls (R1, R5.3 et R9 verts) ; `synchro.sh verifier` : amont retrouvé à l'octet.
