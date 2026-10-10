---
phase: 57-verrou-de-driver-par-compartiment
plan: 03
subsystem: conductor
tags: [driver-lock, workstream, bash, tdd, status-all]
requires:
  - phase: 57-02
    provides: legacy_lock, repli hors git, LEGACY_DIR
provides:
  - "driver-lock.sh : status --all (vf_dl_status_all), suffixe de portée sur tous les verbes, registre frère du verrou résolu"
  - "contrat JSON de status --all consommé par 57-06 (check-guard-health) et 57-07 (check-mission-exit)"
key-files:
  created: []
  modified: [plugin/conductor/scripts/driver-lock.sh, plugin/conductor/scripts/tests/test-driver-lock-ws.sh]
key-decisions:
  - "ttl porté par chaque entrée PRÉSENTE (ligne de json_status inchangée) ; une entrée absente garde la forme historique sans ttl"
  - "LOCK_ROOT devient globale (lue par vf_dl_status_all) ; --all avec --ws/--depot refusé seulement en lab partitionné"
requirements-completed: [DLWS-01, DLWS-07]
duration: 35min
completed: 2026-10-10
status: complete
---

# Phase 57 Plan 03: status --all et verbes par compartiment Summary

**`driver-lock.sh status --all` rend en une ligne l'état de tous les verrous d'un lab partitionné (dépôt, ancien verrou, compartiments, verrous sans dossier), et tous les verbes portent `--ws`, le suffixe `scope`/`ws`/`location` et un registre frère du verrou ; lab plat inchangé.**

## Accomplissements
- Partitionné : `{"present": true, "scope": "lab", "location": "git-common-dir", "legacy_lock": false, "locks": [{"present": false, "lock": "<…>/repo/DRIVER.lock", "children_running": 0, "scope": "depot", "ws": "", "location": "git-common-dir"}, {"present": true, "owner": "m1", …, "ttl": 1800, …, "children_running": 0, "scope": "compartiment", "ws": "alpha", "location": "git-common-dir"}], "children_running": 0}` (mesuré sur fixture).
- Verrou unique (lab plat ou `VF_DRIVER_LOCK`) : exactement la sortie de `status` (`{"present": false, "lock": ".planning/DRIVER.lock", "children_running": 0}`), prouvé par `cmp` normalisé.
- `--all` avec un autre verbe : usage sur stderr, exit 1 ; `status --all --ws=…|--depot` : `ws-invalid` (clé `error`) ; noms forgés écartés et comptés sur stderr.
- Cas ajoutés (suite 219 → 469 assertions, ≈ 16 s) : WS-ALL-1 à 4, WS-VERBS-1 à 5. Aucune ligne de la mécanique d'acquisition touchée.

## TDD
RED 1 `fe081947` (30 FAIL) → GREEN 1 `32438005` ; RED 2 `385b2f91` (38 FAIL, suffixe absent) → GREEN 2 `91f4b3bb`. Pas de REFACTOR. Format bash non géré par le classifieur gsd : évaluation sémantique manuelle.

## Déviations
None - plan executed exactly as written. Précision : « `ttl` par entrée » lu comme « par entrée présente » (la branche absente de `json_status` n'a jamais porté `ttl`, la changer modifierait le lab plat). Trailer de co-auteur « Claude Sonnet 5.5 » (modèle réel).

## Problèmes
`check-version-sync.sh` rouge (compte de suites) : attendu jusqu'à 57-15.

## Self-Check: PASSED
`test-driver-lock-ws.sh` 469/0 (aussi `/bin/bash`), `test-driver-lock.sh` 243/0, `test-guard-driver-lock.sh` 103/0 ; `bash -n` exit 0 ; `vf_dl_status_all` ×2 ; diff vide des deux suites existantes contre la base.
