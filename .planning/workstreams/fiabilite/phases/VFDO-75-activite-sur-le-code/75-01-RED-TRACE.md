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
