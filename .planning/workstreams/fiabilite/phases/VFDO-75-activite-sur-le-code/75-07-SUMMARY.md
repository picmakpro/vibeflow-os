# 75-07 — SUMMARY (PARTIEL : première moitié, le canal de marquage)

Rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale).

Écart : le rebranchement de "Voir sur la carte" (tâche 4) passe de 75-07 à 74-06 — décision déléguée par Samuel (message session principale, 2026-11-08), option recommandée ; prise par la session principale le 2026-11-13 ; amende l'arrangement de P74-D-47.

## Livré

- `plugin/cockpit/skills/cockpit-moteur/assets/ui/75-vf-marques.js` (144 lignes, aucune ligne de plus de 160 colonnes, aucun `innerHTML`) : `window.VF_MARQUES` gelé, jamais d'extension de
  `window.VibeFlow`. API (entrées, retours et forme d'une marque : voir l'en-tête du fichier, qui fait foi) :
  - `poser(couche, entrees, { exclusif })` : rangées `[id, palier, glyphe, mot, infobulle]` ; `exclusif` vaut vrai sauf `false` exact ; rend vrai ou faux (nom ou table invalide, canal fermé) ;
  - `retirer(couche)` : dépile et restitue la précédente, rend le nom de la couche exclusive alors active ;
  - `active()`, `lire(id)` (tableau, vide si rien), `table()`, `brancherDessin(rappel)` (point d'entrée du dessin).
  Pile : une seule couche exclusive visible (la dernière posée), les couches non exclusives toujours visibles ; reposer une couche la remplace et la passe au-dessus.
  Agrégat aux ancêtres par `chain(id)` du moteur (racine exclue) : une marque par (couche visible, ancêtre), palier maximal et nombre de fichiers distincts à ce palier, jamais une somme ;
  sans palier connu (collisions) : « n fichiers ».
- Inscription : `VF_COQUILLE.surOnglet(arrivee, { cle: '75-vf-marques.js' })` (sans coquille : appel direct) ; le rappel ne laisse le canal ouvert que sur l'onglet `code`, le nettoyage rendu retire
  toutes les couches et ferme le canal (les poses sont alors refusées). Un seul écouteur `render` par moteur (`on` ne se défait pas) : relais par `window.__vfMarquesRendu`, qui pointe vers l'instance courante.
- Résolution tardive, côté (2) de V74.3 : à son chargement le canal vide `window.VF_MARQUES_EN_ATTENTE` (`splice`), éléments `{ couche, entrees, exclusif }` appliqués dans l'ordre, une seule fois.
- Point d'entrée du dessin : `brancherDessin(rappel)` ; `rappel({ table })` est appelé à chaque pose, retrait et événement `render` ; sans peintre, ou sans moteur, il ne fait rien. Aucune hypothèse sur le moteur de la 79-18.
- `VENDORED.txt` : ligne `AJOUT assets/ui/75-vf-marques.js` entre celles de `73-vf-tiroir-travail.js` et `75-vf-modele.js`.
- `plugin/cockpit/scripts/tests/test-cockpit-activite-carte.sh` + aide `tests/fixtures/test-cockpit-activite-carte/marques-harness.mjs` : D1, D2, D2b, D5 (avec D5b), D18, D19 (dessin), D20 (file tardive) ; D1 rouge sur la base (`75-07-RED-TRACE.md`).

## Reste à faire (seconde moitié, dépend de 79-17 et 79-18)

Application visuelle (`dessiner`, pied `.lm`, réapplication à `render` par le moteur), `viewer.html`, `75-vf-marques-glyphes.js`, `chrome-activite-carte.mjs`, D3, D4, D6 à D17, tâches 2 et 3,
`tableRelecture` et `RANG_SOURCE` (tâche 3 : le canal sait déjà porter plusieurs rangées par carte dans une couche, une par couple carte et source).

## Écarts

- Écart : la file de résolution tardive est nommée `window.VF_MARQUES_EN_ATTENTE` (choix du mandat), et non `window.__vfFrise.posesEnAttente` du plan ; un élément est une pose complète `{ couche, entrees, exclusif }`,
  non une liste `fichiers`. Conséquence pour 74-06 : le dépôt de repli doit construire les rangées lui-même, ou la seconde moitié ajoute la forme `{ couche, fichiers }` résolue par `tableRelecture`.
- Écart : `D19` et `D20` s'ajoutent aux témoins du plan (point d'entrée du dessin ; file de résolution tardive) ; `D5b` (données hostiles) aussi.
- Écart : le moteur est lu par `window.VibeFlow || window.Floorplan` (la base livre `Floorplan`, la coquille lit déjà `VibeFlow`) ; seuls `chain` et `on` sont appelés, tolérants à l'absence.
- Écart : `lire(id)` rend toujours un tableau (une marque par rangée visible, agrégats compris), jamais `null`.

## Suites jouées (sur la tête commitée)

- `test-cockpit-activite-carte.sh` : vert, 35 PASS, 0 FAIL, 1 s.
- `test-cockpit-vendor.sh` : vert, 253 PASS, 0 FAIL, 206 s (V4 et V10.5 verts).
- `scripts/check-machine-paths.sh` : vert. `colonnes-cliquet.mjs verifier` : OK, aucun de mes fichiers en écart.
- Temps total dans les suites : environ 210 s.
