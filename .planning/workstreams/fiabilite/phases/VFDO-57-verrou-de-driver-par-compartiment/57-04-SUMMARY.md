---
phase: 57-verrou-de-driver-par-compartiment
plan: 04
subsystem: conductor
tags: [driver-lock, workstream, bash, concurrence, mutation, ab-test]
requires:
  - phase: 57-03
    provides: driver-lock.sh compartiment-aware complet (status --all, suffixe de portee, registre frere)
provides:
  - "preuve de concurrence : un gagnant par verrou (compartiments, depot, deux worktrees), 24 x 5 tours"
  - "temoin A/B octet pour octet du lab plat contre la copie gelee d'avant la phase"
  - "neuf mutants rouges tracés DL-M-a a DL-M-i (QUAL-01)"
key-files:
  created: [plugin/conductor/scripts/tests/fixtures/driver-lock-pre-e8771d9.sh]
  modified: [plugin/conductor/scripts/tests/test-driver-lock-ws.sh]
key-decisions:
  - "Mutants : neuf matrices rejouees en parallele (en serie : 302 s de mutants, hors borne confortable) ; verdict rendu dans l'ordre apres wait"
  - "Famille de cas = identifiant avant le premier point (WS-LEG-1, WS-INV-dotdot) ; ensembles attendus mesures puis relus un par un"
requirements-completed: [DLWS-01, DLWS-02, DLWS-03, DLWS-05, DLWS-08]
status: complete
completed: 2026-10-10
plan_head_before: 740fb461
---

# Phase 57 Plan 04: Concurrence, A/B du lab plat, mutants Summary

**La suite `test-driver-lock-ws.sh` (492 assertions) prouve un gagnant unique par verrou sous concurrence, le lab plat au bit près contre la copie gelée `e8771d94`, et un rouge par comportement neuf ; `driver-lock.sh` n'a pas bougé.**

## Mesures
- Concurrence (24 x 5 tours) : WS-CONC-ACQ (alpha + omega ensemble), WS-CONC-TKO (takeover de verrous périmés), WS-CONC-DEPOT, WS-CONC-WT (12 checkout + 12 worktree lié) : « rounds hors contrat : 0 » x4. Pire tour : aucun hors contrat (1 gagnant par verrou à chacun des 5 tours). Un premier lancement a rendu 0 gagnant : défaut du compteur (glob), corrigé et doublé d'un témoin du compteur (WS-CONC-TEMOIN).
- A/B : `A/B : --help exclu (P57-D-37)` · `A/B lab plat : IDENTIQUE` (20 étapes, sans puis avec `VF_DRIVER_LOCK`, `cmp -s` des transcriptions normalisées). WS-AB-INTEGRITE : copie gelée == `git show e8771d94:…` (objet présent ; SKIP-INTEGRITE écrit sinon).
- Mutants : `== mutants : 9/9 tués ==`, témoin non muté à zéro KO. Ensembles basculés exacts : a {WS-LOC-1..4} · b {WS-INV, -dotdot, -quote, -slash, WS-VERBS-5a..5j} · c {WS-ALL-1..3, WS-ENV, WS-LEG-1..3, WS-NOWS, WS-VERBS-4} · d {WS-LEG-1, WS-LEG-4} · e {WS-ENV} · f {WS-AB} · g {WS-ALL-2, WS-ALL-3, WS-LEG-1..4, WS-VFL} · h {WS-ALL-4, WS-RC2-file, -lien, -vide} · i (21 familles dont WS-FIRST, WS-LAST ABSENT : signature du piège P1).
- Durée : suite complète 117 s (bash par défaut), 137 s sous `/bin/bash` 3.2 (dont mutants 75 s) ; borne 600 s tenue.

## Commits
`928bd89f` test (concurrence) · `f9742dba` test (A/B, copie gelée, mutants)

## Déviations
None - plan executed exactly as written. Précisions : pas de RED au sens classique (le mécanisme existe, la preuve est une mesure ; le rouge est celui des mutants) ; `bash -e` sur les deux suites existantes s'arrête au premier code non nul attendu (non conçues pour `-e`), rejouées en `bash` simple comme la CI. Trailer de co-auteur « Claude Sonnet 5.5 » (modèle réel).

## Problèmes
`check-version-sync.sh` rouge (compte de suites) : attendu jusqu'à 57-15 (la copie gelée n'est pas une suite). L'usage concurrent réel à deux humains reste à la Phase 61.

## Self-Check: PASSED
`test-driver-lock-ws.sh` exit 0 (492/0, aussi `/bin/bash`), `test-driver-lock.sh` 243/0, `test-guard-driver-lock.sh` exit 0 ; diff des deux suites existantes vide contre la base ; `cmp` copie gelée vs `git show e8771d94` exit 0 ; exécutable (100755).
