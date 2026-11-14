# 80-05 — trace du rouge (P80-D-25)

Base : `342a8763` (tête de la vague 1 ; ni `02-vf-coin.js`, ni `02-vf-ligne-etat.js`, ni `02-vf-reperes.js`). Suite :
`bash plugin/cockpit/scripts/tests/test-cockpit-coin.sh` (mesure brute : `SONDE=1`).

## Tâche 1 — repères de bord (CN1)

Lab : 70 notes dans un dossier, ajusté à 1440 x 900 (plancher 11/13) : au plancher, 22 cartes sortent à droite et 46 en bas
(`hors = { gauche: 0, droite: 22, haut: 0, bas: 46 }`, calcul indépendant du pilote sur `state.layout.children` et `state.t`).
Résultat sur la base : 2 PASS / 4 FAIL (CN0 et H0 verts).

| Cas | Attendu | Obtenu sur la base | Cause |
|---|---|---|---|
| CN1.1 compte par bord, quatre états (ajusté, coupé à gauche, coupé à droite, tout à droite) | `[true, true, true, true]` | `[true, false, true, false]` | aucun repère (2e : au moins un repère ; 4e : le compte n'est pas celui des cartes hors champ) ; le 3e est le témoin : des cartes sont bien hors champ |
| CN1.2 clic sur le repère droit | compte qui diminue, `k` et sélection inchangés | `sans clic` | aucun `button.vf-repere[data-bord=droite]` à cliquer |
| CN1.3 Tab depuis la carte itinérante | un `button.vf-repere` nommé « N cartes hors champ à <bord>. Aller à la plus proche. » | `[null, false]` | le focus va à un autre élément de la page |
| CN1.9 témoin | aucune section en échec | `cn1` | la section lève « élément absent : button.vf-repere[data-bord=droite] » |

Note : CN1.2 a été renforcée après la première trace (elle exige aussi que la carte la plus proche soit entièrement dans le champ : 5 valeurs au lieu de 4) ; sur la base
elle reste rouge (`sans clic`).

## Tâche 2 — bloc bas-droit, minicarte, ligne d'état (CN2)

Rejeu sur une copie de la base (`git archive 342a8763 plugin/cockpit`, `CN_SCRIPTS=<copie>/plugin/cockpit/scripts`) : le pilote et la suite sont ceux de la tête, le module est celui de
la base. Résultat : 2 PASS / 12 FAIL (CN0, H0 verts). Mesure indépendante lue sur la base : panneau `l = 1064`, `#ask` de 138 à 838 px, `freeArea().w = 1016`.

| Cas | Attendu | Obtenu sur la base | Cause |
|---|---|---|---|
| CN2.1 bloc à 1440 px | `[true, true, true, true]` | `bloc absent` | pas de `#vf-coin` |
| CN2.2 clic au centre de la minicarte | `[true, true]` | `sans clic` | pas de minicarte |
| CN2.3 tiroir Git, hachure | 11 valeurs vraies | `sans mesure` | ni `#vf-minicarte` ni hachure (les mesures `freeArea().w` et `state.t` identiques sont prises, avant et après l'ouverture : 1016 / 1016, `t` identique) |
| CN2.4 ligne d'état | 8 valeurs vraies | `sans mesure` | pas de ligne d'état |
| CN2.4b direct coupé, branche hostile | `["Direct coupé", true, "true,0"]` | `sans mesure` | idem |
| CN2.5 sans `--terminal` | `[0, false, 0]` | `sans mesure` | pas de bloc à mesurer (la mesure de fond, avec bloc, est portée par le mutant M-TERMINAL) |
| CN2.6 intersections | `["true,true,true,true", null, true]` | `["false,false,false,false", null, false]` | bloc absent à 1440 et 1024 px, ligne d'état absente au tactile à 1100 px |
| CN2.9 témoin | aucune section en échec | `cn22, cn24` | les sections lèvent faute de bloc |

## Tâche 3 — feuille de détail, tactile, terminal ouvert, focus orphelin, mouvement réduit (CN3)

Deux rejeux de la suite de la tête (pilote et suite de la tête, module d'une copie `git archive`).

**Sur la base 342a8763** (aucun des trois modules) : 5 PASS / 28 FAIL sur la suite entière. Rouges propres à CN3 : CN3.1 (tactile et moyen : aucun repère, `n = 0`), CN3.2
(`[true, false, false, true]` : onglets de 26,2 px, zone d'appui nulle), CN3.3a, CN3.3b, CN3.3c (pas de bloc, pas de repère), CN3.4a, CN3.4b, CN3.4c
(`activeElement` = `body`, `itin = "f:lots/n05.md"` : aucun repère donc rien à rendre), CN3.5 (« élément absent : button.vf-repere[data-bord=droite] »).

**Sur la tête de la tâche 2 (9e60d903)** : 28 PASS / 3 FAIL. Les repères de la tâche 1 portent déjà CN3.1, CN3.3a, CN3.3b, CN3.3c, CN3.4a, CN3.4b et CN3.5 : ces sept cas sont verts avant
le code de la tâche 3 (ils ne rougissent que sur la base, voir ci-dessus). Rouges réels de la tâche 3 :

| Cas | Attendu | Obtenu à 9e60d903 | Cause |
|---|---|---|---|
| CN3.2 onglets du téléphone | `[true, true, true, true]` | `[true, false, false, true]` | onglet de 26,2 px, une sonde à 3 px au-dessus et au-dessous tombe sur la piste, pas sur l'onglet (les boutons de zoom sont déjà à 44 x 44 : dernier élément vrai) |
| CN3.4c plus aucun repère | `[true, 0, "g", true]` | `[true, 1, "button", false]` | le pilote laissait un repère « haut » (dix clics sur « - » ne ramènent pas toutes les cartes dans le champ) : pilote corrigé (il recentre ensuite la boîte des cartes dans le champ), pas le module |
| H0 | aucun processus de la suite | un renderer d'aide de Chrome en train de mourir | aléa de charge connu (rejeu : vert) |

Rejeu final de la suite de la tête : 33 PASS / 0 FAIL (cinq mutants rougissent leur assertion).

## Défaut trouvé à la capture (CN2.3, mesure ajoutée après coup)

La capture claire à 1440 px montrait le cadre du champ de la minicarte plein et sombre : la règle `.vf-mini .vf-mc rect { fill: var(--text-4) }` (cartes) l'emportait sur
`.vf-mini .vf-mf { fill: none }` (même groupe, spécificité supérieure). CN2.3 n'en disait rien (géométrie seule). Mesure ajoutée (`getComputedStyle(cadre).fill === 'none'`, tiroir Git
fermé et ouvert), jouée avant la correction : `vide: false` aux deux états (`CN_SOLO=cn2:cn23`), puis `vide: true` après la règle `rect:not(.vf-mf)`.

## Correction ciblée après revue fraîche (gardes de forme, repères disjoints, focus)

Témoins ajoutés à la suite, joués sur une copie de la tête avant correction (`git archive`, pilote et suite de la tête, module d'avant) : 35 PASS / 2 FAIL sur 37, plus la mesure brute de CN3.6.

| Cas | Attendu | Obtenu avant correction | Cause |
|---|---|---|---|
| CN4 Projet en couloirs (`?vue=couloirs`, 1440 px puis 390 px tactile, après « + » x 8 et `deplacer`) | `[true x 9]` : canevas masqué, ni minicarte ni repère, ligne d'état gardée à 1440 | `[false, true, false, false, true, false, true, true, false]` (brut : 1440 `mini: true, reperes: 1` ; 390 `reperes: 1`) | `bloc()` et `maj()` ne testaient que `getClientRects().length`, qui reste vrai quand `#svg` est en `visibility: hidden` |
| CN3.4d nouveau bord, focus sur « droite » | focus gardé sur le repère droit | `[true, "body", null, true]` | `creer()` posait le nouveau repère juste après `#svg` : la boucle d'ordre déplaçait le repère focalisé |
| CN3.6 repères à 1000 et 1024 px, panneau et tiroir Git ouverts, état « milieu » | gauche et droite disjoints | première version du témoin verte (le panneau se refermait à l'ouverture du tiroir) ; après avoir rouvert le panneau, mesure brute `gauche [368,334,502,362]`, `droite [450,334,584,362]` à 1000 px, `[392,334,526,362]` et `[474,334,608,362]` à 1024 px : recouvrement de 52 px | `placer()` n'évitait que les surcouches, jamais les repères déjà posés |
| M-COMPTE (témoins ajoutés) | repères non vides, somme des `n` supérieure à celle des cartes hors champ | `[false, true, 4, true]` rejoué sur le mutant ; sur un module mort : `etats[].reperes` vides | le mutant et un module absent donnaient le même `[false, 4]` |

Corrections : `canevas()` (boîte de `#svg` ET `visibility` calculée non masquée, sans nom de forme) dans `02-vf-coin.js` et `02-vf-reperes.js` ; chaque repère posé devient un obstacle pour les suivants ; `creer()` insère le nouveau repère avant son premier suivant, sans déplacer les autres.
Remarque de méthode : sans `?vue=couloirs`, la visite guidée du premier passage laisse Projet en forme graphe (`vue=graphe`) : le témoin CN4 force la forme.
