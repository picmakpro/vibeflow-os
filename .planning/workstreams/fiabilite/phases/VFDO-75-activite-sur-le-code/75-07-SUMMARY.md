# 75-07 — SUMMARY : le canal de marquage et ce qu'il marque (ACTV-01, ACTV-02, ACTV-03, ACTV-10, ACTV-11)

Rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale). Exception tenue : la chaîne XSS de la marque (D3, D15) a son témoin rouge puis vert ET ses mutants vus rouges (`75-07-RED-TRACE.md`).

Écart : le rebranchement de "Voir sur la carte" (tâche 4) passe de 75-07 à 74-06 — décision déléguée par Samuel (message session principale, 2026-11-08), option recommandée ; prise par la session principale le 2026-11-13 ; amende l'arrangement de P74-D-47.

## Livré

Première moitié (commits 9250ee95, 1974b994) : `ui/75-vf-marques.js` (canal `VF_MARQUES` : `poser`, `retirer`, `active`, `lire`, `table`, `brancherDessin`, file `VF_MARQUES_EN_ATTENTE`, agrégat aux ancêtres), D1, D2, D2b, D5, D18 à D20.

Seconde moitié (8d3459ba, 1f018a28, 794bf9dc) :
- `ui/75-vf-marques.js` (218 lignes) : le peintre (`peindre`, branché au chargement, remplaçable par `brancherDessin` dont la signature ne change pas) pose en place un `.lmg` > `.lm` (glyphe, mot, forme courte) dans le pied
  déjà réservé de chaque carte, sans render ni rerender ; `RANG_SOURCE` range les sources de collision par carte (agents, arbres, branches, plans) ; nom accessible repris de `VF_CANEVAS.nomDeCarte` (Phase 80) avec, avant
  « reliée à N cartes », le mot de lentille puis les mots de collision ; une prévue dit « prévu, créé par … ». Tout texte par `textContent` ou `setAttribute`, aucun `innerHTML`.
- `ui/75-vf-marques-glyphes.js` (81 lignes, neuf, ligne `AJOUT` dans `VENDORED.txt`) : onze glyphes en masque SVG plus le glyphe neutre, place du pied (20 à l'ouverture, 28 aux paliers lod, glyphe 24 unités, padding 0 12), forme courte,
  respiration du glyphe « en cours » coupée en mouvement réduit, `--recent-text` sur `.card.module`, carte prévue.
- `viewer.html` : `cardFoot` réserve un pied à toute carte marquable de l'onglet Code (`G.meta.vfTab` ni `project` ni `equipe`), `STATE_WORD.prevu`, `editorUrl` nul pour un fichier prévu (ni « ouvrir » ni éditeur, menu et panneau),
  dossier virtuel sans les prévues, panneau d'une prévue (« Prévu par … », « n'existe pas encore », fraîcheur de la carte).
- `test-cockpit-activite-carte.sh` (91 PASS, 0 FAIL, sept mutants/jeux de mutants vus rouges : D3, D4, D15 x2 ; les autres levés), `chrome-activite-carte.mjs` et aides `fixtures/test-cockpit-activite-carte/` (`mesures*.mjs`, `mk-lab.sh`, `mk-agents.mjs`).

D8 (chiffre à relever, lab de la suite, 1440 et 390 px) : les niveaux de fichiers gagnent 28 par carte sans pied (src/a : 14 cartes, hauteur 2206 → 2598 ; src/b : 16 cartes, 2340 → 2788) ; k d'ouverture inchangé (1,1 ; 0,846), aucun changement de palier :
`ARRET-D25` non déclenché. Projet et Équipe : géométrie identique à 0 px au module sans réserve.

## Écarts

- Écart : aucun point d'accroche dans `viewer.html` pour le dessin : le peintre lit `state.chipEls` du moteur et se branche par `brancherDessin` ; `viewer.html` ne porte que la réserve du pied et les retouches des prévues. `viewer.html` (`.html`, « hors gate » dans `VENDORED.txt`) n'a pas de plafond en colonnes à mesurer.
- Écart : barres des paliers en x = 1,5 / 6,5 / 11,5 (écart de 2) au lieu de 2 / 6,5 / 11 : avec 1,5 unité d'écart il n'y avait pas de colonne éteinte à k = 0,42 (D9b rouge, la spec demande d'élargir). Le critère « autant de hauteurs que de barres » se lit sur la colonne la plus haute de chaque barre.
- Écart : tige du confluent à y = 13,5 (spec : 14) et bouclier évidé décalé de 1 vers l'intérieur : sinon le trait sort de [1,5 ; 14,5] (D9d).
- Écart : carte prévue : `outline: 1,5px dashed var(--hair-2)` et `outline-offset` négatif, sans bordure ni padding compensé : le navigateur arrondit une bordure de 1,5 px à 1 px (même à densité 2 dans le `foreignObject` mis à l'échelle) et le contenu bougeait d'un demi-pixel.
  Le focus clavier (`outline` de `g.node:focus-visible .card`) remplace le pointillé le temps du focus.
- Écart : la clé de glyphe inconnue (dont `relecture`, Phase 74) se rend avec le glyphe neutre = carré creux en `--text-3` ; le mot est posé tel quel.
- Écart : file de résolution tardive `VF_MARQUES_EN_ATTENTE` (voir la première moitié) ; `tableRelecture` n'est pas écrit ici (tâche 4 passée à 74-06).
- Écart : le keyframe `vfrespire` n'est pas chargé sur l'onglet Code : `vfm-respire` (mêmes valeurs) est posé par le fichier des glyphes.
- Écart : `D3b` (S8 : mot ellipsé, glyphe intact) et `D14` « paire Prévu / À faire » (mesure de silhouette) s'ajoutent aux témoins du plan ; D13 est rejoué après `rerender()`.
- Limite : en moteur lent, D6b « Équipe » a rougi une fois (géométrie lue pendant le chargement d'un poste à plus de 140 de charge) et a vert au rejeu ; les durées des suites voisines sont gonflées par la charge.

## Suites jouées (sur la tête commitée 794bf9dc)

- `test-cockpit-activite-carte.sh` : vert, 91 PASS, 0 FAIL (environ 2 à 3 minutes sous charge, avec le jeton Chrome commun).
- `test-cockpit-vendor.sh` : vert, 120 s. `test-cockpit-chaine-xss.sh` : vert, 77 s. `test-cockpit-moteur-carte.sh` : vert, 86 s (et sur la tête de la tâche 2). `test-cockpit-equipe.sh` : vert, 290 s (EK10 et le mutant d'équipe compris, tête de la tâche 2).
- `test-cockpit-responsive.sh` : R1 et R3 verts ; la suite complète s'arrête sans message au bloc R13 (deux rejeux, 0 FAIL, aucun code de sortie : processus disparu sous charge) ; R19 et R20 non rejoués (un découpage de la suite par copie n'a pas donné de lab : sans valeur, abandonné) : à rejouer sur un poste calme.
- `scripts/check-machine-paths.sh` : vert ; `colonnes-cliquet.mjs verifier` : OK, aucun de mes fichiers en écart.
