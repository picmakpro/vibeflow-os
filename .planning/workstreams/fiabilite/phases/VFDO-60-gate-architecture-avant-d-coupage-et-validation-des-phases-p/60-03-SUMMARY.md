---
phase: 60-gate-architecture-avant-d-coupage-et-validation-des-phases-p
plan: 03
subsystem: conductor
tags: [marqueur-de-phase, preuve-moteur, qual-01]
requires: [60-01]
provides: [CPV-GSD-*]
key-files:
  modified: [plugin/conductor/scripts/tests/test-check-phase-validation.sh]
status: complete
commits: 2
plan_head_before: 76f9351c096d7e48fdde407f84f8078032066097
plan_head_after: 08dea1ac62476a3bdbc8aad2c6177b3afe2d4c5c
actuals: {tokens: 6500, tasks: 2, commits: 2}
---

# Phase 60 Plan 03: preuve moteur CPV-GSD Summary

Le marqueur `**Validation:**` est prouvé invisible aux lecteurs du moteur GSD, sur fixtures générées, par un comparateur qui a d'abord prouvé qu'il sait rougir.

## Cas CPV-GSD (suite : 46 ok, 0 ko, 0 skip, rc 0 sous bash courant et `/bin/bash` 3.2, 6 s)
- **NEG** (joué avant toute comparaison positive) : témoin positif A = A identique, puis N1 (`### Phase 2 [proposed]:`) et N2 (tag après les deux-points) déclarés DIFFÉRENTS ; sinon `comparateur aveugle`.
- **GET** / **ANALYZE** : `roadmap get-phase 2` (hors ligne `section`) et `roadmap analyze` identiques entre sans marqueur, `proposed`, `validated (dev, 2026-10-29)`. **WS** : idem en lab partitionné `--ws w1` (avec son propre témoin N1).
- **COMPLETE** : `phase complete 2` coche `- [x] Phase 2:` avec et sans marqueur, ROADMAP identiques hors ligne de marqueur, gate 1 sur B et 0 sur A. **RENUM** : `phase insert 1` puis `phase remove 1`, gate 1 sur la phase renumérotée qui portait le marqueur, 0 sur l'autre, `get-phase 1` identique hors `section`.
- Aucun SKIP sur ce poste (node et moteur présents) ; SKIP nommé `CPV-GSD moteur GSD absent` si l'un manque.

## Commandes du moteur jouées (fixtures sous `$TMP/gsd` seulement, `--cwd`)
`roadmap get-phase`, `roadmap analyze`, `phase complete`, `phase insert`, `phase remove`. ROADMAP réel inchangé (cksum avant/après).

## Vérifications
- Mutation hors suite (marqueur retiré des fixtures B) : COMPLETE et RENUM rougissent (marqueur non survécu, gate rc 0 au lieu de 1).
- `check-gate-touche.sh` rc 0 (12/12 marqueurs conformes) ; trailer `Gate-Touche` sur chaque commit.
- `check-version-sync.sh` rouge attendu sur le compte de suites jusqu'à 60-07 (P60-PL-17), non rejoué ici.

## Deviations from Plan
None - plan executed exactly as written. Détail d'outillage : `gsd_same` rend 2 (référence inutilisable) si le moteur échoue ou si la sortie de référence ne porte pas son jeton attendu, pour qu'un « identique » ne puisse jamais venir de deux erreurs identiques.

## Self-Check: PASSED
