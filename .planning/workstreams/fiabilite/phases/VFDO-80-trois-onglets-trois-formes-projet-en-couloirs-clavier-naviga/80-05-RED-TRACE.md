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
