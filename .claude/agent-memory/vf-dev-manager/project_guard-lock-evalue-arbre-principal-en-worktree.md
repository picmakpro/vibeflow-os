---
name: guard-lock-evalue-arbre-principal-en-worktree
description: guard-driver-lock, sur un worktree posé sous .claude/worktrees/, juge l'arbre principal (ses fichiers non suivis) et non l'index du worktree — refus de commit fantôme quand une autre mission tient le verrou
metadata:
  type: project
---
Depuis `.claude/worktrees/issues-A`, guard-driver-lock a refusé chaque `git commit` en citant « le commit embarque : .planning/workstreams/fiabilite/{config.json,milestone.lock,state.json} ». Ce sont des fichiers non suivis de l'arbre PRINCIPAL. L'index du worktree était vide de `.planning/`. Le verrou appartenait à une autre mission, sur main. Anomalie constatée le 2026-10-29, pas encore corrigée.

**Why:** un worktree placé sous la racine du lab est traité comme un sous-dossier du lab (C7o). L'isolation par worktree ne protège donc pas des verrous d'une autre mission.

**How to apply:** avant une mission en worktree, relever `driver-lock.sh status` ; si une autre mission peut prendre le verrou, prévoir d'emblée la voie commit-pret.sh ([[derogation-relayee-par-agent-refusee-par-les-workers]]). Ne jamais lancer `reclaim` ou `takeover` sur le verrou d'autrui.
