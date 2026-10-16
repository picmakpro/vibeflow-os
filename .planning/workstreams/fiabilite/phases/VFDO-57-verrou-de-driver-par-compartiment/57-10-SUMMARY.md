---
phase: 57-verrou-de-driver-par-compartiment
plan: 10
subsystem: dev-orchestrator
tags: [doctrine, driver-lock, workstream, prompts, head-governance]
requires:
  - phase: 57-03
    provides: "driver-lock.sh --ws/--depot, status --all, registre frère du verrou"
  - phase: 57-07
    provides: "check-mission-exit.sh --ws, --budget-snapshot exit 4 sans --ws"
provides:
  - "mission-flow.md : section « Verrou par compartiment (lab partitionné) », registre par verrou, snapshot --ws"
  - "prompts vf-dev-manager / vf-coder / vf-reviewer portant --ws, à instructions constantes"
  - "head-governance, intent-routing, mission-cross-team : invariant « un manager par compartiment »"
key-files:
  modified: [plugin/dev-orchestrator/references/mission-flow.md, plugin/dev-orchestrator/agents/vf-dev-manager.md, plugin/dev-orchestrator/agents/vf-coder.md, plugin/dev-orchestrator/agents/vf-reviewer.md, plugin/dev-orchestrator/references/head-governance.md, plugin/dev-orchestrator/references/intent-routing.md, plugin/dev-orchestrator/references/mission-cross-team.md]
key-decisions:
  - "P57-D-34 et P57-D-35 réalisées (ratifiées, AskUserQuestion session principale, 2026-10-10) ; limite P57-D-20 écrite dans head-governance et mission-cross-team"
requirements-completed: [DLWS-07]
status: complete
completed: 2026-10-10
---

# Phase 57 Plan 10: Protocole du verrou par compartiment dans les prompts et références Summary

**Le manager, ses workers et le head portent `--ws` et un `GSD_SESSION_KEY` distinct : le protocole vit dans `mission-flow.md` §Verrou par compartiment, les prompts y renvoient à instructions constantes (46 / 23 / 9), et la doctrine dit « un manager par compartiment » avec sa limite (allowlists, pas verrou).**

## Transcription (clone jetable partitionné, S = `./.claude/scripts`, `<sujet>`=alpha, `<id>`=m1)
`acquire --ws` · `check-mission-exit.sh --budget-snapshot --ws alpha` (génération lue : `DRIVER.lock.gen.…`) · `dag.sh init --ws` (`"ws": "alpha"`) · `heartbeat` · `mark-progress` · `register` (registre `.git/vf-driver/ws/alpha/DRIVER.lock.children.jsonl`) · `close` · `orphans` · `reclaim` · `release` · `acquire --depot` · `release --depot` : **12 commandes, 12 × exit 0** (`RC_ALL=0`). Refus rejoués : `--budget-snapshot` sans `--ws` exit 4 ; `--ws=zeta` `{"acquired": false, "reason": "unknown-ws", "hint"…}` exit 1 ; ancien `.planning/DRIVER.lock` tenu → `"reason": "legacy-lock-held"` + `hint` `VF_DRIVER_LOCK=… release --owner=old`, exit 1. Sonde : scratchpad `57-10-probe.sh`.

## Mesures
`check-instruction-budget.sh` exit 0 : `vf-dev-manager.md` 250 lignes, `46 | 46` ; `vf-coder.md` 22 (base 23), `vf-reviewer.md` 9 (base 9) ; `check-baseline-arbitrage.sh` 0 (aucune baseline relevée) ; `check-agents.sh --strict` exit 0 ; `test-dev-orchestrator.sh` 279 OK / 0 KO / 0 SKIP (T37, T38 inclus). Relecture de head-governance §2 : le paragraphe « Extension non livrée » (quatre prérequis, déclencheur) n'existe plus, remplacé par « mécanisme livré (Phase 57) ».

## Commits
`08cfd08b` mission-flow + prompt manager (porte aussi les ajouts registre/snapshot de la tâche 2) · `496d2378` workers · `999b45a3` head, routage, étages croisés

## Déviations
None - plan executed exactly as written. Précisions : le plan cite l.29 pour la ligne d'export, elle est à l.30 ; le contrat `legacy-lock-held` est porté par la ligne `reason: held` existante (pas de ligne neuve) ; trailer de co-auteur « Claude Sonnet 5.5 » (modèle réel).

## Problèmes
`check-version-sync.sh` rouge (compte de suites) : attendu jusqu'à 57-15.

## Self-Check: PASSED
Sept fichiers modifiés présents, trois commits, critères d'acceptation des trois tâches rejoués (grep : 1 / 2 / 1 / 1 / 1 / 1 / 4 ; budget, agents, suite exit 0).
