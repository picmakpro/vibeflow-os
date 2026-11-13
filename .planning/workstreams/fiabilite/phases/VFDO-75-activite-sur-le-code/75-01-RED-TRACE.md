# 75-01 — Trace du rouge (témoin avant code)

Régime allégé (mandat commun de la Phase 75) : les mutants sont levés, seul le témoin rouge puis vert est exigé pour chaque tâche.
Chemins relativisés : `<tmp>` pour le dossier temporaire de la suite, `.` pour la racine du dépôt.

## Base

- Date : 2026-11-13.
- SHA RÉELLEMENT mesuré comme base du rouge : `d506bb6a` (tête de départ du mandat `f9e6fabd`, avancée par les commits des plans voisins 75-02 et 75-04 avant la mesure).
- Constats : `plugin/cockpit/scripts/vf-cockpit-activite-log.mjs`, `vf-cockpit-activite-git.mjs` et `vf-cockpit-activite-branches.mjs` n'existent pas ; `monoVol` est une fonction locale de `plugin/cockpit/scripts/vf-cockpit-git.mjs` (non exportée).
- `lancerGitAsync` vit dans `plugin/cockpit/scripts/vf-cockpit-git-lanceur.mjs` (79-07, dans la base).

## Tâche 1 — témoin G1 à G5 sur la base

- Assertion : import du module `vf-cockpit-activite-log.mjs` (première ligne de la suite après le chargement de la sonde).
- Attendu : module chargé, puis `lireLog` rend `{ok:true, commits}` sur une sortie réelle.
- Obtenu : `ERR_MODULE_NOT_FOUND` ; la suite sort 1 avec `BILAN : 0 PASS, 1 FAIL`.
- Bonne raison de l'échec : le témoin échoue AVANT d'évaluer la moindre assertion de comportement, donc le rouge ne prouve que l'absence du module. La bonne raison des assertions de comportement est établie par l'état intermédiaire de la tâche suivante (voir la section « Tâche 2 » : le couplage et le cache échouent sur les modules de la tâche 1 faute d'export, alors que G1 à G5 y restent verts).
- Vert après code (modules `vf-cockpit-activite-log.mjs` et `vf-cockpit-activite-git.mjs`, `monoVol` exporté) : `BILAN : 33 PASS, 0 FAIL`, G0 à G5 verts, exit 0.

## Tâche 2 — témoin G6 à G9 sur le code de la tâche 1 seul

Base du rouge : le commit de la tâche 1 (modules `vf-cockpit-activite-log.mjs` et `vf-cockpit-activite-git.mjs` sans `couplage`, sans clé de cache, sans incrémental).

- Assertion `G6.1` (défauts de couplage exportés) — attendu : `{"minCommunes":5,"minRevs":5,"minDegre":30,"maxFichiers":30,"voisins":5}` ; obtenu : `undefined` (export absent). G0 à G5 restent verts (33 PASS) sur cet état : la suite échoue pour la bonne raison, l'absence de la fonctionnalité de la tâche 2, pas celle du module.
- Assertion `G7.1` (rejouée avec la section G6 retirée d'une copie jetable de la suite, pour atteindre le cache) — attendu : `[1,true,1,1]` (un `log`, clé sha256, un `for-each-ref`, un `worktree list`) ; obtenu : `[1,false,0,0]` (aucune clé, aucune lecture des refs).
- Vert après code : `BILAN : 60 PASS, 0 FAIL`, exit 0.

### Seuils de couplage : preuves sans mutant (régime allégé)

Chaque contrôle a une assertion qui rougit s'il est retiré, faute de mutant exécuté (levé) : communes (G6.2, 4 contre 5), degré (G6.3, 29 % contre 30 %), taille d'ensemble (G6.4, 30 contre 31), bruit (G6.5, avec le témoin positif sur un fichier ordinaire), voisins (G6.6), tri (G6.7) ; contrôle « par fichier » : G6b.1 (`minRevs: 6` exclut alors que `minCommunes: 3` laisse passer), G6b.2 (défauts : exclu par les communes seules). Mutants non exécutés : rituel levé.

### Liste `BRUIT` mesurée sur ce dépôt (hypothèse A1 de la recherche)

Mesure (90 jours, 4 152 commits hors merges, historique complet, plafond non atteint ; relue par `calculerGit` avec `options: { bruit: [] }` puis avec la liste) :
- sans bruit retiré : 395 paires (5 voisins au plus par fichier) ;
- avec la liste figée : 325 paires ;
- 80 des 395 paires impliquent un nom de la liste (par exemple `VERSION` avec `module.json` à 100 % sur 8 à 17 révisions communes) : sans la liste, les fichiers de version dominent le couplage. La liste est donc figée telle quelle.
