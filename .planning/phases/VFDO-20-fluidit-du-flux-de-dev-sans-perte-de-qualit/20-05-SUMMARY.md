---
phase: VFDO-20-fluidit-du-flux-de-dev-sans-perte-de-qualite
plan: 05
subsystem: infra
tags: [bash, gate-advisory, mission-kernel, dag, git]

requires:
  - phase: VFDO-20 (plan 20-02)
    provides: "dag.sh status --file=... : compteurs + frontière + périmètres GELÉS (JSON), source vivante de la table des fichiers gelés"
provides:
  - "plugin/conductor/scripts/check-mission-invariants.sh — gate advisory qui constate qu'un glob de zone de risque ne matche plus aucun fichier suivi"
  - ".planning/MISSION-INVARIANTS.md — fichier d'invariants réduit au falsifiable (2 sections gatées + 1 étiquetée non gatée)"
affects: [VFDO-20-plan-06, VFDO-20-plan-07]

tech-stack:
  added: []
  patterns:
    - "Gate advisory répliqué en STRUCTURE (pas en heuristique) depuis check-doc-drift.sh : lecture seule, git_safe() unique, exits 0/3/64, distinction FAIT vs JUGEMENT"
    - "Section '## ' comme frontière de parsing : le script s'arrête à la 2e entête, les sections suivantes du fichier d'invariants ne sont jamais lues"

key-files:
  created:
    - plugin/conductor/scripts/check-mission-invariants.sh
    - plugin/conductor/scripts/tests/test-check-mission-invariants.sh
    - .planning/MISSION-INVARIANTS.md
  modified: []

key-decisions:
  - "D-16 tranchée par Samuel (checkpoint humain, hors de ce plan) : option-a — la 3e section (contrainte d'outillage XcodeBuildMCP) ENTRE dans le fichier, étiquetée « non gaté — à revérifier manuellement à chaque mission » dans son titre ET en première ligne de corps, retirable seule sans casser le gate ni les 2 premières sections."
  - "Emplacement du gate : plugin/conductor/scripts/ (module obligatoire, à côté du kernel de mission dag.sh/driver-lock.sh) — tranché par le plan lui-même, appliqué tel quel."

requirements-completed: [SC5]

coverage:
  - id: D1
    description: "check-mission-invariants.sh détecte une zone morte (glob sans correspondance dans l'index git) et l'ignore si vivante, sans jamais juger ni écrire"
    requirement: "SC5"
    verification:
      - kind: unit
        ref: "plugin/conductor/scripts/tests/test-check-mission-invariants.sh (15 cas, 0 KO)"
        status: pass
      - kind: other
        ref: "mutation manuelle du test de compte nul (COUNT -eq 0 → forcé faux puis forcé vrai) : 2 KO puis 3 KO, restauration → 0 KO — hors suite committée, preuve consignée au rapport de mission"
        status: pass
    human_judgment: false
  - id: D2
    description: ".planning/MISSION-INVARIANTS.md — §1 zones de risque en globs tous vivants à la livraison, §2 convention de lecture dynamique (aucune liste de fichiers), §3 contrainte d'outillage étiquetée non gatée et retirable seule"
    requirement: "SC5"
    verification:
      - kind: other
        ref: "bash plugin/conductor/scripts/check-mission-invariants.sh (défaut) → rc=3 ; git ls-files -- '<glob>' glob par glob → tous > 0 ; retirabilité prouvée par copie sans §3, même rc=3"
        status: pass
    human_judgment: false
  - id: D3
    description: "Portabilité Linux (job CI tests, ubuntu-latest)"
    verification: []
    human_judgment: true
    rationale: "docker indisponible localement (démon éteint) — preuve Linux différée au job CI au push, non exécutable dans cette session"

duration: ~35min
completed: 2026-07-29
status: complete
---

# Phase VFDO-20 Plan 05: Fichier d'invariants de mission réduit au falsifiable Summary

**Gate advisory `check-mission-invariants.sh` (patron `check-doc-drift.sh`) qui constate une zone de risque morte par glob, plus `.planning/MISSION-INVARIANTS.md` réduit à 2 sections gatées (zones de risque en globs, convention de lecture dynamique de la table des fichiers gelés) et 1 section étiquetée non gatée (D-16, option-a tranchée par Samuel).**

## Performance

- **Tasks:** 2 sur 3 (Task 1 = checkpoint de décision D-16, déjà tranché par Samuel en amont de l'exécution — non rejoué, appliqué tel que reçu)
- **Files created:** 3

## Accomplishments
- Gate advisory en lecture seule qui confronte chaque glob de la 1re section de `MISSION-INVARIANTS.md` à l'index git (`git ls-files --`) et signale, sans jamais juger ni écrire, tout glob qui ne matche plus aucun fichier suivi — contrat 0 (signal)/3 (rien à signaler)/64 (usage invalide).
- Suite dédiée à 15 cas (les 3 codes de sortie, absence de jugement, durcissement git, lecture seule par empreinte, 2e section jamais lue, `--help`/`--hook`).
- `.planning/MISSION-INVARIANTS.md` créé : zones de risque réelles de ce dépôt (gates partagés, fragments de hooks, kernel de mission, agents managers), table des fichiers gelés dérivée à la demande via `dag.sh status --file=...` (jamais recopiée), et la 3e section (contrainte XcodeBuildMCP) explicitement étiquetée non gatée.
- Discriminance du gate prouvée par mutation manuelle du test de compte nul (2 puis 3 échecs induits, restauration à 0).
- Revue `vf-reviewer` : **PASS**, aucun correctif bloquant.

## Task Commits

Task 1 (checkpoint:decision D-16) n'a produit aucun commit — décision déjà tranchée par Samuel avant l'exécution (option-a), appliquée directement en Task 3.

1. **Task 2: le gate de zone morte** — `de5edbd` (feat) — script + suite dans le même commit (précédent établi par `check-doc-drift.sh`/`test-check-doc-drift.sh`, commit unique).
2. **Task 3: `.planning/MISSION-INVARIANTS.md`** — `45abc16` (docs).

## Files Created/Modified
- `plugin/conductor/scripts/check-mission-invariants.sh` — gate advisory de constat, lecture seule
- `plugin/conductor/scripts/tests/test-check-mission-invariants.sh` — suite dédiée, 15 cas
- `.planning/MISSION-INVARIANTS.md` — fichier d'invariants réduit au falsifiable

## Decisions Made
- D-16 : conservation de la 3e section (option-a), tranchée par Samuel — cf. `key-decisions` en frontmatter. Aucune alternative (option-b/option-c) explorée puisque la décision était déjà reçue.
- Exécution en main context (pas de dispatch `gsd-executor`) : le plan porte un checkpoint `type="checkpoint:decision"` bloquant déjà résolu en amont — dispatcher un exécuteur générique aurait rouvert une décision déjà tranchée et risqué de toucher STATE.md/ROADMAP.md/REQUIREMENTS.md hors du périmètre d'écriture strict fixé pour cette mission (3 fichiers nouveaux + ce SUMMARY, rien d'autre).

## Deviations from Plan

None - plan exécuté exactement comme écrit (Task 1 exclue du rejeu car déjà tranchée par le donneur d'ordre, conformément à la consigne reçue).

## Issues Encountered
None.

## User Setup Required
None - aucune configuration de service externe requise.

## Next Phase Readiness
- `.planning/MISSION-INVARIANTS.md` existe et est parsable par le gate (rc=3, aucune zone morte à la livraison) : le plan 20-06 peut brancher sa lecture dans les sources de connaissance de `vf-dev-manager`.
- **Reste-à-faire connu, volontairement non traité ici** : le compteur de suites des 2 README racine (42 → 43) et la mise à jour `STATE.md`/`ROADMAP.md` — délégués respectivement à 20-07 (release) et au geste de synthèse du manager, hors du périmètre d'écriture strict de ce plan.
- Portabilité Linux non exécutée localement (docker indisponible, démon éteint) — vérification différée au job CI `tests` (ubuntu-latest) au prochain push.

---
*Phase: VFDO-20-fluidit-du-flux-de-dev-sans-perte-de-qualit*
*Completed: 2026-07-29*
