---
name: halt-tardif-cherry-pick-pas-stash
description: Un halt qui arrive après le worker trouve un commit, pas des modifs — la reprise est un cherry-pick ; et si l'arbre principal est sale, worktree au lieu de checkout
metadata:
  type: feedback
---

Deux gestes de récupération, appris ensemble le 2026-08-15 (Phase 28).

**1. Un ordre de halt arrive toujours APRÈS le worker.** Une consigne « ne commite rien, mets tes
modifs de côté » suppose un arbre modifié. Mais le worker a fini son mandat avant que le message
n'arrive : il n'y a pas de modifications à stasher, il y a un **commit**. La reprise est un
`git cherry-pick <sha>` sur la nouvelle base, pas un `git stash`. **Mesure avant d'obéir** :
`git log --oneline -3` + `git status --short` disent lequel des deux cas tu es.

**2. Arbre principal sale = worktree, jamais checkout.** Avant tout `git checkout` demandé dans
l'arbre partagé, relève `git status`. Des fichiers modifiés **que tes mandats n'autorisaient pas**
(ici `plugin/consolidator/*`, `plugin/installer/*`, `_internal/vibeflow-update.sh`) = une session
concurrente travaille en ce moment. Basculer l'arbre casse SA session et emporte son travail sur ta
branche. Fais `git worktree add -b <branche> <chemin-scratch> origin/main` : la branche vit dans le
dépôt partagé (les commits sont récupérables), seul le répertoire de checkout est jetable.

**Why:** le coordinateur a demandé `git checkout main` alors que l'arbre portait le travail non
committé d'une autre session ; et sa consigne « mets tes modifs de côté » visait un ARM_LINE déjà
committé (`aa1c5bd`). Les deux ordres étaient inapplicables tels quels — les exécuter littéralement
aurait détruit du travail tiers.

**How to apply:** mesure d'abord (`branch --show-current`, `log`, `status`), puis choisis le geste
qui atteint l'intention sans le dommage, et **dis-le au rapport** comme déviation assumée. Dans les
mandats de worker, donne le chemin ABSOLU du worktree et rappelle que le cwd est réinitialisé entre
les appels bash.

Voir aussi [[sessions-concurrentes-sur-le-repo]], [[verifier-contre-le-commit-de-base]],
[[relire-le-disque-avant-tout-rapport]].
