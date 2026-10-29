---
phase: "61"
slug: collaboration-deux-humains-divergence-armee
status: planned
nyquist_compliant: true
wave_0_complete: false
created: "2026-10-29"
---

# Phase 61 — Validation Strategy

> Contrat de validation par phase. Source : `61-RESEARCH.md` § Validation Architecture, raffinée par le registre
> `61-PLANNING-REGISTRE.md` (mesures du 2026-10-29).

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | suites bash `*/tests/test-*.sh` (`ok()/ko()/skip()`, exit 1 si un KO) |
| **Config file** | aucune — découverte `find plugin scripts -type f -path '*/tests/test-*.sh'` (ci.yml) |
| **Quick run command** | `bash plugin/conductor/scripts/tests/test-vf-divergence-hook.sh` |
| **Full suite command** | suites touchées une à une (≤ 2 processus lourds) ; porte : `replay-ci-jobs.sh --job gates` |
| **Estimated runtime** | ~180 s pour les quatre suites neuves ; `test-vibeflow-update.sh` ≈ 150-270 s à part |

## Sampling Rate

- **Après chaque commit de tâche :** la suite du fichier touché ; `check-gate-touche.sh` si la suite de conductor a bougé.
- **Après chaque vague :** `check-planning-consumers-registered.sh`, `check-machine-paths.sh`, `check-python-isolation.sh --min-sites 40`, `test-vibeflow-update-role.sh` (non-régression de l'engine).
- **Avant `/gsd-verify-work` :** porte de phase verte (61-08).
- **Latence max :** 180 s par tâche, sauf dérogation nommée de la porte.

## Per-Task Verification Map

Une ligne par tâche, commandes reprises des `<verify>` des plans (chacune suivie d'un `<fails_when>` dans le plan). Base de
phase : parent du commit `docs(61): cadrage de la Phase 61` (P61-PL-15).

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 61-01-T1 | 01 | 1 | COLB-01, 04, 07 | T-61-01 | install dev → hook → cri + ligne de journal après un vrai pull | e2e deux clones | `bash plugin/_internal/tests/test-divergence-deux-clones.sh` (D2C-TRACE) ; `--help` du script | ❌ créé par la tâche | ⬜ pending |
| 61-01-T2 | 01 | 1 | COLB-01, 02 | T-61-02, 04 | hook tiers intact, refus relayé, solo intact | e2e | idem (D2C-TRACE-SOLO, D2C-TRACE-TIERS) ; hors dépôt → 3 | ✅ après T1 | ⬜ pending |
| 61-01-T3 | 01 | 1 | COLB-03 | T-61-03 | script introuvable → NON VERIFIABLE journalisé | e2e | idem (+ `/bin/bash`) ; `test-vibeflow-update-role.sh` | ✅ | ⬜ pending |
| 61-02-T1 | 02 | 1 | COLB-06 | T-61-05 | ligne Role source, valeur de vf-role.sh, check-registres et reindex inchangés | suite | `bash plugin/consolidator/scripts/tests/test-registres-role.sh` ; `--numstat` des sources | ❌ créé par la tâche | ⬜ pending |
| 61-02-T2 | 02 | 1 | COLB-06, 09 | T-61-06, 07 | copies, six consommateurs avec/sans, témoins | suite + témoins | idem ; suites existantes de consolidator ; ordre source → copies | ✅ | ⬜ pending |
| 61-03-T1 | 03 | 2 | COLB-04 | T-61-13 | pull --rebase crié par post-rewrite, amend silencieux | suite | `bash plugin/conductor/scripts/tests/test-vf-divergence-hook.sh` (VDH-TRACE, REWRITE, REWRITE-AMEND, JOURNAL) ; G-2 | ❌ créé par la tâche | ⬜ pending |
| 61-03-T2 | 03 | 2 | COLB-02, 03 | T-61-10, 11, 14 | core.hooksPath, tiers, armé à la main, script sous l'arbre, état | suite | idem (+ `/bin/bash`) | ✅ | ⬜ pending |
| 61-03-T3 | 03 | 2 | COLB-03, 04, 09 | T-61-09, 12 | garde d'exécution, journal blindé, douze mutants | suite à mutants | idem ; gardes de dépôt | ✅ | ⬜ pending |
| 61-04-T1 | 04 | 2 | COLB-01 | T-61-17 | armé au poste dev, retiré au poste solo, journal gardé | suite | `bash plugin/_internal/tests/test-vibeflow-update-divergence.sh` (VUD-TRACE, ROLE-SOLO, ROLE-DEV) | ❌ créé par la tâche | ⬜ pending |
| 61-04-T2 | 04 | 2 | COLB-01, 03, 05 | T-61-16, 18, 19, 21 | sortie, désinstallation, refresh sans armer, scopes, dry-run, cache seul | suite | idem (+ `/bin/bash`) | ✅ | ⬜ pending |
| 61-04-T3 | 04 | 2 | COLB-09 | T-61-17, 21 | dix mutants de l'engine, suites existantes vertes | suite à mutants | idem ; quatre suites existantes sous alarme 600 s | ✅ | ⬜ pending |
| 61-05-T1 | 05 | 3 | COLB-07 | T-61-22 | fusion vue au pull suivant, pull --rebase, armés par l'install | e2e | `bash plugin/_internal/tests/test-divergence-deux-clones.sh` (D2C-FF, D2C-REBASE) | ✅ | ⬜ pending |
| 61-05-T2 | 05 | 3 | COLB-03, 07 | T-61-22, 23 | silence, worktree, branche piégée, trois témoins rouges | e2e + témoins | idem (+ `/bin/bash`) | ✅ | ⬜ pending |
| 61-05-T3 | 05 | 3 | COLB-08 | T-61-24, 25 | recette à six rubriques, relevé joué et capable de rougir, COLB-08 décochée | e2e + doc | idem (D2C-RELEVE, D2C-RELEVE-TEMOIN) ; rubriques de la recette | ✅ | ⬜ pending |
| 61-06-T1 | 06 | 3 | COLB-09 | T-61-26, 28 | conductor minor, catalogue, compte de scripts | triade + compte | triade contre la base ; « Scripts (N) » | ✅ | ⬜ pending |
| 61-06-T2 | 06 | 3 | COLB-06, 09 | T-61-26 | consolidator minor | triade | triade contre la base | ✅ | ⬜ pending |
| 61-06-T3 | 06 | 3 | COLB-06, 09 | T-61-27 | reference minor, release intacte | triade | triade contre la base ; `git diff --quiet` VERSION et manifestes | ✅ | ⬜ pending |
| 61-07-T1 | 07 | 4 | COLB-04, 05 | T-61-29 | manuel FR/EN : filet, journal, état, limites | gate doc | `bash manual/.tools/check-manual.sh` ; contenu des deux pages | ✅ | ⬜ pending |
| 61-07-T2 | 07 | 4 | COLB-05 | T-61-30 | install, mise à jour, désinstallation FR/EN | gate doc | idem ; `check-machine-paths.sh` | ✅ | ⬜ pending |
| 61-07-T3 | 07 | 4 | COLB-06, 09 | T-61-31 | champ Role au manuel, compte de suites | gate doc + version | `bash scripts/check-version-sync.sh` ; `check-manual.sh` | ✅ | ⬜ pending |
| 61-08-T1 | 08 | 5 | COLB-09 | T-61-33 | job `gates` rejoué depuis ci.yml | porte | `replay-ci-jobs.sh --job gates --list` puis `--job gates` ; `check-instruction-budget.sh` (37, ligne 2610) | ✅ | ⬜ pending |
| 61-08-T2 | 08 | 5 | COLB-01..09 | T-61-34 | suites une à une, périmètre, contrôles négatifs, gardes, bases | porte | liste blanche du diff ; quinze suites sous alarme 600 s ; G-2, ajout-retrait, consommateurs | ✅ | ⬜ pending |
| 61-08-T3 | 08 | 5 | COLB-01..09 | T-61-32 | ledger à la main, COLB-08 décochée, arrêt avant la PR | intégrité | `check-state-integrity.sh --file` ; plans cochés = SUMMARY ; COLB-08 Pending ; aucun tag | ✅ | ⬜ pending |

## Wave 0 Requirements

Aucune vague 0 séparée : chaque suite neuve est créée par la tâche traceuse qui la rougit d'abord (TDD de tâche).

- [ ] `plugin/_internal/tests/test-divergence-deux-clones.sh` — créée par 61-01-T1, étendue par 61-05
- [ ] `plugin/consolidator/scripts/tests/test-registres-role.sh` — créée par 61-02-T1
- [ ] `plugin/conductor/scripts/tests/test-vf-divergence-hook.sh` — créée par 61-03-T1 (surface G-2, `Gate-Touche`)
- [ ] `plugin/_internal/tests/test-vibeflow-update-divergence.sh` — créée par 61-04-T1
- [ ] témoin d'opposabilité d'abord pour chaque mutant et chaque comparateur (VDH-MUT-*, VUD-MUT-*, RRO-COMPARATEUR-TEMOIN, D2C-TEMOIN-*)

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Deux humains, deux clones, postes product et dev, un workstream, trois semaines sur un lab réel | COLB-08 | preuve d'usage humaine (P61-B-01, P61-B-02) | `61-RECETTE-LAB-REEL.md` |
| Comportement du hook sous Git Bash (Windows) | COLB-09 | aucun poste Windows dans la mission (A4) | recette Windows hors phase, limite écrite au manuel |
| Confirmation de P61-H-01, P61-PL-03, P61-PL-08 | — | arbitrage Samuel | reporté |

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies (23 tâches, chaque `<automated>` suivi d'un `<fails_when>`)
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (suites créées par les tâches traceuses)
- [x] No watch-mode flags
- [x] Feedback latency < 180 s par tâche, sauf dérogation nommée (porte : rejeu du job `gates` sous 1 800 s, suites longues de l'engine sous 600 s)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** planned 2026-10-29 (planificateur, sous mandat Samuel, /vf-auto session principale, 2026-10-29) — exécution à venir
