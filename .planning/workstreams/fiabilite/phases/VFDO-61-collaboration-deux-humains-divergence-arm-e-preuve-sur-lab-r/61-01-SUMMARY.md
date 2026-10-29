---
phase: 61-collaboration-deux-humains-divergence-arm-e-preuve-sur-lab-r
plan: 01
subsystem: conductor
tags: [divergence, git-hook, post-merge, installeur, journal]
status: complete
requires: []
provides: [vf-divergence-hook.sh (arm, disarm, status, run), find_divergence_hook, divergence_hook_apply, suite test-divergence-deux-clones.sh]
affects: [61-03, 61-04, 61-05, 61-06, 61-07]
requirements: [COLB-01, COLB-02, COLB-03, COLB-04, COLB-07]
commits: 3
plan_head_before: fee355c49f48d5ce52a1c4edc3f0ace9aa7ff786
plan_head_after: db7efd8cffe4f4ff4fd0f68084812eaa5118511b
actuals:
  tokens: 9800
  tasks: 3
  commits: 3
key-files:
  created: [plugin/conductor/scripts/vf-divergence-hook.sh, plugin/_internal/tests/test-divergence-deux-clones.sh]
  modified: [plugin/_internal/vibeflow-update.sh]
completed: 2026-10-29
---

# Phase 61 Plan 01: filet de divergence armé — tracer install → hook → journal

Un clone installé au poste product ou dev reçoit un hook `post-merge` qui rejoue `check-divergence.sh` depuis le cache du plugin, crie sur une divergence et journalise ; prouvé par un vrai `git pull --no-rebase` sur clones jetables.

## Contrat écrit dans l'en-tête du script
- Verbes : `arm [--path] [--check|--refresh]`, `disarm`, `status`, `run --hook post-merge|post-rewrite` ; codes énumérés par verbe (arm 0/1/2/3/64, disarm 0/2/3/64, status 0/1/2/3/64, run 0/1/2/64) ; `arm` imprime `CIBLE <hook>` (--check) et `BILAN verbe=arm code=<n>` sur stdout, messages `[vf-divergence]` sur stderr.
- Hook posé : sh POSIX, ligne 2 = `# vibeflow:vf-divergence-hook v1 - ...`, chemin absolu physique du script du cache entre apostrophes ; chemin disparu → `NON VERIFIABLE` + ligne de journal `introuvable`, exit 0.
- Journal v1 : `<git-common-dir>/vf-divergence/journal.tsv`, en-tête `# vf-divergence journal v1` + 7 noms de champs, 7 champs tabulés (date, hook, verdict, code, HEAD, signaux, raison). `run` : 1 crie et journalise, 0 et 3 se taisent, autre → NON VERIFIABLE journalisé ; `post-rewrite` ne joue que l'argument `rebase`.
- Engine : `find_divergence_hook` (cache seul), `divergence_hook_apply` en dernière ligne de `role_apply` (product/dev seulement), dry-run déclaré `[plan] ~ <cible>`, codes relayés sans jamais faire échouer l'install.

## Suite `test-divergence-deux-clones.sh` (6 cas, 6 ok / 0 ko)
D2C-TRACE, D2C-TRACE-SOLO, D2C-TRACE-TIERS (`cmp -s` du hook tiers), D2C-TRACE-INTROUVABLE, D2C-PLAN (--dry-run), D2C-VERBES (refresh, disarm, status, hors dépôt = 3, usage = 64, aucune écriture de config git).
Mutants prouvés rouges (suite relancée sur la source mutée, source restaurée) : M1 engine n'arme pas (14 ko), M2 engine arme au solo (4 ko), M3 écrase le hook tiers (6 ko), M4 sans repli introuvable (3 ko), M5 journal muet (2 ko), M6 divergence silencieuse (3 ko).

## Vérifications rejouées
`test-vibeflow-update-role.sh` : 54 OK, 0 KO. Suite neuve verte sous bash, `/bin/bash` 3.2.57 et mawk 1.3.4 (PATH de la CI). `check-machine-paths.sh`, `check-python-isolation.sh --min-sites 40`, `check-planning-consumers-registered.sh`, `check-gate-touche.sh`, `check-instruction-budget.sh` : rc 0 (aucune baseline touchée). `check-divergence.sh`, `scripts/hooks`, `.github` inchangés depuis le cadrage.

## Deviations from Plan
None - plan executed exactly as written. Deux écarts de forme sans effet : messages d'exécution du hook en ASCII (tiret simple à la place du tiret cadratin), `status` livré dès ce plan (version minimale, 61-03 l'étend) pour que l'en-tête ne documente aucun verbe absent.

## Rouge intermédiaire attendu
`check-version-sync.sh` : compte de suites 118 ≠ 119 (README et README.fr), nommé P61-PL-12, recompté en 61-07. Ni bump ni changelog ici (61-06).

## Known Stubs
None.

## Self-Check: PASSED
Fichiers créés présents ; commits f36b1572, d91f3007, db7efd8c ancêtres de HEAD.
