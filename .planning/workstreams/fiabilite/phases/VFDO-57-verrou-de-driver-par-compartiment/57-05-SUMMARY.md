---
phase: 57-verrou-de-driver-par-compartiment
plan: 05
subsystem: conductor
tags: [guard, driver-lock, workstream, fail-closed, hooks]
requires:
  - phase: 57-03
    provides: driver-lock.sh compartiment-aware (emplacements vf-driver/{ws/<sujet>,repo}, repli DRIVER.lock.d, ancien verrou)
provides:
  - "guard-driver-lock.sh jugeant les Write/Edit par compartiment en lab partitionné, fail-closed"
  - "suite neuve test-guard-driver-lock-ws.sh (71 assertions)"
key-files:
  created: [plugin/conductor/scripts/tests/test-guard-driver-lock-ws.sh]
  modified: [plugin/conductor/scripts/guard-driver-lock.sh, plugin/conductor/references/workstream-planning-consumers.md]
key-decisions:
  - "Lab plat ou VF_DRIVER_LOCK posé : ni crochet, ni sonde, ni appel (P57-D-03, P57-D-22)"
requirements-completed: [DLWS-03, DLWS-05, DLWS-06, DLWS-08]
status: complete
completed: 2026-10-10
---

# Phase 57 Plan 05: Guard par compartiment, fail-closed Summary

**Le guard refuse une écriture sous un compartiment tenu par une autre session, laisse le voisin libre, et rend un refus JSON (jamais une ouverture) sur toute exception du chemin partitionné ; le lab plat est inchangé.**

## Cas ajoutés (71 assertions, 4-5 s, aussi sous /bin/bash 3.2)
GW-TRACE-1..4 · GW-W-LEG · GW-W-CASE · GW-W-UNMAP · GW-LOC-1/2 (worktree dans les deux sens, PATH sans git) · GW-MARK-W · GW-Q-PASS/DENY/UNPARSE/UNPARSE-OBJ/EMPTY/NOPY (code 17 + marqueur) · GW-CRASH · GW-CRASH-PRE (a sonde dispatch, b octet NUL en C6, c lab plat : silence conservé).
Verrous posés par le vrai `driver-lock.sh` sur clones jetables avec préflight anti-pollution.

## Forme et emplacement
- Refus d'erreur interne : `hookSpecificOutput.permissionDecision = "deny"`, motif « erreur interne du guard, fail-closed », JSON valide unique, rien sur stderr, code du guard 0 (le repli bash ramène le 1 de python).
- `sys.excepthook = fail_closed_hook` posé juste après `PARTITIONED = partition_switch(payload)` (guard l.738-744), avant le dispatch d'outil ; `decide_partitioned` (l.675) suit le dispatch.

## Mutants (rejoués sur copie jetable de plugin/ + scripts/)
casefold du verrou -> GW-W-CASE-1 rouge · crochet excepthook retiré -> GW-CRASH.2/.3/.4, GW-CRASH-PRE-a.2/b.2/b.3 rouges · casse de « workstreams » -> GW-W-CASE-3 rouge · `commondir` ignoré -> GW-LOC-2.2 rouge. Les mutants complets GW-M-* sont à 57-11.

## Commits
`1b14615b` test RED tâche 1 · `be50721e` feat GREEN tâche 1 · `6c45174f` test tâche 2

## Déviations
1. **Reprise** : un premier exécutant, figé sur un appel Bash, a été arrêté ; tâche 2 reprise depuis son diff non commité (relu, rejoué, validé), tâche 1 vérifiée.
2. **Pas de RED pour la tâche 2** : le guard de la tâche 1 porte déjà tout le comportement ; discriminance prouvée par les 4 mutants ci-dessus plutôt que par un rouge initial.
3. **Défaut de fixture corrigé** : GW-PRE « PATH sans git » rouge (la table de hachage de bash gardait `git`) ; `hash -r` ajouté. Aucun défaut du guard révélé.

## Problèmes
`check-version-sync.sh` rouge (compte de suites) : attendu jusqu'à 57-15.

## Self-Check: PASSED
Suite neuve 71/0 ; `test-guard-driver-lock.sh`, `test-hook-exit-contract.sh`, `test-hook-exit-parc.sh`, `test-vf-portable.sh`, `check-planning-consumers-registered.sh` exit 0 ; diff des deux suites existantes et de `hooks.json` vide contre la base.
