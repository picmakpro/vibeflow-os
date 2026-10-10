---
phase: 57-verrou-de-driver-par-compartiment
plan: 11
subsystem: conductor
tags: [guard, driver-lock, mutation, ab-test, fail-closed, latence]
requires:
  - phase: 57-08
    provides: guard partitionné complet (volet Write/Edit 57-05, volet Bash 57-08)
provides:
  - "témoin A/B du guard en lab plat contre la copie gelée de cff1e2af (bit près)"
  - "douze mutants rouges tracés GW-M-a à GW-M-l (QUAL-01), fail-closed compris"
key-files:
  created: [plugin/conductor/scripts/tests/fixtures/guard-driver-lock-pre-cff1e2a.sh]
  modified: [plugin/conductor/scripts/tests/test-guard-driver-lock-ws.sh]
key-decisions:
  - "Ensemble basculé = assertions (identifiant=nombre d'échecs), plus strict que la famille de cas du plan"
  - "Mode GW_MODE=matrice : sous-processus d'un mutant, A/B et mutants exclus (pas de récursion)"
requirements-completed: [DLWS-03, DLWS-06, DLWS-08]
status: complete
completed: 2026-10-10
---

# Phase 57 Plan 11: Preuves du guard (A/B lab plat, mutants, latence) Summary

**Le guard d'un lab plat rend les mêmes stdout, stderr et codes que la copie gelée d'avant la phase sur 73 payloads x 5 états de verrou x 2 régimes ; chacun des douze comportements neufs rougit sous sa mutation, dont le crochet fail-closed neutralisé ou posé trop tard ; `guard-driver-lock.sh` n'a pas bougé.**

## Bilans verbatim
`A/B guard lab plat : IDENTIQUE` (365 passages par régime, VF_DRIVER_LOCK posé puis chemin par défaut) · `GW-AB-INTEGRITE.1` copie gelée == `git show cff1e2af:…` (objet présent) · `== mutants : 12/12 tués ==` · `== resultat : 180 ok, 0 ko ==` (suite 161 -> 180 assertions, 105 s au total dont mutants 45 s ; borne 600 s tenue).
Témoin non muté : programme python embarqué compile, zéro assertion en échec. Preuve que l'A/B discrimine : un crochet fail-closed posé aussi en lab plat rougit les deux régimes (payload à octet NUL), ligne 321 de la transcription.

## Ensembles basculés (assertion=nombre d'échecs)
a `-z` : NONASCII-1, C-REL-tenu=2 · b `--no-renames` : C-REN-1, -2 · c crochet neutralisé : CRASH.2/.3/.4, CRASH-PRE-a.2, b.2, b.3 · d crochet posé tard : CRASH-PRE-a.2, b.2, b.3 (CRASH.* restent verts) · e exemption `worktree add` : T-EXEMPT-1 · f condition de worktree : T-OTHERWT=6, T-OTHERWT-bis · g session courante = autrui : 15 assertions « détenteur » dont TRACE-3.2 · h cartographie : TRACE-2.2, TRACE-4.1, W-LEG-3, Q-PASS, MARK-W-4 · i RELEASE_FORM_FILES : C-REL-tenu=2 · j `-a` : C-ALL-1, -2 · k ajouts : C-ADD-1 · l ancien verrou : W-LEG-1, -2. Trace « rouge <cas> / attendu / obtenu » dans la sortie de la suite.

## Latence (hypothèse A5, hors suite, 50 appels de `git commit`, script `57-11-latence.sh` du scratchpad)
- lab plat, aucun verrou (sonde bash seule) : **4,7 ms** par appel
- lab partitionné, verrou d'autrui sur alpha (python + git rev-parse + git diff --cached) : **72,6 ms** par appel
- repère : lab plat sous ancien verrou d'autrui (python seul) 39,8 ms. Le surcoût du chemin partitionné vs le chemin plat sous verrou est donc ~33 ms (deux git durcis).

## Déviations
1. **Prédiction du plan corrigée (GW-M-a)** : le plan attendait GW-C-NONASCII seul ; mesuré, GW-C-REL-tenu (VERSION, docs/ADR.md) bascule aussi : sans `-z` le saut de ligne reste collé au nom, qui ne correspond plus à la liste exacte des fichiers de forme de release (le commit passe). Effet réel du mutant, pas un défaut du guard ; ensemble relu un par un puis fixé.
2. **Granularité** : l'ensemble est exprimé en assertions et non en familles (GW-CRASH, GW-T-OTHERWT…) : plus strict, contient chaque cas nommé par le plan. GW-M-i = `RELEASE_FORM_FILES` rendue sans effet à l'usage (`pb in ()`), équivalent à la vider.
3. **Pas de RED pour la tâche 2** (le guard porte déjà le comportement, la preuve est le rouge des mutants) ; RED réel pour la tâche 1 (copie gelée absente : 161 ok, 2 ko).
4. Un premier ordre de tri (`id=n`) faisait échouer f à tort (comparaison triée différemment) : tri final ajouté des deux côtés.

## Commits
`2596f2ad` RED A/B · `e049e57a` copie gelée + A/B vert · `1b9b96a8` mutants. Aucun défaut du guard révélé, aucun changement de `guard-driver-lock.sh`.

## Self-Check: PASSED
Suite neuve 180/0 ; `test-guard-driver-lock.sh` 103/0 ; `test-vf-portable.sh` 16/0 ; `test-hook-exit-contract.sh` 40/0 ; `test-hook-exit-parc.sh` 42/0 ; diff vide des deux suites existantes et de `hooks.json` contre la base ; `cmp` copie gelée vs `git show cff1e2af` exit 0. `check-version-sync.sh` rouge (compte de suites) : attendu jusqu'à 57-15 (la copie gelée n'est pas une suite).
