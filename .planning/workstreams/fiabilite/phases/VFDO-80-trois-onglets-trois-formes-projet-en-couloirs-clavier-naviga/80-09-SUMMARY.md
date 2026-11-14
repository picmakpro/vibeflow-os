# 80-09 — SUMMARY

## Livré
- `viewer.html` : `VibeFlow.cadrage({ plancher, zone, ids })` (calcul pur, `fit()` = `setT(cadrage())`), plancher 11/13 choisi sur l'onglet chargé
  (état de chargement de la coquille, sinon `VF_COQUILLE.onglet()`, sinon `meta.vfTab`), jamais sur l'adresse ; `setReadingArea(fn)` (candidat au plus grand
  `kFit`, borné 200 x 140, fournisseur qui lève ignoré) ; `zoomBy` centré (carte sélectionnée dont le centre est dans le champ, sinon centre du plus grand
  candidat), 1,25 et 0,8 partout ; `enSaisie(ev)` ; lettre seule ignorée avec ⌘, Ctrl, Alt ; `transformer({ k, x, y })` (non fini refusé, k borné).
- `04-vf-clavier-canevas.js` : `champsDeCadrage()` (deux découpes autour du coin), inscrit à l'évaluation ; recadrage à l'arrivée de l'onglet d'une vue qui était
  le cadrage de la zone libre (le coin n'existe qu'après le premier rendu). Idiome A51 : rappel d'onglet sous la clé du fichier ; le repli par `ready` reste
  (page sans coquille). Aucun découpage en `04-vf-canevas-champ.js` : 215 lignes (budget 255).
- `76-vf-git-entete.js` : copie de la formule retirée (`SC.cadrage()`), baseline de colonnes 38 -> 37 par `abaisser`. `40-tour.js` : zoom « tout le graphe » par `SC.cadrage`.
- Suite `test-cockpit-zoom-garde.sh` (23 PASS) et pilote `chrome-zoom-garde.mjs` ; trace rouge : `80-09-RED-TRACE.md` (7 PASS / 16 FAIL sur la base).
- Nombre de lignes `<script` de `viewer.html` : 6 avant, 6 après.

## Écarts
- Écart : ZG5.1 (idiome A51) est VERT sur la base : la portée de 79-16 retirait déjà l'écouteur de document ; pas de rouge à tracer. Sensibilité prouvée par un mutant
  (init inscrit deux fois) : ZG5.1 seul rougit.
- Écart : ZG2.4 au téléphone (390 px) : `#zoom` est une colonne à gauche DANS la zone libre que `freeArea()` ne déduit pas ; la carte amenée dans le champ peut le
  recouvrir. Non assertée pour `#zoom` à 390 px (hors contrat de ce plan, changerait `freeArea`). Autres disjonctions (`#ask`, pastille, feuille) assertées.
- Écart : ZG1.2 « carte entière » = entière dans un candidat du champ de lecture (avec le plancher, la carte déborde hors du champ et passe sous le coin : inévitable).
- Écart : commits des tâches 1 et 2 groupés (un seul `viewer.html`).
- Écart : mutants M-FACTEUR, M-CENTRE, M-GARDE, M-PLANCHER, M-PLANCHER-ADRESSE : levés (régime allégé). ZG4 sans lignes « le mutant rougit ».
- ZG4.4 : sans objet (`04-vf-canevas-champ.js` non créé).
- Cas à ajouter après livrable absent : aucun.

## Suites jouées sur la tête commitée
- zoom-garde 23/0 ; moteur-carte 73/0 ; accessibilite 35/0 ; clavier-canevas 33/0 ; panneau-retour 43/0 (PR2.9 PASS).
- projet-visite 114/1 (R3.18, bouton Copier : presse-papiers sous charge, sans lien avec le cadrage) ; coin 43/1 (H0 : Chrome étranger vivant, hygiène).
- git-entete 119/17, responsive 347/32, git-tiroir 167/27 : échecs restreints aux mutants de la sortie (non servie en statique depuis 79-16) et à H2.3, H9.2 —
  git-entete rejoué sur la base 68343e27 (archive) : 119/17, mêmes échecs ; responsive et git-tiroir : seuls des mutants rougissent à vide, aucune assertion non mutante. vendor 249/3 (V11 Q : module introuvable, hors périmètre) ; V4c vert après le commit de cliquet.

## Rituel
rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale)

## CHANGELOG demandé (80-18)
Cockpit : une seule formule de cadrage pour « Ajuster », l'en-tête Git et la visite, nourrie par le champ de lecture ; le zoom `+`/`-` est centré sur la carte
sélectionnée et revient exactement ; aucun raccourci ne part depuis un champ de saisie.
