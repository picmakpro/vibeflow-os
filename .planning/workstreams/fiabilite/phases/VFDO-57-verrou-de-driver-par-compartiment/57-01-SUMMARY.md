---
phase: 57-verrou-de-driver-par-compartiment
plan: 01
subsystem: conductor
tags: [driver-lock, workstream, bash, tdd]
requires:
  - phase: 41.1
    provides: workstream-policy.sh (vf_ws_name_valid, vf_ws_dir_resolve, vf_ws_enumerate)
provides:
  - "driver-lock.sh : options --ws= et --depot, résolution paresseuse d'un verrou NOMMÉ, refus nommés"
  - "contrat JSON partitionné (scope, ws, location, scope_reason) consommé par 57-02 à 57-07"
  - "suite neuve test-driver-lock-ws.sh (131 assertions) et ligne de recensement a1"
affects: [57-02, 57-03, 57-04, 57-05, 57-06, 57-07]
actuals:
  tokens: 5118
  tasks: 2
  commits: 4
plan_head_before: a0b8d43db172e0548b253e39218cce995ffd3842
plan_head_after: 15b1ff6798e4e4e33b061e9eee39812a8b5f75d6
tech-stack:
  added: []
  patterns: ["un seul point d'insertion vf_dl_resolve avant LOCK_PARENT", "détection paresseuse : lab plat = zéro source, zéro git de plus"]
key-files:
  created: [plugin/conductor/scripts/tests/test-driver-lock-ws.sh]
  modified: [plugin/conductor/scripts/driver-lock.sh, plugin/conductor/references/workstream-planning-consumers.md]
key-decisions:
  - "Verbes autres qu'acquire/status/release : le verrou est résolu mais le suffixe JSON n'y est pas encore posé (57-03)"
  - "Hors dépôt git en lab partitionné : refus no-git-common-dir provisoire, remplacé par le repli de 57-02"
requirements-completed: [DLWS-01, DLWS-02, DLWS-03, DLWS-04]
duration: 15min
completed: 2026-10-10
status: complete
---

# Phase 57 Plan 01: Verrou de driver par compartiment Summary

**`driver-lock.sh` verrouille un compartiment (`--ws`) ou le dépôt (`--depot`, ou sans `--ws`) sous `<git-common-dir>/vf-driver/`, sur la mécanique d'acquisition inchangée, avec quatre refus nommés et rejouables ; lab plat intact.**

## Accomplissements
- Résolution paresseuse `vf_dl_resolve` : ni `source` ni `git` en lab plat ou sous `VF_DRIVER_LOCK` (les deux suites existantes, 243 et 103 assertions, passent sans modification).
- Le compartiment ne vient que de `--ws` : `GSD_WORKSTREAM`, `VF_WORKSTREAM` et `active-workstream` posés ne déplacent rien (WS-ENV).
- Refus nommés avec `hint` : `ws-invalid`, `unknown-ws`, `partition-unreadable` (lien, fichier, dossier vide ; `acquire` ET `status`), `policy-missing`.
- Suite neuve : préflight anti-pollution du vrai `.git`, 1er ET dernier compartiment exercés, dépôt et compartiment acquis dans les deux sens. Durée : environ 3 s.

JSON livré (contrat) : `acquire --ws=alpha` → `{"acquired": true, "owner", "step", "generation", "session_ids", "lease_seconds", "orphans_count", "orphans", "scope": "compartiment", "ws": "alpha", "location": "git-common-dir"}` ; `status --ws=alpha` → les champs historiques puis `"scope": "compartiment", "ws": "alpha", "location": "git-common-dir"` ; sans `--ws` : `"scope": "depot", "ws": "", "location": "git-common-dir", "scope_reason": "ws-absent"` (pas de `scope_reason` avec `--depot`).

## TDD
- RED 1 `aae01fc9` : 16 FAIL sur WS-TRACE-1 à 3 (`Unknown arg: --ws=alpha`), cible exécutée, assertion prévue. Format bash non géré par le classifieur de gsd (hors `workflow.tdd_mode`) : évaluation sémantique manuelle.
- GREEN 1 `220bab27`. RED 2 `d6db3c0c` : 8 FAIL (verrou de dépôt) ; les cas de refus et FIRST/LAST passaient déjà, car la validation était posée par le tracer. GREEN 2 `15b1ff67`. Pas de REFACTOR.

## Commits
`aae01fc9` test · `220bab27` feat · `d6db3c0c` test · `15b1ff67` feat

## Déviations
None - plan executed exactly as written. Deux précisions : refus `no-git-common-dir` provisoire (57-02 le remplace) ; trailer de co-auteur « Claude Sonnet 5.5 » (modèle réel) au lieu de « Opus 5.5 » du mandat.

## Problèmes
`check-version-sync.sh` rouge (compte de suites 98 → 99) : attendu jusqu'au plan 57-15.

## Self-Check: PASSED
Fichiers et quatre commits présents ; `test-driver-lock-ws.sh`, `test-driver-lock.sh`, `test-guard-driver-lock.sh` exit 0 (la suite neuve aussi sous `/bin/bash` 3.2) ; diff des deux suites existantes vide contre la base ; lint de recensement exit 0 (24 consommateurs).
