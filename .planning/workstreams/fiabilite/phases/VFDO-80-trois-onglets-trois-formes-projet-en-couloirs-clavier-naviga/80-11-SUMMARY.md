# 80-11 — le vocabulaire du planning dans le panneau de Projet (FORM-08) : SUMMARY

## Livré
- Côté données : `vf-cockpit-project.mjs`, `meta.kindLabels` gagne les clés à préfixe (`feuille:`, `parent:`, `liste:`, `entrant:`, `sortant:`, `ouvrir:`, `champ:`,
  `valeur:`, `statut:exigences:*`), `sortant:data` = chaîne vide (commits 25fef083 puis 6d689419). Aucun champ retiré ni renommé.
- Côté panneau : `viewer.html` (garde `vfTab === 'project'`, une constante `PROJ` et l'accesseur `KL`) : type d'une feuille, ligne du parent, listes d'un nœud
  titrées et sans compte, bouton « Ouvrir la phase », listes de liens par sens et par genre, étiquette vide non rendue, règle « document » neutralisée,
  statistiques du code retirées, bloc Statut / Vague (6d689419, ff97088d) ; `ui/41-vf-projet-panneau.js` neuf : « Exigences couvertes » par la porte
  `lireExigences` lue à chaque rendu, ligne d'état de phase, synthèse et barre de jalon (1b6eb0a0, df5f7dbc) ; ligne `AJOUT` de `VENDORED.txt`.
- Suite `test-cockpit-projet-vocabulaire.sh` + pilote `chrome-projet-vocabulaire.mjs` : 18 PASS, dont PV2.5 (porte substituée) et PV2.7 (porte relue après un
  aller-retour d'onglet). Rouge de base tracé dans `80-11-RED-TRACE.md`.

## Écarts
- Écart : sur Code le type d'un fichier se lit « fichier » (le plan disait « Élément ») ; PV1.3 prend la valeur mesurée.
- Écart : `grep -c "kindLabels\["` de `viewer.html` vaut 0 (le critère visait ≥ 3) : l'accès passe par `KL`, lecture `kindLabels?.[…]` ; critère de forme, pas de fond.
- Écart : les statistiques d'un nœud et d'une feuille sont retirées en bloc sur Projet (plutôt que filtrées à 0) : « éléments », « lignes », « points d'accès »
  sont des mots du code. Les listes d'un nœud sont celles du nœud et de ses sous-nœuds (Plans, Exigences), un nœud sans clé `liste:` (le jalon) n'en rend pas.
- Écart : clés neuves `parent:*` (exigences, mission, backlog, graine, release) et `statut:exigences:*` pour qu'aucun « module » ne reste sur Projet.
- Pour la 76 (clés de libellé qui nomment le nœud et le lien de couverture, à retirer avec eux, 76-08) : `feuille:exigences`, `liste:exigences`, `parent:exigences`,
  `statut:exigences:done`, `statut:exigences:todo`, `entrant:data`, `sortant:data`.
- Ordre des sections d'une phase observé : en-tête, ligne d'état, « Contenu », « Plans », « Exigences », puis les sections ajoutées (rang d'enregistrement), « Détails
  techniques » ; non touché : `addPanelSection` et `setOverview` gardent signature et ordre.
- Mutants M-MENTIONS, M-ELEMENT, M-DOUBLE, M-PORTE, M-CACHE : levés (régime allégé), cas PV3.2 (section du pilote par `addPanelSection`) non écrit.

## Suites (sur la tête commitée)
test-cockpit-projet-vocabulaire 18/0 ; moteur-carte, lancer-ui, panneau-retour, projet-liste, couloirs, projet-champs : 0 échec ; chrome-fr : 0 échec après la
correction F17.1 ; vendor : V4c.9a vert, un rouge V4 (`70-vf-live.js` à 300 lignes, fichier d'un autre plan, hors périmètre) ; projet-graphe : 1 rouge P10.5 sous charge (613 s) puis 119/0 rejoué seul.

Ligne de CHANGELOG demandée par 80-18 : « Panneau de Projet : le vocabulaire du planning (Plan, Exigence, Dans la phase, Statut, Vague, Exigences couvertes), plus de
« Élément », « module » ni « Mentions » sur Projet. »

rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale)
