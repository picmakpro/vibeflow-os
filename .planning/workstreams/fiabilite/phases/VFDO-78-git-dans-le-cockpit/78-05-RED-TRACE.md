# 78-05 — traces des rouges (route GET /api/vf/git, lecture seule)

Commande de base : `bash plugin/cockpit/scripts/tests/test-cockpit-git.sh` (git 2.50.1 ; serveur réel sur port éphémère, dépôt fabriqué : 14 commits, octopus, seconde racine, 2 worktrees, 2 tags, 2 stash).

## Tâche 1 — tracer (avant tout code de `vf-cockpit-git.mjs`)

| Assertion | Attendu | Obtenu (avant code) |
|---|---|---|
| S1.1a statut de `GET /api/vf/git` | 200 | 404 |
| S1.1b schéma et état | `vibeflow/cockpit-git@1\|ok` | `illisible` (corps vide) |
| S1.1c rangées à colonne entière | true | `illisible` |
| S1.1d rangée d'octopus à 3 parents | true | `illisible` |
| S1.2d témoin (Origin de la page) | 200 | 404 |
| S1.2a POST, S1.2b sans jeton, S1.2c Origin tierce | 405 / 403 / 403 | 405 / 403 / 403 : **déjà verts sur la base**, ce sont des témoins du plan (les contrôles existants s'appliquent avant la route) |

Résultat : 5 PASS / 5 FAIL. Premier jet du fixture : l'octopus était fast-forwardé en merge à 2 parents (main n'avait pas bougé depuis g1/g2) ; corrigé par un commit `m1b` sur main avant la fusion (S1.1d le mesure).
