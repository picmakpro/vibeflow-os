---
phase: 57-verrou-de-driver-par-compartiment
plan: 12
subsystem: conductor
tags: [doctrine, driver-lock, team-kernel, managers, vf-split-planning]
requires:
  - phase: 57-10
    provides: "mission-flow.md §Verrou par compartiment (lab partitionné), prompts dev"
key-files:
  modified: [plugin/conductor/references/team-kernel.md, plugin/design-orchestrator/agents/vf-design-manager.md, plugin/business-pilot-bundle/agents/vf-business-manager.md, plugin/content-bundle/agents/vf-content-manager.md, plugin/growth-bundle/agents/vf-growth-manager.md, plugin/conductor/skills/vf-split-planning/SKILL.md]
key-decisions:
  - "P57-D-36 réalisée (ratifiée, AskUserQuestion session principale, 2026-10-10) ; limite P57-D-20 écrite dans team-kernel"
requirements-completed: [DLWS-02, DLWS-07]
status: complete
completed: 2026-10-10
---

# Phase 57 Plan 12: Kernel, managers hors dev et partition sous verrou de dépôt Summary

**team-kernel.md dit « une mission pilote par compartiment, un geste de dépôt à la fois » avec la limite P57-D-20 ; les quatre managers hors dev passent `--ws` à instructions constantes ; la partition acquiert `--depot` avant le geste.**

## Transcriptions
- **Kernel** (clone partitionné jetable, `<sujet>`=alpha, `<id>`=d1) : acquire --ws, heartbeat, `status --ws | jq -r .generation` (`DRIVER.lock.gen.…`), release --ws, acquire/release --depot, `status --all` : 7 commandes, 7 × exit 0 (`RC_ALL=0`). Sonde : scratchpad `57-12-probe-kernel.sh`.
- **Partition** (lab plat jetable) : `acquire --depot --owner=vf-split-planning` exit 0 ; second `acquire` `{"acquired": false, "reason": "held", "held_by": "vf-split-planning"}` exit 1 ; `split-planning.sh --path . --name essai` `{"mode":"plat","subject":"essai","state":"complete"}` exit 0 ; `release --owner=vf-split-planning` `"released": true, "scope": "depot", "legacy_lock": true` exit 0. Mesure préalable : le moteur LAISSE `.planning/DRIVER.lock` et `DRIVER.lock.gen.*` à la racine de `.planning/` (condition d'arrêt non déclenchée). Sonde : `57-12-probe-split.sh`.

## Mesures
`check-instruction-budget.sh` exit 0 (instructions design 30/30, business 21/21, content 14/14, growth 25/25 ; lignes design 196, growth 172 en hausse, sans effet : ratchet sur instructions seules) ; `check-agents.sh --strict` exit 0 sur les 4 dossiers ; `check-skills.sh --strict` exit 0 ; `check-ajout-retrait.sh --strict` exit 0 ; `check-baseline-arbitrage.sh` 0 ; `test-design-orchestrator.sh` 51/0 ; `test-vf-split-planning.sh` 40 cas/0 échec ; business 16/0, content 14/0, growth 14/0, `test-check-agents.sh` 200/0, `test-dev-orchestrator.sh` 279/0. SKILL.md 155 lignes (≤ 500).

## Commits
`56150de7` kernel + design · `87814cfd` bundles · `96710f20` partition

## Déviations
None - plan executed exactly as written. Précision : la sonde de partition exige un STATE.md à ligne `Phase:` et un ROADMAP à phases (fixture du moteur), sans incidence sur le skill.

## Problèmes
`check-version-sync.sh` rouge (compte de suites) : attendu jusqu'à 57-15.

## Self-Check: PASSED
Six fichiers modifiés, trois commits, critères d'acceptation rejoués (grep 1 / 1 / ≥1 ; 1 / ≥1 ; budget, agents, suites exit 0).
