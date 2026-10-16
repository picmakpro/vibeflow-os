---
phase: 57-verrou-de-driver-par-compartiment
plan: 06
subsystem: conductor
tags: [watchdog, dag, driver-lock, workstream, bash, tdd, mutation]
requires:
  - phase: 57-03
    provides: "driver-lock.sh status --all, status --ws, mark-progress --ws"
provides:
  - "check-guard-health.sh : check_driver_stall lit status --all, une ligne par famille (abandon > stall, suffixe +N)"
  - "dag.sh : init --ws=<sujet>, champ ws du DAG, record_progress ciblé sur le verrou du compartiment"
  - "suite neuve test-driver-lock-consumers-ws.sh (18 cas, 4 mutants)"
key-files:
  created: [plugin/conductor/scripts/tests/test-driver-lock-consumers-ws.sh]
  modified: [plugin/conductor/scripts/check-guard-health.sh, plugin/conductor/scripts/dag.sh]
key-decisions:
  - "Aucun des deux scripts ne détecte la partition ni ne porte le littéral du dossier des compartiments : le lint des consommateurs reste vert sans ligne neuve (P57-D-15, P57-D-23)"
requirements-completed: [DLWS-07, DLWS-08]
status: complete
completed: 2026-10-10
---

# Phase 57 Plan 06: Consommateurs de progrès par compartiment Summary

**Le watchdog de la Phase 33 voit un stall ou un abandon par compartiment (`ws=<sujet>`, une seule ligne, abandon prioritaire, « +N autre(s) »), et `dag.sh mark` avance le `progress_epoch` du verrou du compartiment lié au DAG ; lab plat et DAG sans `ws` inchangés.**

## Preuves (suite neuve : 18 cas, 13 s, aussi sous /bin/bash 3.2)
CW-TRACE-1/2/3 · CW-HEALTH-MULTI · CW-Q-SIGNAL/SAIN/BRUYANT/SILENCE · CW-DAG-WS/KEEP/NOWS/OPT, verrous posés par le vrai `driver-lock.sh` sur clones jetables (préflight anti-pollution). Antidatage du meta par le lien lu sur `status --ws` avant acquisition.

## Mutants — bilan verbatim : `== mutants : 4/4 tués ==` (9 s, deux copies témoins non mutées à zéro KO)
- CW-M-a `status --all` -> `status` : bascule {CW-HEALTH-MULTI CW-Q-SIGNAL CW-TRACE-1 CW-TRACE-3}
- CW-M-b priorité inversée (`rank > best_rank` -> `<`) : bascule {CW-HEALTH-MULTI}, obtenu un `stall ws=alpha` au lieu de l'abandon
- CW-M-f `--ws` non passé à `mark-progress` : bascule {CW-DAG-WS} (`progress_epoch` 1791664020 -> 1791664020)
- CW-M-g `ws` non écrit par `init` : bascule {CW-DAG-KEEP CW-DAG-WS}
Ancre unique, mutant opposable (`cmp -s`), `bash -n`, ensemble comparé exactement ; trace « rouge CW-… : attendu … obtenu … » dans la sortie.

## Lab plat
Aucune différence : `test-check-guard-health.sh` 78/0 et `test-dag.sh` 161/0 sans modification (diff vide contre la base), `init` sans `--ws` octet pour octet (`cmp`).

## Commits
`fd436ea2` RED T1 · `e5c186df` GREEN T1 · `779e0953` RED T2 · `ce374ca7` dag.sh · `84c64b90` mutants

## Déviations
None - plan executed exactly as written. Précisions : la tâche 2 est livrée en trois commits (cas rouges, dag.sh, mutants) ; un commentaire du programme Python embarqué dans `$(…)` ne porte aucune apostrophe (bash 3.2) ; trailer de co-auteur « Claude Sonnet 5.5 » (modèle réel).

## Problèmes
`check-version-sync.sh` rouge (compte de suites) : attendu jusqu'à 57-15.

## Self-Check: PASSED
Suite neuve 18/0 ; `test-check-guard-health.sh`, `test-dag.sh` exit 0 ; `check-planning-consumers-registered.sh` exit 0 (24 consommateurs, aucune ligne neuve) ; `check-gate-touche.sh` exit 0 (19 marqueurs conformes) ; 0 occurrence du dossier des compartiments dans les deux scripts.
