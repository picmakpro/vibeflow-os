# Roadmap: VibeFlow Dev Orchestrator (VFDO)

## Overview

Une seule phase livre le module `dev-orchestrator/` complet : le bootstrap d'auto-install,
l'index GSD auto-généré, l'agent routeur, la couche d'abstraction `/vf-*`, et la vérification.
Le module est ensuite branchable sur n'importe quel lab via `vibeflow-update.sh`.

## Phases

- [ ] **Phase 1: dev-orchestrator** - Module complet VibeFlow → GSD + Superpowers (agent routeur, index auto, verbes `/vf-*`, bootstrap auto-install)

## Phase Details

### Phase 1: dev-orchestrator
**Goal**: Livrer le module `dev-orchestrator/` distribuable, qui rend GSD + Superpowers invisibles et auto-installés derrière un agent VibeFlow.
**Depends on**: Nothing (first phase)
**Requirements**: ROUT-01, ROUT-02, ROUT-03, ROUT-04, IDX-01, IDX-02, ABS-01, ABS-02, BOOT-01, BOOT-02, BOOT-03, BOOT-04, VERIF-01, VERIF-02
**Success Criteria** (what must be TRUE):
  1. Sur une machine sans GSD ni Superpowers, brancher le module les installe automatiquement (ou affiche les étapes manuelles si Node/`claude` manquent).
  2. L'utilisateur formule une demande dev en langage naturel et l'agent lance le bon skill GSD/superpowers sans jamais nommer « GSD ».
  3. `references/gsd-skills-index.md` est généré depuis les skills GSD réellement installés (aucun nom inventé) et se régénère sur update.
  4. Les verbes `/vf-*` existent, mappent vers une cible réelle, et sont invocables par l'agent en autonomie (dont `gsd-autonomous`).
  5. `test-dev-orchestrator.sh` passe à 100% et les gates de densité (agent ≤250L, skills ≤500L) sont verts.
**Plans**: 5 plans en 4 waves

Plans:
- [x] 01-01-PLAN.md — Scaffolding module + générateur d'index (`build-gsd-index.sh` → `gsd-skills-index.md`) [wave 1]
- [x] 01-02-PLAN.md — Bootstrap auto-install (`ensure-deps.sh` + fallback manuel, BOOT-01..04) [wave 1]
- [ ] 01-03-PLAN.md — Agent `vibeflow-dev` (`AGENT.md`) + doctrine pipeline (`references/GSD-PIPELINE.md`, ROUT-01..04) [wave 2]
- [ ] 01-04-PLAN.md — Couche d'abstraction : 12 skills `/vf-*` + traduction de vocabulaire (ABS-01..02) [wave 3]
- [ ] 01-05-PLAN.md — Vérification (`tests/`) + intégration `vibeflow-update.sh` + README (VERIF-01..02) [wave 4]

## Progress

**Execution Order:**
Phase unique : 1
Waves : {01, 02} → {03} → {04} → {05}

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. dev-orchestrator | 0/5 | Not started | - |
