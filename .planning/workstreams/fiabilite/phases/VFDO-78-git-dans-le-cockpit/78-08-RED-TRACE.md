# 78-08 — traces des rouges (détail d'un commit, état des worktrees)

Reprise après le crash du 2026-11-05 : la suite `test-cockpit-git-details.sh` laissée par le prédécesseur (X1 seulement) a été relue contre le plan.
Un défaut de fixture corrigé AVANT de la rejouer : le lab n'avait pas de `.planning`, `vf-cockpit-build.mjs` refusait (« aucun dossier .planning trouvé »),
le serveur ne démarrait pas et les 26 assertions rougissaient pour une fixture morte. Après correction (lab GSD, `.planning` et `.vibeflow` dans `.git/info/exclude`),
X0.2 (serveur démarré, jeton lu) passe : le rouge ci-dessous vient donc de la seule absence de la route.

## Tâche 1 — rouge (route absente)

Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-git-details.sh`
Attendu : X1.1 à X1.5 en échec (aucun module, `/api/vf/git/commit` répond 404 comme toute route inconnue de `routeGit`).
Obtenu : `Résultats : 3 PASS / 25 FAIL` (PASS : X0.1 fixture, X0.2 serveur, H0 hygiène). Exemple : X1.1a attendu `200|vibeflow/cockpit-git-commit@1|ok|true|true`, obtenu `404|illisible` ;
X1.2 « sha court de 12 caractères » attendu `400|sha-invalide`, obtenu `404|illisible`.

## Tâche 1 — vert

`Résultats : 29 PASS / 0 FAIL` après `vf-cockpit-git-details.mjs` (`detailCommit`, `lireNumstat`), l'aiguillage de `/api/vf/git/commit` et le schéma. Deux défauts de TEST corrigés en chemin (pas de code) :
X1.1d tenait `@` pour un e-mail et matchait « cockpit-git-commit@1 » du champ `schema` (le schéma est désormais retiré avant le test) ; X1.6a (contrat contre réponse réelle) ajouté.

## Tâche 2 — rouge

Écart de méthode, dit tel quel : `etatWorktrees` et l'aiguillage `/api/vf/git/worktrees` ont été écrits dans le commit de la tâche 1 (le module a été rédigé d'un trait), AVANT les sections X2 à X5 de la suite.
Pour ne pas livrer un vert sans rouge, le rouge de X2/X3 est joué sur une COPIE de `plugin/cockpit` où la route et le corps d'`etatWorktrees` sont retirés
(`etatWorktrees` rend `indisponible`, la route worktrees est supprimée) :
`bash <copie>/scripts/tests/test-cockpit-git-details.sh` -> `64 PASS / 18 FAIL`, serveur démarré (X0.2 PASS : fixture vivante).
- X2.1a attendu `200|vibeflow/cockpit-git-worktrees@1|ok|false|null|5` ; obtenu un échec (404, corps illisible) ; X2.1b à X2.5 de même (modifies, nonSuivis, avance/retard, 200 entrées, `cd`, contrat).
- X3.1b attendu `ok|true|approximatif : filtres du dépôt non exécutés` ; obtenu un échec.
- X3.2d (route worktrees) attendu `403|200`, obtenu `403|404` : sans route, l'Origin de la page (témoin) ne rend pas 200.
- X3.1a PASSE sur la copie (un stub qui ne lance rien n'allume aucun marqueur) : c'est pourquoi X3.1b et le mutant M-FILTRES-STATUS existent.
Le code complet à l'état du commit de la tâche 1 donne, lui : `75 PASS / 7 FAIL` — X2.5 (schéma worktrees absent du contrat), X5.1a/b/c (refs sans date : `indisponible|undefined`, P78-D-31), X5.2c (description du schéma muette sur les auteurs), X4 M-IGNOREES (cible absente).
Rouge de P78-D-31 (X5.1a) : attendu `ok|3`, obtenu `indisponible|undefined` sur un dépôt dont 3 refs (tag vers un blob, tag vers un arbre, distante vers un blob) ont une date vide (témoin positif X5.0 : for-each-ref les rend bien à date vide).

## Mutants (rouge de CHACUN, assertion « avec effet » puis sonde)

Chaque mutant : (1) `mut.mjs` rend « applique » (la cible existe), (2) la sonde est verte sur l'original, (3) la sonde sur le mutant rend autre chose que l'attendu ET le module se charge. Obtenus au vert final :

| Mutant | Cible (copie) | Sonde | Attendu (original) | Obtenu (mutant) |
|---|---|---|---|---|
| M-MOTIF | les deux contrôles de motif retirés | sha court de 12 caractères | `400` | `404` |
| M-MOTIF | idem | 64 caractères dans un dépôt sha1 | `400` | `404` |
| M-VERIFY | comparaison de `rev-parse --verify` retirée | sha d'un arbre | `404` | `200` (`indisponible`) |
| M-PREMIER-PARENT | `<sha>^1 <sha>` remplacé par `-m <sha>` | merge `--no-ff` | `["f.txt"]` | `["f.txt","m.txt"]` |
| M-BORNE-FICHIERS | `fichiers.length < max` remplacé par `true` | commit de 600 fichiers | `500` lus | `600` |
| M-FILTRES-STATUS | `lancerGit` remplacé par `execFileSync` direct, GIT_SUR seul | status sur le dépôt piégé | marqueurs `absent\|absent\|absent` | `posé\|absent\|absent` (filter.f.process lancé) |
| M-IGNOREES | `f[3] === ''` remplacé par `false` | dépôt aux refs sans date | `ok\|3` | `indisponible\|undefined` |

Aucun mutant ne rougit pour une autre raison : chacun est précédé de l'assertion « cible présente » (`applique`) et de la sonde verte sur l'original, et la sonde exige un module chargeable (un `module absent` ou `illisible` ferait FAIL).
Vert final : `Résultats : 82 PASS / 0 FAIL` (`78-08-vert2.log`).

## Correction ciblée — P78-D-32 (2026-11-06)

- Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-git-details.sh`, assertion X6.1 (requête légère servie avant la fin de la lecture des worktrees).
- Attendu `true|ok|true`. Obtenu AVANT le code : `false|ok|true` (la lecture aboutit, elle est lente, la requête légère n'est servie qu'après : la boucle était bloquée). Log : scratchpad `78-fix-rouge-details.log`.
- Après : X6.1 vert ; M-SYNC rouge `false|ok|true` pour la même raison (X6.2 vert). Suite 85/0 (`78-fix2-git-details.log`) ; garde E6.5 et suite env 86/0.
