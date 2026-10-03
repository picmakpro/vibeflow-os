---
name: executeurs-forces-en-worktree
description: En session isolée, la garde du harnais refuse tout gsd-executor sans isolation="worktree" — chaque plan atterrit sur une branche d'agent que le manager rapatrie en fast-forward après contrôle de base
metadata:
  type: project
---

Phase 45 (2026-09-30), session isolée dans un worktree : la garde du harnais (`dispatch-isolation =
harness-worktree`) a refusé le dispatch d'un `gsd-executor` sans `isolation="worktree"`. Les commits
de chaque plan arrivent donc sur `worktree-agent-<id>`, pas sur la branche de mission. Avec
`baseRef: head`, la base du worktree d'agent a bien suivi le HEAD de la branche de mission
(vérifié : `02d848b` ancêtre de la base de l'exécuteur de 45-03).

**Why:** le mandat interdit merge et checkout au worker. Si le manager ne rapatrie pas, les plans
suivants partent d'une base sans leurs dépendances, et le rapport annonce « livré » un travail
absent de la branche.

**How to apply:** dans chaque mandat d'exécution, exiger `git merge-base --is-ancestor <HEAD
attendu> HEAD` dans le worktree de l'exécuteur avant toute exécution, et la remise branche +
chemin + SHA. Côté manager : `git merge-base --is-ancestor HEAD <branche-agent>`, puis `git merge
--ff-only`, puis la non-régression complète. `gsd-quick` en correction ciblée, lui, a codé
directement sur la branche de mission (pas d'exécuteur secondaire). Voir
[[execute-phase-filtre-par-vague-pas-par-plan]] et [[baseref-head-contamine-les-mesures-isolation]].
