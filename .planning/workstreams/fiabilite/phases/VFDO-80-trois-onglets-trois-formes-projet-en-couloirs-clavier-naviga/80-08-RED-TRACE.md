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
