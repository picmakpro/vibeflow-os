# 70-12 — trace rouge / vert (P70-D-08, méthode allégée selon le risque)

Plan 70-12 (UIFN-14) : onglet Équipe — zoom, titre / première carte, fil d'Ariane / recherche, page Équipe dans la matrice responsive.
P70-D-20 est un choix du manager (vf-dev-manager, 2026-11-04), PAS un arbitrage de Samuel.

## Avant (rouge)

- Base : `ca05484f` (contenu applicatif de `794c6dba` + plans 70-01 à 70-06, 70-10, 70-11).
- Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-responsive.sh > "$TMPDIR/70-12-t1.out"` (un lancement, 90 s). Résultat : 248 PASS / 13 FAIL ; aucune suite sautée.
- Fixture : lab jetable écrit par la suite, nom de 62 caractères, une session et un sous-agent actifs, HOME jetable (jamais un lab vivant). Fenêtres de la suite : 390x844, 768x480, 1024x768, 1440x900.
- 6 FAIL attendus et hors plan : R13.4 à 1 024 et 1 440 px sur les trois onglets (onglets à 12 px / 2 px, arbitrage de Samuel en attente depuis 70-04).
- 7 FAIL de ce plan :

| Assertion | Attendu | Obtenu |
|---|---|---|
| R17.1 Équipe / 768 px (x, écart au bas, direction du zoom) | `16\|16\|row` | `308\|228\|column` (zoom 52x144 à x=308, y=108) |
| R17.1b Équipe / 768 px (cartes recouvertes par le zoom) | `0` | `1` |
| R17.1 Équipe / 1 024 px | `16\|16\|row` | `574\|582\|column` (zoom 42x114 à x=574, y=72) |
| R19.1 Équipe / 390 px, premier affichage (aire titre / première carte) | `0` | `22752` px² |
| R19.1 Équipe / 768 px | `0` | `17408` px² |
| R19.1 Équipe / 1 024 px | `0` | `26100` px² |
| R19.1 Équipe / 1 440 px | `0` | `26100` px² |

- Verts dès le départ (témoins de non-régression, valeurs relevées) : R17.0 (la fixture montre une carte), R17.1 et R17.1b à 1 440 px (zoom `16|16|row`, rangée 114x42 à x=16, y=842), R17.2 (Code et Projet : 768 px `308,108,52,144`, 1 024 px `574,72,42,114`, 1 440 px `16,842,114,42`), R19.2 (session ouverte, 390 et 1 024 px : aire 0), R20 (Équipe, 390 / 768 / 1 024 / 1 440 px : aucune superposition, aucun défilement horizontal).
- Aires mesurées sur la fixture stable, plus élevées à 1 024 et 1 440 px que le relevé du manager (~17 400) : le nom de lab long fait un titre sur deux lignes ; le défaut est le même.

### Cause du défaut E (relevée par sonde, avant tout code)

Au premier affichage de l'onglet Équipe le groupe `#viewport` garde `translate(0px, 0px) scale(1)` : `fit()` n'a jamais cadré la scène. `72-vf-equipe.js` lance `SC.rerender()` (rendu `keepTransform`) pendant le premier rendu du viewer ; le jeton de rendu du viewer annule alors le premier rendu, c'est-à-dire celui qui appelait `fit(false)`, et le rendu `keepTransform` conserve la transformation d'origine. La première carte reste à (40, 40) sous l'en-tête et sous le titre. Un `fit(false)` rejoué à la main cadre la carte sous le titre (390 px : carte à y=429, titre à y=86). Sur Projet le premier rendu aboutit (transformation cadrée). Après l'ouverture d'une session (`go()` -> `render()` sans `keepTransform`) le cadrage a lieu : R19.2 vert.

### Conclusion R18 (fil d'Ariane / recherche) : non reproduit, témoin négatif

À 1 024 px, lab au nom long (colonne gauche à 280 px, `01-vf-responsive.js:23-25`), mesuré sur Équipe et sur Projet : fil d'Ariane en x=265, largeur 31 px (rogné, « V… »), recherche en x=308 : aire de recouvrement 0 px². Les deux éléments sont visibles (le témoin R18 refuse un vert si l'un est absent). Aucun correctif sans rouge mesuré : `01-vf-responsive.js` ne reçoit aucune règle pour le fil d'Ariane. R18 reste en suite comme garde de non-régression.

## Après

- Base : `c8f1d90d`. Un second lancement de `test-cockpit-responsive.sh` (90 s) : 255 PASS / 6 FAIL ; les 6 FAIL sont les R13.4 à 1 024 et 1 440 px sur les trois onglets (hors plan, arbitrage de Samuel en attente). R17.0, R17.1, R17.1b, R17.2, R18, R19.1, R19.2 et R20 verts.
- Une retouche de `72-vf-equipe.js` (`SC.fit?.(false)` au lieu de `SC.fit(false)`, voir plus bas) est postérieure à ce lancement ; le comportement en navigateur est identique, vérifié en rejouant seulement la section R17 à R20 (25 PASS / 0 FAIL, hors budget des deux lancements complets).

| Mesure | Avant | Après |
|---|---|---|
| Zoom Équipe / 768 px | colonne 52x144 à x=308, y=108 | rangée 144x52 à x=16, y=412 (écart au bas 16) |
| Zoom Équipe / 1 024 px | colonne 42x114 à x=574, y=72 | rangée 114x42 à x=16, y=710 (écart au bas 16) |
| Zoom Équipe / 1 440 px | rangée 114x42 à x=16, y=842 | inchangé |
| Zoom Code et Projet / 768, 1 024, 1 440 px | `308,108,52,144` / `574,72,42,114` / `16,842,114,42` | inchangés (R17.2) |
| Cartes recouvertes par le zoom, Équipe / 768 px | 1 | 0 |
| Aire titre / première carte, 390 px | 22752 px² | 0 |
| Aire titre / première carte, 768 px | 17408 px² | 0 |
| Aire titre / première carte, 1 024 px | 26100 px² | 0 |
| Aire titre / première carte, 1 440 px | 26100 px² | 0 |
| Première carte à 390 px (haut) | y=32 (sous l'en-tête) | y=427 |

Autres suites : `test-cockpit-marque-blanche.sh` 30/0, `test-cockpit-vendor.sh` 78/0, `test-cockpit-equipe.sh` 134/0 (après la retouche ci-dessous).

## Choix de réalisation

- Zoom : `body.vf-tab-equipe #zoom` (spécificité supérieure aux règles `#zoom` du viewer et de `01-vf-responsive.js`) sous `@media (min-width: 701px)`. Le marqueur `vf-tab-<onglet>` est posé sur le corps de page par `00-vibeflow.js`. Sous 701 px, rien n'est posé : la pile verticale de 70-05 reste seule.
- Titre (défaut E) : `SC.fit(false)` dans `arrivee()` de `72-vf-equipe.js`, une fois par page, avant la révélation éventuelle d'une carte visée. Aucune marge de scène ni variable CSS : la cause est un cadrage jamais exécuté, pas une hauteur de titre ignorée (la marge aurait déplacé un décor encore sous l'en-tête).
- `SC.fit?.(...)` : la première version appelait `SC.fit(false)` ; le faux viewer du harnais hors navigateur de `test-cockpit-equipe.sh` (EUI2.10, 2.14, 2.18c, 2.26) n'expose pas `fit` et la suite rougissait. Cette suite n'est pas dans les fichiers du plan : le correctif est resté dans le code VibeFlow.
- Fil d'Ariane / recherche : aucun changement (R18, non reproduit).
- `viewer.html` et `VENDORED.txt` non touchés (`git diff --name-only ca05484f..HEAD`).
