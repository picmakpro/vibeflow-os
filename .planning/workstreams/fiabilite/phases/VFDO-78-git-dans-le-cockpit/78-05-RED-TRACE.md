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

## Tâche 2 — fenêtre bornée, non mergées, distantes, mergées repliées, refs hostiles, lecture seule (avant le code de la tâche 2)

Tête : `a8fbdd2a` (tâche 1 : un seul `log`, pas de non mergées, pas de base, pas de commande). Suite jouée : 25 PASS / 19 FAIL. Les rouges (attendu -> obtenu) :

| Assertion | Attendu | Obtenu |
|---|---|---|
| S2.1c pointe de `ancienne` dans `horsFenetre` (avance 1), sans rangée | `[["ancienne",1]]\|false` | `illisible` (champ absent) |
| S2.1d témoin : pointe de `longue` a sa rangée | true | false (aucun second `log`) |
| S2.2 30 branches non mergées : 30 pointes, 0 hors fenêtre | `30\|0` | `illisible` |
| S2.3a étiquette `distante:origin/f` + `locale:f` | `distante:origin/f,locale:f` | `illisible` |
| S2.3b base divergente, deux comptes | `["main",1,1,true]` | `illisible` (pas de champ `base`) |
| S2.3c commit propre à `origin/main` au graphe | true | false |
| S2.3d lab principal : base non divergente | `["main",false]` | `illisible` |
| S2.4a mergées = f,g1,g2,other | `f,g1,g2,other` | `illisible` (pas de `mergees`) |
| S2.4b commande de `f` | `git branch -d --end-of-options 'f'` | `illisible` |
| S2.4c aucune étiquette pour une mergée repliée | 0 | 4 |
| S2.4d étiquettes u1, origin/u1, wtb | `origin/u1,u1,wtb` | `wtb` (u1 et origin/u1 absents : pas de second `log`) |
| S2.4f worktrees (principal, ici, wtb, détaché) | 3 entrées | `illisible` |
| S2.5b..f refs hostiles : noms, commandes citées, bidi -> null, jeton -> null (P78-D-27) | 2 / 1 / 2 / 1 / 1 | 0 / 0 / 0 / 0 / 0 (aucune commande servie) |
| S2.6d tout `log` porte `-n`, refs `refs/…` ou sha ; au moins 4 lignes `log` vues | `vu\|0\|0` | `aveugle\|0\|0` (2 lignes `log` seulement) |
| S2.7b contrat : deux schémas et `interdits` | true | false |

Déjà verts avant le code de la tâche (cohérent : acquis de la tâche 1 ou témoins) : S2.1a/b (fenêtre de 500 de la tâche 1 ; c'est M-BORNE qui prouve la borne), S2.4e, S2.5a, S2.5g (vide tant qu'aucune commande n'est servie ; la preuve de P78-D-27 est S2.5f et son mutant), S2.6a/b/c/e/f (témoins et lecture seule).
Incident de suite corrigé avant ce rouge : `bash -n` rendait « unexpected EOF » (une citation `'` dans un `$(…)` de la suite, repérée à `bash -n` par dichotomie) ; la suite n'a jamais tourné cassée.
