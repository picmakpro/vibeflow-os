---
name: guard-verrou-juge-l-arbre-principal-depuis-un-worktree
description: guard-driver-lock refuse un git commit fait depuis un worktree isolé quand une autre mission tient le verrou, et liste les non-suivis .planning/ de l'arbre PRINCIPAL comme « embarqués »
metadata:
  type: project
---

Constaté le 2026-10-28/29, lot B de la passe de clôture des issues, worktree `.claude/worktrees/issues-B`. Quand une autre session tient le verrou `fiabilite` sur main, le PreToolUse `guard-driver-lock.sh` refuse les `git commit` du worktree. Son motif cite des fichiers `.planning/workstreams/fiabilite/*` non suivis de l'arbre principal, alors que l'index du worktree ne les contient pas. Le message conseille « travaille dans un arbre séparé », ce qui était déjà le cas. Le refus est intermittent : il disparaît dès que le verrou est relâché. Deux commits sont passés pendant que le verrou était tenu, deux autres ont été refusés.

**Why:** le guard résout le verrou par le git-common-dir et juge l'arbre principal, pas le worktree d'où part la commande. Résultat : un worker se bloque sans faute de sa part, et un worker ne peut pas accepter de moi l'autorisation de passer outre (voir [[joignabilite-asymetrique-manager-worker]]).

**How to apply:**
- Dès qu'une mission tourne en parallèle sur main, faire porter par la session principale l'arbitrage du marqueur `vibeflow:allow-lock-override`, avec canal et date.
- Inscrire cette citation dans le mandat INITIAL de chaque worker, avec ses conditions : aucun `.planning/` dans `--cached`, jamais vers main.
- Sinon, commiter soi-même le travail prêt, après avoir vérifié `git diff --cached --name-only`.
- Jamais de reclaim ni de takeover.
