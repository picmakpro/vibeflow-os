---
phase: 57-verrou-de-driver-par-compartiment
plan: 07
subsystem: dev-orchestrator
tags: [gate-sortie, driver-lock, workstream, bash, tdd, mutation]
requires:
  - phase: 57-03
    provides: "driver-lock.sh status --ws / --depot"
provides:
  - "check-mission-exit.sh --ws <sujet> : E1, identité d'E7 (cur_lock_gen), --budget-snapshot et surcharge d'E4 par compartiment"
  - "suite neuve test-check-mission-exit-ws.sh (54 assertions, 5 mutants)"
key-files:
  created: [plugin/dev-orchestrator/scripts/tests/test-check-mission-exit-ws.sh]
  modified: [plugin/dev-orchestrator/scripts/check-mission-exit.sh]
key-decisions:
  - "P57-D-35 réalisée : partitionné sans --ws = E1 indéterminé et snapshot exit 4 ; verrou de dépôt tenu dit sur stderr, jamais un manque"
requirements-completed: [DLWS-07, DLWS-08]
status: complete
completed: 2026-10-10
---

# Phase 57 Plan 07: gate de sortie par compartiment Summary

**Le gate de sortie du head juge le verrou du compartiment désigné par `--ws` (E1, identité d'E7, surcharge d'E4) ; un lab partitionné sans `--ws` est INDÉTERMINÉ (E1) ou exit 4 (`--budget-snapshot`), jamais un vert ; lab plat inchangé.**

## Mutants — bilan verbatim : `== mutants : 5/5 tués ==` (suite complète 43 s, borne 600 s)
- EW-M-a export de `VF_DRIVER_LOCK` rétabli : bascule {EW-CHILD-1 EW-Q-INDET-2 EW-Q-INDET-3 EW-Q-MANQUE-1 EW-TRACE-1 EW-TRACE-3}
- EW-M-b absence de `--ws` = sain : {EW-NOWS-1 EW-Q-INDET-1} (EW-NOWS-2, rc 4, tient sans E1 : E4/E5/E6 indéterminés)
- EW-M-c `cur_lock_gen` lit le verrou du checkout : {EW-GEN-2 EW-GEN-3 EW-GEN-5}, obtenu `-` au lieu de `DRIVER.lock.gen.…`
- EW-M-d surcharge d'E4 retirée : {EW-E4-1 EW-E4-2}, E4 juge `omega`
- EW-M-e snapshot permis sans `--ws` : {EW-SNAP-1 EW-SNAP-2 EW-SNAP-4}, exit 0 au lieu de 4
Disposition miroir : `<mut>/dev-orchestrator/scripts/` (copie mutée), `<mut>/planning-core/scripts/workstream-policy.sh`, `<mut>/conductor/scripts/{check-method-budget,check-divergence}.sh` ; témoin EW-LAYOUT vert avant tout mutant.

## TDD
RED T1 `6479d9cc` (6 KO, `--ws` argument inconnu) → GREEN T1 `abee938c` ; RED T2 `1cc6dd8b` (12 KO mesurés contre le gate de T1) → GREEN T2 `ba1eac61` → mutants `2d5e08e7`.

## Déviations
None - plan executed exactly as written. Précisions : EW-CHILD asserte « 1 agent(s) consigné(s) encore running » (le libellé existant de l'issue #82 ne contient pas le littéral `children_running` quand le verrou est relâché) ; EW-TRACE-3 asserte sur la seule ligne `status --ws=alpha` du faux script (la lecture du dépôt qui suit vide aussi la variable : première version vacue, trouvée par EW-M-a) ; trailer de co-auteur « Claude Sonnet 5.5 » (modèle réel).

## Problèmes
`check-version-sync.sh` rouge (compte de suites) : attendu jusqu'à 57-15. Les appels documentés `--budget-snapshot` sans `--ws` (`mission-flow.md`, `vf-dev-manager.md`, `README.md`) sont réécrits par 57-10 : d'ici là un manager sur ce dépôt partitionné doit passer `--ws fiabilite`.

## Self-Check: PASSED
Suite neuve 54/0 ; `test-check-mission-exit.sh` 135/0 (diff vide contre la base) ; `test-dev-orchestrator.sh` 279/0 ; `--ws` seul exit 64 ; `check-planning-consumers-registered.sh` exit 0 sans ligne neuve ; `check-gate-touche.sh` exit 0 (19/19) ; marqueurs `# >>> E1`/`# <<< E1` 1/1.
