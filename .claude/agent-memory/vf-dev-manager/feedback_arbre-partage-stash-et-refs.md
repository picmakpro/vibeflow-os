---
name: arbre-partage-stash-et-refs
description: Dans un worktree partagé, interdire dès le premier mandat stash/checkout/reset ET tout déplacement de ref — même un juge en worktree jetable déplace main pour tout le dépôt
metadata:
  type: feedback
---
Tout mandat, exécutant OU juge, doit interdire nommément dès le premier dispatch : `git stash` (toutes formes), `git checkout --`, `git restore`, `git reset`, et toute commande qui déplace une ref (`git branch -f`, `git update-ref`, `checkout -B`). Pour comparer à une version antérieure : `git show <rev>:<fichier>` ou un `git worktree add --detach` jetable. Pour muter des refs : un `git clone` jetable seulement.

**Why:** Phase 40.1, exécution (2026-09-16/17). Avec dix lots parallèles dans le même arbre, trois workers ont fait un stash/pop pour obtenir leur « rouge d'avant-édition » : sans perte cette fois, mais un stash sans pathspec emporte l'arbre entier des voisins. La session principale a exigé l'interdiction. Ensuite, un vf-auditer « lecture seule » a lancé `git branch -f main 713c621` dans son worktree jetable : les refs étant partagées entre worktrees, le `main` du dépôt a bougé, et `phase-base.sh` de la clôture a résolu une mauvaise base. Il a fallu le reflog pour trouver la cause.

**How to apply:** ajouter la ligne d'interdits aux mandats de revue, d'audit et de vérification, pas seulement aux exécutants — « lecture seule » ne suffit pas à l'empêcher. Après chaque retour de juge, constater `git rev-parse main origin/main`. Pour prouver un « rouge d'avant », la forme sûre est `git show HEAD:<outil>` copié dans le scratchpad. Voir [[commit-par-pathspec-pour-paralleliser]].
