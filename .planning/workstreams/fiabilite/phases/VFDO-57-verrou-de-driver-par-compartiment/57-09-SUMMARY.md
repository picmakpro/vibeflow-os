---
phase: 57-verrou-de-driver-par-compartiment
plan: 09
subsystem: conductor
tags: [branch-claim, driver-lock, workstream, bash, tdd, mutation]
requires:
  - phase: 57-06
    provides: "suite des consommateurs test-driver-lock-consumers-ws.sh (4 mutants), cadre et constructeurs"
provides:
  - "check-branch-claim.sh : claim_check_lock, examen des verrous du clone, agrégation signal > indéterminé > sain, mode verrou unique"
  - "suite des consommateurs complétée : 30 assertions, 7 mutants"
key-files:
  modified: [plugin/conductor/scripts/check-branch-claim.sh, plugin/conductor/scripts/tests/test-driver-lock-consumers-ws.sh]
key-decisions:
  - "Aucun littéral du dossier des compartiments ni détection de partition : le script lit les dossiers de verrous du clone (P57-D-15) ; lint des consommateurs vert sans ligne neuve"
  - "--lock ou VF_DRIVER_LOCK non vide : seul ce verrou est examiné (P57-D-22) ; sans verrou du clone, chemin d'avant octet pour octet (P57-D-03)"
requirements-completed: [DLWS-07, DLWS-08]
status: complete
completed: 2026-10-10
---

# Phase 57 Plan 09: Claim de branche sur les verrous du clone Summary

**Une branche revendiquée par un verrou de compartiment depuis un autre worktree rend le signal `[branch-claim] … compartiment alpha` (exit 0), le même worktree est SAIN (3), un meta illisible INDÉTERMINÉ (4), un signal l'emportant sur un indéterminé ; lab plat inchangé.**

## Preuves (suite neuve : 30 OK · 0 KO, 21 s, aussi sous /bin/bash 3.2)
CW-CLAIM-WT · SAME · NONE · META · LOCKOPT et CW-Q-CLAIM-SIGNAL/SAIN/INDET, verrous posés par le vrai `driver-lock.sh` sur clones jetables avec worktree lié.

## Mutants — bilan verbatim : `== mutants : 7/7 tués ==` (14 s, trois copies témoins non mutées à zéro KO)
- CW-M-c examen des verrous du clone retiré : bascule {CW-CLAIM-META CW-CLAIM-SAME CW-CLAIM-WT CW-Q-CLAIM-INDET CW-Q-CLAIM-SIGNAL} (rouge CW-CLAIM-WT : attendu `[branch-claim]` obtenu vide)
- CW-M-d comparaison d'arbre retirée : bascule {CW-CLAIM-SAME CW-Q-CLAIM-SAIN} (attendu exit 3 obtenu exit 0)
- CW-M-e indéterminé agrégé comme sain : bascule {CW-CLAIM-META CW-Q-CLAIM-INDET} (attendu exit 4 obtenu exit 3)
Quatre mutants de 57-06 (a, b, f, g) inchangés et toujours tués.

## Lab plat
Aucune différence : `test-check-branch-claim.sh` 18/0, `test-check-guard-health.sh` et `test-dag.sh` rc 0, trois suites au diff vide contre la base ; lint des consommateurs 0 ; G-2 0.

## Déviations
1. L'ensemble attendu de CW-M-c, annoncé {SAME, WT, Q-SAIN, Q-SIGNAL} à la rédaction, est corrigé en {META, SAME, WT, Q-INDET, Q-SIGNAL} après exécution : sans examen du clone, META et INDET rendent 3 au lieu de 4, et Q-SAIN ne vérifie que le code (inchangé). Erreur de prédiction, pas de défaut du script.

## Commits
`6f2b94fd` RED tâche 1 · `d0706802` GREEN tâche 1 · `0a7e4aeb` tâche 2 (cas, mutants, bilan 7/7)

## Self-Check: PASSED
