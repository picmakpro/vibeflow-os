# 80-08 — trace du rouge (P80-D-25)

Base : copie de `plugin/cockpit` sans `ui/42-vf-panneau-retour.js` (aucun module, aucune ligne `AJOUT`), suite `test-cockpit-panneau-retour.sh`,
pilote `chrome-panneau-retour.mjs`, vrai Chrome sans tête. Résultat : 5 PASS / 25 FAIL.

## Rouges pour la bonne raison (aucun bouton, aucune globale)

| Cas | Attendu | Obtenu sur la base |
|-----|---------|--------------------|
| PR1.1 | `[1,"true","Retour, indisponible",0]` | `mesure absente : Cannot read properties of null (reading 'n')` (aucun `.vf-retour`) |
| PR1.2 | `["n:ph-1",1,"false","Retour : Phase 2 · Écran",…]` | `Cannot read properties of null (reading 'dis')` |
| PR1.3 | `["n:ph-2",0,"true",true]` | `Cannot read properties of undefined (reading 'sel')` (le lien n'a rien empilé) |
| PR2.6a | `[[true,2],true,2]` | `[[true,null],true,null]` (`window.VF_PANNEAU` absent : taille nulle) |
| PR2.10a/b | `[false,"false",true,true,true]` | `Cannot read properties of null (reading 'couvert')` (aucun bouton à viser) |
| PR2.1 à PR2.5, PR2.7 | tableaux de la suite | sections du pilote en échec ou valeurs nulles : `empiler` n'existe pas |
| M-REEMPILE, M-HTML, M-BORNE, M-GLOBALE | « mutation impossible » | le module est absent : rouge attendu, le mutant n'a rien à muter |

## Verts sur la base (témoins)

- PR0 (serveur du lab), PR2.8 (equipe.html et index.html : aucun `.vf-retour`, `VF_PANNEAU` indéfini) : vert sur la base, c'est le témoin que M-GLOBALE rougit.
- PR2.6d, PR2.10c : sections de pilote sans exception (les valeurs, elles, sont rouges ci-dessus). H0 : aucun processus ne survit.
- PR2.9 : « ⏳ ATTENTE » (41-vf-projet-liste.js absent de l'arbre : couplage avec 80-07), ni PASS ni FAIL.

## Mutants (copie du module dans `$WORK`, copie maison de couloirs-commun.sh)

| Mutant | Fichier muté | Mutation | Assertion qui rougit |
|--------|--------------|----------|----------------------|
| M-REEMPILE | 42-vf-panneau-retour.js | `enRetour = Date.now() + DELAI` -> `enRetour = 0` (Retour réempile) | PR1.3 |
| M-HTML | 42-vf-panneau-retour.js | `texte.textContent = …` -> `texte.innerHTML = …` (titre sans échappement) | PR2.4 |
| M-BORNE | 42-vf-panneau-retour.js | `BORNE = 32` -> `BORNE = 3200` | PR2.3 |
| M-GLOBALE | 42-vf-panneau-retour.js | `window.VF_PANNEAU = {}` avant la garde d'onglet | PR2.8 |

## Correction ciblée du 2026-11-12 (revue de deux juges frais)

Base : copie de `plugin/cockpit` avec le module tel que commité en `d455327b` (avant correction), suite du jour : 31 PASS / 15 FAIL.

| Cas | Attendu | Obtenu sur le module d'avant |
|-----|---------|------------------------------|
| PR2.15a (Entrée, actif) | `{"sel":"n:ph-2","cont":"root","taille":0,"foc":"vf-retour","meme":false}` | focus `vp-carte` (le focus tombe sur la carte, le bouton reposé ne le reprend pas) |
| PR2.15c (Entrée, désactivé) | `{"sel":"n:ph-2","cont":"root",…,"foc":"vf-retour","meme":true}` | `{"sel":null,"cont":"n:ph-2",…,"foc":"vf-tab-project vf-forme-graphe"}` : le moteur a plongé dans la phase |
| PR2.15b, PR2.15d (Espace) | idem | rouges aussi |
| PR2.16 (retour() sur pile vide) | `{"foc":"vf-retour","meme":true,"taille":0}` | `{"foc":"vf-tab-project vf-forme-couloirs","meme":false,…}` : bouton reconstruit, focus sur body |
| PR2.2 (plan) | `ro=["C"]`, « Retour : B », taille 2 | `ro=["C","B"]`, « Retour : A », taille 1 (B rouverte dans le même clic) |
| PR2.7 (deux thèmes) | `["true",true,"500","13px"]` | poids de police `400` (aucun `font-weight`) |
| PR2.14 | texte coupé 12 + … + 11 | bouton absent de la section (rouge d'un autre ordre : le pilote lit un champ avant le correctif de la suite) |

PR2.11 (M-DEHORS) et PR2.12 (M-NULL) sont des témoins de couverture : verts sur le module d'avant (le comportement existe), leur valeur est que le mutant correspondant les fait rougir
(un premier rejeu isolé de PR2.12 sur le module d'avant rend `[1,0]` ; un rouge `[0,0]` vu dans le rejeu complet était un aléa de charge).

Nouveaux mutants (copie du module dans `$WORK`, copie maison de couloirs-commun.sh), tous dans `42-vf-panneau-retour.js` :

| Mutant | Mutation | Assertion qui rougit |
|--------|----------|----------------------|
| M-DEHORS | retrait des écouteurs `pointerdown` et `keydown` « dehors » | PR2.11 |
| M-NULL | retrait de `sel == null \|\| typeof sel !== 'string' \|\|` | PR2.12 |
| M-COUPE | `a.length <= COUPE` -> `a.length <= 1e9` | PR2.14 |
| M-ENTREE | retrait du `stopPropagation` d'Entrée et d'Espace sur le bouton | PR2.15a, PR2.15c |
| M-VIDE | retrait de `if (!pile.length) return;` | PR2.16 |
