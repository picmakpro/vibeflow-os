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
