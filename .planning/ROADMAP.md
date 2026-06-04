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
**Plans**: TBD (raffiné en plan-phase — découpage indicatif ci-dessous)

Plans:
- [ ] 01-01: Scaffolding module + générateur d'index (`build-gsd-index.sh` → `gsd-skills-index.md`)
- [ ] 01-02: Bootstrap auto-install (`ensure-deps.sh` + fallback manuel)
- [ ] 01-03: Agent `vibeflow-dev` (`AGENT.md`) + doctrine pipeline (`references/GSD-PIPELINE.md`)
- [ ] 01-04: Couche d'abstraction — skills `/vf-*` + traduction de vocabulaire
- [ ] 01-05: Vérification (`tests/`) + intégration `vibeflow-update.sh` + README

## Progress

**Execution Order:**
Phase unique : 1

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. dev-orchestrator | 0/5 | Not started | - |
