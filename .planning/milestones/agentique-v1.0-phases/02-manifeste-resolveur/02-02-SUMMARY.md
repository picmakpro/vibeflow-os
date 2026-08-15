---
phase: 02-manifeste-resolveur
plan: 02
subsystem: dependency-resolver
tags: [bash, jq, tdd, dependency-resolution, module-manifest]
requires:
  - "Plan 01 : module.json présents à <repo-root>/<module>/module.json (8 modules)"
provides:
  - "_internal/resolve-deps.sh : fermeture transitive triée + dédupliquée des requires"
  - "_internal/tests/test-resolve-deps.sh : test autonome (5 asserts)"
affects:
  - "Phase 3 (engine scope-aware) et Phase 4 (/vibeflow-install) consommeront le résolveur"
tech-stack:
  added: []
  patterns:
    - "BFS sur file de modules + set « vu » (anti-cycle, dédup)"
    - "jq -r '.requires[]?' pour lire les deps"
    - "VF_MODULES_ROOT surchargeable pour fixtures de test"
    - "Pattern test repo : helpers ok/ko, asserts numérotés, exit 0/1"
key-files:
  created:
    - _internal/resolve-deps.sh
    - _internal/tests/test-resolve-deps.sh
  modified: []
decisions:
  - "Contrat d'entrée : argv (resolve-deps.sh <module> [<module> ...]), pas stdin"
  - "Racine modules : ${VF_MODULES_ROOT:-parent du dossier du script}"
  - "Marquage « vu » AVANT enfilage des deps → terminaison garantie même en cycle"
metrics:
  duration: ~5min
  completed: 2026-06-04
  tasks: 2
  files: 2
  commits: 3
---

# Phase 02 Plan 02 : Résolveur de dépendances transitives Summary

Résolveur bash `_internal/resolve-deps.sh` qui calcule la fermeture transitive des `requires` des `module.json` (BFS + dédup + tri via `sort -u`), avec sécurité anti-cycle et exit non-zéro sur module inconnu, prouvé par un test autonome à 5 asserts (TDD RED→GREEN).

## What Was Built

- **`_internal/resolve-deps.sh`** (47 lignes) — Lit `${VF_MODULES_ROOT:-parent}/<mod>/module.json`, suit récursivement `requires` via `jq -r '.requires[]?'`, parcours en largeur (file `queue`) avec set `seen` marqué avant enfilage des deps (anti-cycle + dédup), émet la fermeture triée (`sort -u`) un module par ligne. `err`/exit non-zéro si un manifeste est absent.
- **`_internal/tests/test-resolve-deps.sh`** (44 lignes) — Test autonome pointant sur les vrais `module.json` du repo via `VF_MODULES_ROOT=$REPO_ROOT`. 5 asserts numérotés : (1) `validator` → closure triée 3 lignes, (2) `consolidator` → lui-même seul, (3) `validator consolidator` → pas de doublon, (4) module inconnu → exit non-zéro, (5) sortie triée alphabétiquement.

## Verification Results

| Étape | Commande | Résultat |
|-------|----------|----------|
| RED | `bash _internal/tests/test-resolve-deps.sh` (résolveur absent) | exit 1 — 3 asserts cœur KO (attendu) |
| GREEN | `bash _internal/tests/test-resolve-deps.sh` | exit 0 — 5 OK / 0 KO |
| Task 1 verify | `bash _internal/tests/test-resolve-deps.sh` | exit 0 |
| Task 2 verify | closure `validator` == {consolidator, infrastructure-audit, validator} + `reference` == reference | exit 0 — `CLOSURE OK` |
| Robustesse (hors plan) | cycle A↔B sur fixture temp | termine, sortie `a b`, exit 0 (T-02-05 confirmé) |

## TDD Gate Compliance

- RED gate : commit `test(02-02): add failing test for resolve-deps` (f25233f) — test échoue avant implémentation.
- GREEN gate : commit `feat(02-02): implement transitive dependency resolver` (f0ffe75) — test passe après implémentation.
- REFACTOR gate : non nécessaire (implémentation propre dès le GREEN).

## Threat Mitigations Applied

- **T-02-04 (input module inconnu)** : `[ -f "$manifest" ] || err ...` → message stderr + exit non-zéro (Test 4).
- **T-02-05 (cycle de requires)** : `seen` marqué avant d'enfiler les deps → terminaison garantie ; vérifié manuellement sur fixture A↔B.
- **T-02-06 (module.json malformé)** : accepté (manifestes validés en Plan 01, entrée de confiance interne).

## Deviations from Plan

None - plan exécuté exactement comme écrit. Aucune correction du résolveur nécessaire en Task 2 (closure correcte du premier coup).

## Known Stubs

None.

## Self-Check: PASSED

- FOUND: _internal/resolve-deps.sh
- FOUND: _internal/tests/test-resolve-deps.sh
- FOUND commit: f25233f (test RED)
- FOUND commit: f0ffe75 (feat GREEN)
