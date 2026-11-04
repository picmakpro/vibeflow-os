# 70-04 — trace rouge des témoins R13 à R16 (avant tout code de mise en page)

- Date : 2026-11-04 ; HEAD : `18e4d7ab` (plans revalidés, 70-01, 70-10, 70-11 partiel) ; code de mise en page inchangé.
- Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-responsive.sh` (sortie conservée dans `$TMPDIR`) — 198 PASS / 38 FAIL, durée 87 s, aucune suite sautée.
- Aucune régression : les 38 FAIL sont tous des témoins R13 à R16 ; R1 à R12 (dont R4.2 et R8) restent verts.

## Mesures de départ à 390 px (lab court, Chrome headless)

| Onglet | Hauteur d'en-tête | Rangées | Actions dans la rangée | Bouton « ⋯ » | Zoom | Bouton Détail |
|---|---|---|---|---|---|---|
| Code (avec Travail récent et Écrans) | 148 px | 3 | 8 | absent | dans l'en-tête (x 202, ligne de 132 px) | visible |
| Projet | 100 px | 2 | 5 | absent | dans l'en-tête | visible |
| Équipe | 100 px | 2 | 5 | absent | dans l'en-tête | visible |

Onglets avant le plan : police 12 px, piste 2 px / 2 px, padding d'onglet 6 px, à toutes les largeurs (règle de resserrement de 69-05).

## Lignes FAIL (assertion, attendu, obtenu)

- R13.1 index / project / equipe, 390 px — attendu `1` rangée ; obtenu `3`, `2`, `2`.
- R13.2 index / project / equipe, 390 px — attendu `|true` (aucune action en rangée, `#vf-plus` visible) ; obtenu `theme-toggle,btn-health,tour-btn,btn-export,btn-recent,screens-btn,flows-btn,filters-btn|false` (Code), `theme-toggle,tour-btn,btn-export,flows-btn,filters-btn|false` (Projet, Équipe).
- R13.3 Code, 390 px, menu ouvert — attendu `aucune` ; obtenu `menu absent`.
- R13.4 trois onglets × 390 / 1 024 / 1 440 px (9 lignes) — attendu `3|13px|3px/3px` ; obtenu `3|12px|2px/2px`.
- R14.1 trois onglets, 390 px — attendu `false|true` ; obtenu `true|true` (le zoom est dans l'en-tête).
- R14.2 trois onglets, 390 px — attendu `ok` ; obtenu `direction row ; à droite (x=202)`.
- R14.3 trois onglets × 390 / 768 / 1 440 px (9 lignes) — attendu `aucun` ; obtenu `z-out [] | z-fit [] | z-in []` (aucun `aria-label`).
- R14.5 Projet, 390 px, parcours — attendu `aucun` ; obtenu `recouvrement 37x44 px` (zoom sur « Remonter d'un niveau »).
- R15.1 390 px — attendu `false|false|false` ; obtenu `true|true|true` (bouton Détail visible).
- R15.3 Projet, 390 px, tiroir ouvert — attendu `poignée true · croix true` ; obtenu `poignée false · croix false`.
- R15.4 Projet, 390 px — la croix ferme le tiroir : attendu `false` ; obtenu `true` (aucune croix).
- R15.5 Projet, 390 px — le tap du titre ouvre le tiroir : attendu `true` ; obtenu `false` (le titre ne reçoit pas les événements de pointeur : `elementFromPoint` rend le canevas).
- R16 lab « trait » (`Trajectoire du grand jalon pour la equipe-produit-v1.0`), 768 et 1 440 px — attendu `aucun` ; obtenu `equipe-produit-v1.0 x2 (boîte 272 px)` puis `(boîte 520 px)` : le mot à traits d'union tient dans sa boîte et pourtant se coupe sur deux lignes, au trait d'union.

## Verts d'emblée, attendus verts

- R14.4 (position du zoom à 800 px, relevée avant la phase : x 340, y 108, 52 × 144 px, sur Code et Projet ; la même sur Équipe, non jugée ici) ; R15.2 (tap d'une carte ouvre le tiroir) ; R15.4b (Échap ferme) ; R15.4c (tap dans le vide ferme).
- R16 lab « long » (nom de 60 caractères, un seul mot à traits d'union plus large que sa boîte à 768 et 1 440 px) : vert, le mot est exempté (plus large que sa boîte). Ce lab seul ne reproduit pas le titre coupé : le témoin utile est le lab « trait », ajouté pour cela (un mot qui tient dans sa boîte et se coupe au trait d'union quand il suit d'autres mots sur la ligne).

## Contrat laissé à 70-05

- Poignée = élément décoratif (`aria-hidden="true"`) plus large que haut (largeur ≥ 24 px, hauteur ≤ 8 px) dans les 24 px du haut de `#panel` ; croix = bouton visible de `#panel` dont l'`aria-label` commence par « Fermer ».
- Nom accessible du zoom : non vide et ne commence pas par `Zoom out`, `Fit to screen`, `Zoom in`.
- R14.2 : pile `column`, `x < 195` à 390 px, bas du zoom au-dessus du haut de la barre de question (quand elle est visible).

## Recalcul P70-D-16 — mesures et arrêt (condition d'arrêt du plan)

Essai : règle de resserrement de 69-05 retirée (onglets à 13 px, piste à 3 px, padding d'onglet 13 px, marge gauche 14 px), mesure à 1 024 px dans Chrome sur le lab « long », onglet Code avec Travail récent et Écrans (le pire en-tête). Le retrait a ensuite été défait : aucun code de mise en page n'est livré, `00-vibeflow.js` et `01-vf-responsive.js` sont inchangés.

Largeurs mesurées à 1 024 px, onglet Code avec ses boutons optionnels : marque (minimum) 84 px ; marge gauche des onglets 14 px ; écart de la colonne gauche 4 px ; « Remonter » 36 px ; recherche (plancher) 200 px ; colonne de droite 496,4 px, dont le badge « au travail » **128 px** (point + « 1 au travail ») et neuf boutons de 36 px (44 px pour le thème). Largeur de la piste d'onglets : 200 px à 13 px / padding 13 px, soit 122 px de texte + 6 × le padding (170 px à 8 px, 182 px à 10 px).

Place disponible : la fenêtre de 1 024 px laisse à la colonne gauche au plus 280 + 7,6 px (la colonne de droite finit à 1 016,4 px).

Calcul de la borne `header .hl` (marque + écart + marge + onglets + écart + « Remonter ») = 84 + 4 + 14 + (122 + 6 p) + 4 + 36 = 264 + 6 p :

| padding d'onglet p | borne avec « Remonter » | sans « Remonter » | résultat mesuré à 1 024 px, Code |
|---|---|---|---|
| 13 | 342 | 302 | `#btn-panel` sort de la fenêtre (1002..1038), en-tête rogné de 14 px |
| 10 | 324 | 284 | à 284 : tient (aucune violation) ; à 324 : `#btn-panel` sort (1024..1060), en-tête rogné de 36 px |
| 8 (plancher du plan) | 312 | 272 | à 312 : `#btn-panel` sort (1012..1048), en-tête rogné de 24 px ; à 290 : sort encore de 2 px |

Conclusion mesurée : avec la police à 13 px et la piste à 3 px, l'en-tête du Code tient à 1 024 px **sans** « Remonter » (padding 10 px, borne 284 px) mais pas **avec** (même au plancher de 8 px, il manque 24 px), alors que la borne actuelle de 280 px garde de la place pour « Remonter » (essai sur l'onglet Projet, qui a un bouton de moins : à 10 px, 324 px tient, aussi en parcours). À 390 px le calcul tient : 8 + 22 + 4 + 14 + 170 (padding 8) + 4 + 44 + 4 + 44 + 4 + 44 + 8 = 370 px sur 390.

Arrêt demandé par le plan (« si les trois onglets à 13 px ne tiennent pas à 1 024 px, s'arrêter et remonter ») : le passage au parcours (« Remonter ») sur l'onglet Code à 1 024 px ne tient pas. Pistes à trancher par le manager, aucune appliquée : (a) le badge « au travail » en point seul sous 1 280 px (comme à 390 px : libère 92 px, p = 13 et borne 342 tiennent) ; (b) accepter la perte de « Remonter » dans l'en-tête du Code à 1 024 px ; (c) plancher de la recherche abaissé pendant un parcours ; (d) déplacer des actions dans le « ⋯ » au-dessus de 700 px (hors P70-D-01).

## Pourquoi le lab « trait » en plus du lab « long » (R16)

Le lab de 60 caractères est un seul mot à traits d'union plus large que sa boîte à 768 et à 1 440 px : R16 l'exempte (règle du plan) et reste vert, il ne pouvait donc jamais rougir. Un témoin doit pouvoir rougir : le lab « trait » (`Trajectoire du grand jalon pour la equipe-produit-v1.0`) a un mot à traits d'union qui tient dans sa boîte et se coupe pourtant au trait d'union (rouge aux deux largeurs). Les deux sont gardés ; le lab « long » reste le témoin de l'exemption (un mot plus large que sa boîte peut seul être coupé). Validé par le manager.

## Partie ≤ 700 px livrée (tâche 3, sans dépendre de la piste 1 024 px)

`ui/02-vf-telephone.js` : une rangée (logo, onglets à 13 px / piste 3 px / padding 8 px, recherche, point « au travail », « ⋯ »), menu à libellés, pastilles reportées, zoom retourné dans la scène (provisoirement à gauche, au-dessus de la barre de question), bouton Détail masqué. Au-dessus de 700 px rien ne change. Dernière suite complète (avant le réglage provisoire du zoom) : 211 PASS / 25 FAIL ; R3 à 390 px et R3 à 800 px re-mesurés verts après le réglage ; `test-cockpit-vendor.sh` et `test-cockpit-marque-blanche.sh` verts ; `test-cockpit-chrome-fr.sh` 58/1, seul F12.2 rouge (70-06).

Verts nouveaux : R13.1, R13.2, R13.3, R13.4 à 390 px, R14.1, R14.5, R15.1 (et R14.2 après le réglage du zoom). Encore rouges : R13.4 à 1 024 et 1 440 px (6 lignes : 12 px / 2 px, tâche 2 en attente de la piste 1 024 px) ; R14.3 (9 lignes : `aria-label` du zoom, 70-05) ; R15.3, R15.4, R15.5 (poignée, croix, tap du titre, 70-05) ; R16 « trait » (2 lignes, 70-05).
