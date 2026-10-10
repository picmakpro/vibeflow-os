---
phase: 57-verrou-de-driver-par-compartiment
plan: 13
subsystem: doctrine
tags: [adr-053, driver-lock, doctrine, manuel, release]
requires:
  - phase: 57-11
    provides: "mesures du guard (A/B, 12 mutants, latence)"
key-files:
  modified: [docs/ADR.md, docs/superpowers/specs/2026-09-15-vibeflow-head-design.md, docs/HOOKS-CONTRAT-SORTIE.md, CLAUDE.md, manual/fr/02-concepts/glossaire.md, manual/fr/05-equipe-agents/une-mission-longue.md, manual/fr/06-reference/depannage.md, manual/en/02-concepts/glossary.md, manual/en/05-agent-team/a-long-mission.md, manual/en/06-reference/troubleshooting.md]
key-decisions:
  - "P57-D-36 réalisée (ratifiée, AskUserQuestion session principale, 2026-10-10) ; limites P57-D-20 et P57-D-29 écrites dans l'amendement"
requirements-completed: [DLWS-02, DLWS-07]
status: complete
completed: 2026-10-10
---

# Phase 57 Plan 13: Doctrine de l'invariant amendé Summary

**ADR-053 porte l'amendement `### Amendement du 2026-10-10 — un manager par compartiment, un seul geste de dépôt à la fois` ; la release de CLAUDE.md ne tient le verrou de dépôt que pour le bump (item 1) puis le tag et la release GitHub (items 3-4) ; manuel FR/EN aligné.**

## Registre relu (57-CONTEXT.md, 2026-10-10)
État conforme au plan : P57-D-34, D-36, D-37 ratifiées (arbitrage Samuel, AskUserQuestion session principale, 2026-10-10) ; P57-D-31, D-32, D-33, D-35 sans veto (même canal, même date) ; D-22..30 « Aucun veto ». Aucun écart. Mesures recopiées de 57-04 (24 × 5 tours, 0 hors contrat ; A/B IDENTIQUE ; 9/9), 57-07 (5/5), 57-09 (7/7), 57-11 (A/B 365 passages par régime ; 12/12 ; 4,7 / 72,6 / 39,8 ms).

## Vérifications (HEAD)
Amendement présent une fois entre ADR-053 et ADR-054 ; `awk` des gestes de release : `A1. R1. A3. R4. ` ; `check-machine-paths.sh` 0 (1908 fichiers) ; `check-ajout-retrait.sh --strict` exit 0 ; `test-hook-exit-contract.sh` 40/0 ; `test-hook-exit-parc.sh` 42/0 ; `test-check-affirmation-non-mesuree.sh` 20/0 (le gate consultatif ne signale que CLAUDE.md:94 et docs/ADR.md:2878, lignes non touchées) ; `check-gate-touche.sh` DECLARE ; `check-baseline-arbitrage.sh` CONFORME ; `check-manual.sh` exit 0 (C1-C6).

## Déviations
None - plan executed exactly as written. Précision : `manual/fr/06-reference/depannage.md` passe à 202 lignes (avertissement non bloquant « hors de la fourchette 100-200 », limite ferme à 300). Aucun Gate-Touche requis (docs seules).

## Commits
`90b5b828` ADR-053 + spec head + entrée n°27 + CLAUDE.md · `9ff9d76d` manuel FR · `8f5ccc28` manuel EN

## Self-Check: PASSED
