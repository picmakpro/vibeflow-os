---
phase: 57-verrou-de-driver-par-compartiment
plan: 02
subsystem: conductor
tags: [driver-lock, workstream, bash, tdd, legacy-lock]
requires:
  - phase: 57-01
    provides: vf_dl_resolve, vf_dl_common_dir, vf_dl_refuse, SCOPE_JSON
provides:
  - "driver-lock.sh : ancien verrou unique refusé (legacy-lock-held, stale-requires-takeover), repli legacy-fallback, champ legacy_lock"
  - "repli hors git sous .planning/DRIVER.lock.d (location checkout), partage entre worktrees prouvé"
key-files:
  created: []
  modified: [plugin/conductor/scripts/driver-lock.sh, plugin/conductor/scripts/tests/test-driver-lock-ws.sh]
key-decisions:
  - "Le repli legacy-fallback vise tout verbe autre qu'acquire sans --ws ni --depot quand le dépôt est absent (lettre du plan, register/close/orphans compris)"
  - "status porte legacy_lock (true|false) pour toute cible en lab partitionné, pas seulement en repli"
requirements-completed: [DLWS-02, DLWS-03, DLWS-05]
duration: 25min
completed: 2026-10-10
status: complete
---

# Phase 57 Plan 02: Ancien verrou, worktrees, repli hors git Summary

**`driver-lock.sh` refuse toute acquisition tant qu'un ancien `.planning/DRIVER.lock` est tenu en lab partitionné (commande exacte en `hint`, rien repris en silence), se replie hors git sous `.planning/DRIVER.lock.d`, et la suite prouve partage entre worktrees et options inertes en lab plat.**

## Accomplissements
- Cas ajoutés (suite 131 → 219 assertions, environ 5 s) : WS-LEG-1 à 4, WS-LOC, WS-NOGIT, WS-VFL, WS-FLATWS.
- Refus vivant : `{"acquired": false, "reason": "legacy-lock-held", "held_by": "old", "age_seconds": 0, "hint": "VF_DRIVER_LOCK=.planning/DRIVER.lock driver-lock.sh release --owner=old", "scope": "compartiment", "ws": "alpha", "location": "git-common-dir"}`
- Refus périmé : `{"acquired": false, "reason": "stale-requires-takeover", "held_by": "old", "age_seconds": <n>, "hint": "VF_DRIVER_LOCK=.planning/DRIVER.lock driver-lock.sh recover", "scope": …}` ; l'ancien verrou reste en place.
- `vf_dl_legacy_probe` réutilise `lock_present`/`lock_age`/`meta_get` dans un sous-shell ; WS-VFL et WS-FLATWS passaient sans code neuf (la condition d'entrée de 57-01 suffit).

## TDD
- RED 1 `d4877a4d` : 27 FAIL sur WS-LEG. GREEN 1 `bf3d3d6c`. RED 2 `8b460676` : 11 FAIL (WS-NOGIT) ; WS-LOC/VFL/FLATWS déjà verts. GREEN 2 `f1771bc2`. Pas de REFACTOR.

## Déviations
None - plan executed exactly as written. Trailer de co-auteur « Claude Sonnet 5.5 » (modèle réel).

## Problèmes
`check-version-sync.sh` rouge (compte de suites) : attendu jusqu'à 57-15. Hypothèse A4 (worktree d'avant la partition) écrite, non mesurée (T-57-37 accepté).

## Self-Check: PASSED
Suites : `test-driver-lock-ws.sh` 219/0 (aussi sous `/bin/bash`), `test-driver-lock.sh` 243/0, `test-guard-driver-lock.sh` 103/0 ; diff des deux suites existantes vide contre la base ; `bash -n` exit 0 ; `legacy-lock-held` et `legacy-fallback` présents (2 chacun).
