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
