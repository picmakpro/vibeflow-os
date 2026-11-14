# 75-09a — trace de rouge (retrait de la couche « Travail récent », assemblage et moteur)

Base du rouge : `7be166b5e` (tête après 75-01 à 75-08 et le correctif de la suite de la carte). Chemins relativisés.

## Inventaire avant (grep d'inventaire de la précondition, hors CHANGELOG)

Écarts avec la table de 75-RESEARCH § Retrait (numéros périmés par les Phases 74, 79, 80) :
- l'écriture de la couche est en `plugin/cockpit/scripts/vf-cockpit-build.mjs` (ligne ~159, non plus 70-80) ;
- `viewer.html:671` et `recent-hl` : aucune des deux n'est une exception, `recent-hl` et `setRecentShown` restent dans `viewer.html` (retirés par 75-09b) ;
- `assets/ui/25-recent.js`, `78-vf-fr-dict-a.js`, `00-vibeflow.js`, `01-vf-responsive.js`, `02-vf-telephone.js` : consommateurs de la page (75-09b).

Autres consommateurs de `.cache/changes.json` (écrit par `refresh.mjs` « for recent.mjs ») : AUCUN, hors `recent.mjs` lui-même. L'écriture et son commentaire sont donc retirés avec `recent.mjs`.

## Comptes d'assertions (avant, après)

| suite | avant | après |
|---|---|---|
| `test-cockpit-onglet-code.sh` | 32 | 47 (+15 : Q1.1 à Q1.5, Q2.1, Q2b.0, Q2b.1, Q4.1, Q5.1 à Q5.3, Q6.1, Q6.2, Q7.1) |
| `test-cockpit-securite.sh` | 104 | 106 (+2 : Q3.1, Q3.2) |

Assertions ADAPTÉES (intention nommée) :
- `C6.3` (« le titre du travail récent est entier ») : la couche disparaît, l'assertion devient « aucun fichier de la couche n'est écrit » ; l'intention « un titre long de phase reste entier, jamais coupé à 60 caractères » passe à `Q2.1`, sur le nœud de phase de la page Projet (même titre, même attendu `Phase 1 · <titre>`).
- Série `Y` de `test-cockpit-securite.sh` : le lien symbolique posé sur l'ancien fichier de la couche est posé sur `.gitignore` (écrit par le socle, après `verifierSortie`) ; `graph.json` garde le sien ; Y1 et Y2 inchangés dans leur texte et leur attendu.

## Rouge sur la base (suite `test-cockpit-onglet-code.sh`, 36 PASS / 11 FAIL)

| assertion | attendu | obtenu | bonne raison |
|---|---|---|---|
| C6.3 | `absent` | `présent` | l'assemblage de la base écrit le fichier |
| Q1.2 | `absent` | `présent` | le fichier hérité est conservé |
| Q1.3 | `undefined` | `object` | le graphe porte `recent` |
| Q4.1 | `0` | `8` | le moteur lit le fichier et écrit sa ligne de rapport |
| Q5.1 | `absent` | `présent` | `recent.mjs` existe |
| Q5.2 | `0` | `2` | `refresh.mjs` recommande l'étape de marquage |
| Q5.3 | `0` | `2` | des mentions du script subsistent |
| Q6.1 | `0` | `2` | `graph-query.js` porte `recentWork` |
| Q6.2 | `0` | `1` | `60-export.js` porte la partie d'export |
| Q7.1 | `0` | `13` | formes de la couche dans les cinq fichiers |
| Q1.5 | `4:dehors` | `0:dehors` | premier jet : `ln -s` échouait sur un fichier déjà écrit par la base ; corrigé (`rm -f` avant le lien), l'assertion est alors un témoin de NON-RÉGRESSION (verte sur la base : le lien est refusé par `verifierSortie`) |

Verts dès la base, par nature : `Q1.1`, `Q1.4`, `Q2.1`, `Q2b.0`, `Q2b.1` (carte prévue livrée par 75-06 ; ne dépend pas du retrait).

## Q3 (sonde Y reportée sur `.gitignore`)

`Q3.1` (lien sur `.gitignore` seul : refus code 4, cible hors du lab intacte) est verte sur la base : `verifierSortie` refuse avant l'écriture. Le témoin rouge est `Q3.2` : une COPIE du module dont les appels à `verifierSortie` sont neutralisés réécrit `dehors.txt` (réponse `réécrit`) ; sur le code livré la même sonde `Q3.1` rend `intact`. Le mutant ne sert que cette preuve ; les autres mutants du plan sont levés (régime allégé).

## Après

`test-cockpit-onglet-code.sh` : 47 PASS / 0 FAIL ; `test-cockpit-assemblage.sh` 55 PASS ; `test-cockpit-routes.sh` 56 PASS ; `check-machine-paths.sh` vert. `test-cockpit-securite.sh` : 106 PASS / 0 FAIL (Q3.2 vert : le mutant réécrit bien la cible).
