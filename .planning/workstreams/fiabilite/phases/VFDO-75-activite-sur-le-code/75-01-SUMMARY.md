# 75-01 — Calcul git : SUMMARY

Rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale).

## Livré

- `plugin/cockpit/scripts/vf-cockpit-activite-log.mjs` : `lireLog` (parseur positionnel aligné, chemins bruts), `fusionner`, `purger`, `resoudre` (alias de renommage).
- `plugin/cockpit/scripts/vf-cockpit-activite-git.mjs` : `FENETRE`, `PALIERS_MIN_FICHIERS`, `SEUILS_COUPLAGE`, `BRUIT`, `pointsChauds`, `couplage`, `calculerGit` (clé de cache, incrémental, dégradations sans champ partiel).
- `plugin/cockpit/scripts/vf-cockpit-activite-branches.mjs` : `PLAFOND_TETES`, `collisionsBranches` (par paire de HEAD, cache par paire de sha).
- `plugin/cockpit/scripts/vf-cockpit-git.mjs` : `monoVol` exporté, rien d'autre.
- Suite `plugin/cockpit/scripts/tests/test-cockpit-activite-git.sh` (G0 à G9, B1 à B9) et `75-01-RED-TRACE.md`.

## Écarts

- Écart : `merge-base` et `--is-ancestor` ne sont pas dans la liste fermée `SOUS_COMMANDES_AUTORISEES` (A-04). L'ascendance se lit par `rev-list --count HEAD..ancien` (0 = ancêtre) ; la base d'une paire par `rev-list --boundary A...B` (candidats départagés par `rev-list --count`). La sémantique de P75-D-10 est gardée (base commune, `diff-tree` de chaque côté) ; `git-durci.mjs` n'est pas touché.
- Écart : date du journal en `%ct` (date du committer) et non `%at` : `--since` filtre sur elle, la purge incrémentale rend ainsi les mêmes agrégats qu'une relecture complète.
- Écart : le tuple de couplage est `[a, b, communes, degré]` avec `a < b`, une seule fois par paire, chaque fichier apparaissant 5 fois au plus (sélection gloutonne par degré puis chemin).
- Écart : l'état gardé par l'appelant (`memo`) stocke les entrées brutes `{h, at, entrees}` et non `{h, at, chemins}` : les alias de renommage dépendent des commits plus récents et se recalculent à chaque agrégation.
- Écart : `collisionsBranches` rend aussi `plafond` ; `tetes` compte les HEAD vérifiés distincts avant plafonnement. Sans `--relative` : le journal de points chauds est celui du dépôt entier (chemins relatifs à la racine du dépôt), le préfixe du lab n'est retiré que par les collisions de branches.
- Cliquet de colonnes 79-11 (consigne du manager) : les trois modules ramenés sous 160 points de code, `colonnes-cliquet.mjs verifier` rend `OK`.
- Mutants non exécutés (régime allégé) ; chaque contrôle garde une assertion à témoin positif et négatif (voir la trace).

## Mesure de la liste `BRUIT` (hypothèse A1)

Sur ce dépôt, 90 jours, 4 152 commits hors merges : 395 paires sans retrait du bruit, 325 avec ; 80 des 395 impliquent un nom de la liste (ex. `VERSION` avec `module.json` à 100 %). Liste figée telle quelle (dix noms).

## Suites jouées

- `test-cockpit-activite-git.sh` : `BILAN : 76 PASS, 0 FAIL`, vert, environ 10 s.
- `test-cockpit-git.sh` (voisin de `monoVol`) : 118 PASS / 0 FAIL, environ 98 s.
- `scripts/check-machine-paths.sh` : vert ; `colonnes-cliquet.mjs verifier` : OK.

## À consigner ailleurs

CHANGELOG (« Non publié ») : écrit par 75-10 seul. Aucune route ni page branchée ici (75-05).

## Correctif de revue

- Majeur corrigé : `--relative` ajouté au journal des points chauds, tout chemin servi est relatif au lab ; témoin G10 vu rouge (`top.js` servi, chemins `sous/…`) puis vert. L'écart « sans --relative » ci-dessus est périmé.
- m5 : témoins G11 pour clé et worktrees, copie `C`, borne de `purger`, purge à HEAD inchangé (deux chemins) ; le tri de la base commune multiple va au BACKLOG. Suite : 82 PASS, cliquet OK.
- Le BACKLOG du compartiment n'existe pas : les lignes sont dans `.planning/BACKLOG.md`, à la suite des lignes 75.
