---
name: execute-phase-filtre-par-vague-pas-par-plan
description: gsd-execute-phase ne discrimine qu'au niveau vague — dispatcher deux vf-coder sur deux plans d'une MÊME vague fait redispatcher le plan du voisin ; le worker doit exécuter inline via execute-plan.md
metadata:
  type: project
---

`gsd-execute-phase` (moteur de découverte `phase-plan-index`, filtre `--wave N`) **ne discrimine
qu'au niveau vague, jamais au niveau plan individuel**. Il n'existe **aucun flag `--plan`**.

**Why:** constaté Phase 31 (2026-08-16). J'avais dispatché deux `vf-coder` en parallèle sur `31-01`
et `31-02` — deux plans de la **même vague 1**, aux périmètres de fichiers disjoints. Le worker de
`31-02` a invoqué le skill comme je le lui demandais, puis a **refusé de continuer** : le skill
aurait redispatché une exécution de `31-01` en parallèle du worker qui le faisait déjà, en
violation directe de l'interdiction de son propre mandat. Il a bifurqué vers `execute-plan.md`
(le document que le PLAN.md référence lui-même dans son `<execution_context>`) et exécuté les
tâches **inline**, avec commits atomiques par pathspec. Bon réflexe, mais il l'a trouvé seul.

**How to apply:** quand la frontière `dag.sh ready` contient **≥ 2 plans d'une même vague** et que je
veux les paralléliser, **ne pas faire invoquer `gsd-execute-phase`**. Mandater explicitement
l'exécution **inline via `execute-plan.md`**, en nommant le plan unique à exécuter. Sinon, un seul
worker pour toute la vague. Conséquences à assumer dans le mandat :

- **Aucun `31-NN-SUMMARY.md` n'est écrit** (il est produit par la machinerie du skill), et aucun
  hook `execute:post` ne rend de `verdicts` (`code_review`/`nyquist`/`secure`) — donc **rien à
  relayer verbatim** : ne pas fabriquer une valeur `absent` pour trois sous-champs jamais évalués.
  Si je veux les SUMMARY, les autoriser nommément (`31-NN-SUMMARY.md` seul, nom disjoint entre
  workers, donc sans collision) plutôt que d'interdire tout `.planning/` en bloc.
- Pas d'`actuals` non plus (hors machinerie `state.record-metric`) — l'`estimate` du frontmatter
  reste seul.

Voir [[commit-par-pathspec-pour-paralleliser]] pour la discipline de commit qui va avec, et
[[dispatches-via-skills-non-forkees]] pour la règle générale sur les skills nommant des agents.
