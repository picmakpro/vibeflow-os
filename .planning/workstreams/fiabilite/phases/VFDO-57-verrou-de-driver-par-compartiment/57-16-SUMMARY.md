---
phase: 57-verrou-de-driver-par-compartiment
plan: 16
subsystem: porte-de-phase
tags: [porte, ledger, sans-release]
requires:
  - phase: 57-15
    provides: "quinze plans passed, compte de suites 102"
key-files:
  modified: [.planning/workstreams/fiabilite/REQUIREMENTS.md, .planning/workstreams/fiabilite/ROADMAP.md, .planning/workstreams/fiabilite/STATE.md]
key-decisions:
  - "Ledger à la main après la porte, aucun verbe state.* (P57-D-12) ; aucune release (P57-D-30)"
requirements-completed: [DLWS-01, DLWS-02, DLWS-03, DLWS-04, DLWS-05, DLWS-06, DLWS-07, DLWS-08]
completed: 2026-10-12
status: complete
---

# Phase 57 Plan 16: Porte de phase et ledger Summary

**Job `gates` rejoué depuis `ci.yml` : 19 étapes vertes, 3 sautées (conditionnelles à `main`) ; 102 suites sur 102 lancées, 100 vertes, 2 rouges environnementales prouvées ; témoins DLWS-03 intacts.**

## Porte de phase
Base HEAD `16d63d91`. Correctifs hors plan couverts par la porte : revue R-1/R-2/R-3 (`f6ef4a58..e97a4196`, `57-REVIEW.md` et `57-SECURITY.md` en `3e3451af`) ; F-1/F-2 tranchés par Samuel (AskUserQuestion session principale, 2026-10-11) = P57-D-38 et P57-D-39 (`e1101295..16d63d91`).

**Job `gates`** : `replay-ci-jobs.sh --job gates --root <dépôt>` (étapes extraites de `ci.yml`, `bash -e` sans pipefail), bilan « 19 rejouée(s), 3 sautée(s), 0 en échec ». Code 0 partout ; durée = écart des horodatages des journaux (l'outil n'en rend pas), arrondie à la seconde :
étape 2 check-agents `agents` 0 s · 3 check-agents `AGENT.md` 0 s · 4 `--resolve-agents=strict` 0 s · 5 check-skills 1 s · 6 check-blueprints 0 s · 7 check-version-sync 1 s · 8 check-state-integrity 1 s · 9 check-capability-activation 0 s · 10 check-machine-paths 1 s · 11 check-instruction-budget 1 s · 12 gates partitionnés (fixture) 1 s · 13 check-divergence 1 s · 14 check-planning-consumers-registered 2 s · 15 check-baseline-arbitrage 2 s · 16 check-gate-touche 2 s · 17 check-ajout-retrait 1 s · 18 check-affirmation-non-mesuree 3 s · 19 check-manual 5 s · 20 check-push-sans-pr (fixture) <1 s.
Sautées (conditionnelles `push` sur `main`) : check-push-sans-pr mesure réelle, check-release-tag. Les jobs `lab-frais` et `lab-frais-arme` ne se rejouent qu'en CI.

**Boucle complète** (commande du plan, détachée, `HOME` jetable avec lien vers le moteur, stdin fermé) : `find plugin scripts -path "*/tests/test-*.sh"` = 102 suites distinctes, fin `FIN 1487s`, deux `FAIL` :
- `test-check-description-fidelity.sh` : 8 OK / 36 KO, cause `module PyYAML introuvable pour python3` ; `test-quick-validate.sh` : 1 ok / 4 ko, `ModuleNotFoundError: No module named 'yaml'`. Le HOME jetable masque le site utilisateur de python.
- Preuve d'environnement : vrai HOME sur HEAD, deux rejeux chacune : 56 OK / 0 KO et 5 ok / 0 ko. Sur la base `dae0147b` (`git archive`) : vrai HOME 56/0 et 5/0 ; HOME jetable 8/36 et 1/4, le même rouge. Rouge de HOME, pas de code.
- Les 100 autres suites rendent 0, dont `test-driver-lock-ws.sh` 528/0 (110 s), `test-guard-driver-lock-ws.sh` 240/0, `test-check-mission-exit-ws.sh`, `test-driver-lock-consumers-ws.sh`.

**Témoins DLWS-03** (historique complet : les objets `e8771d94` et `cff1e2af` existent ; aucune ligne SKIP) :
- `test-driver-lock.sh` rc 0 (243/0), `test-guard-driver-lock.sh` rc 0 (103/0), 0 ligne SKIP ; `git diff --quiet dae0147b -- ` des deux suites : rc 0 (diff vide).
- `WS-AB-INTEGRITE.1/.2` PASS (copie gelée = `git show e8771d94:plugin/conductor/scripts/driver-lock.sh`, exécutable) ; « A/B lab plat : IDENTIQUE » (528/0). `GW-AB-INTEGRITE.1` PASS (copie gelée = `git show cff1e2af:…/guard-driver-lock.sh`) ; « A/B guard lab plat : IDENTIQUE » (240/0).

## Exigences cochées et preuve
Les huit sont cochées : suites vertes citées ci-dessus et aux SUMMARY 57-01 à 57-15 (`requirements-completed`), porte verte hors les deux rouges d'environnement prouvées.
- DLWS-01 : 57-01, 57-03, 57-04 (`test-driver-lock-ws.sh`, deux compartiments / même compartiment, concurrence 24×5).
- DLWS-02 : 57-01, 57-02, 57-04, 57-08, 57-12, 57-13 (verrou de dépôt, geste de release en deux gestes courts).
- DLWS-03 : témoins ci-dessus, 57-04, 57-05, 57-11.
- DLWS-04 : 57-01 (résolution explicite, repli `scope: depot`), complété par P57-D-39.
- DLWS-05 : 57-02, 57-04, 57-05, 57-15 (git-common-dir, worktrees, repli hors git).
- DLWS-06 : 57-05, 57-08, 57-11 (guard par compartiment, commits sur l'index), complété par P57-D-38.
- DLWS-07 : 57-03, 57-06, 57-07, 57-09, 57-10, 57-12 à 57-15 (consommateurs et doctrine, amendement d'ADR-053).
- DLWS-08 : 57-04, 57-05, 57-06, 57-07, 57-09, 57-11 (mutants DL-M-*, GW-M-*, mutants des consommateurs, A/B). L'usage concurrent réel reste à la Phase 61.

## Déviations
- Les deux `FAIL` de la boucle (PyYAML masqué par le HOME jetable) : nommés avec sortie, prouvés environnementaux par rejeu en vrai HOME sur HEAD et sur la base. Le critère « aucune ligne FAIL » du plan est donc satisfait à l'environnement près, pas à la lettre.
- Trois boucles lancées par erreur se sont chevauchées avant d'être tuées (la sonde `ps` du poste ne les montrait pas) ; la boucle retenue est la dernière, relancée seule sous un HOME neuf.

## Self-Check: PASSED
