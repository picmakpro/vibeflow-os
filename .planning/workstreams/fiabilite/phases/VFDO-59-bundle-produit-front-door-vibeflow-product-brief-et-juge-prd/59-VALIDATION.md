---
phase: "59"
slug: bundle-produit-front-door-vibeflow-product-brief-et-juge-prd
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-27"
---

# Phase 59 — Validation Strategy

> Contrat de validation par phase. Source : `59-RESEARCH.md` § Validation Architecture (durées mesurées, toutes < 10 min).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | suites bash `*/tests/test-*.sh` (`ok()/ko()/skip()`, exit 0 si tout passe) |
| **Config file** | aucune — découverte `find plugin scripts -type f -path '*/tests/test-*.sh'` (ci.yml) |
| **Quick run command** | `bash plugin/product-team-bundle/scripts/tests/test-check-prd.sh` |
| **Full suite command** | les suites touchées une à une (jamais la découverte complète en parallèle) |
| **Estimated runtime** | ~5 min cumulées (`test-vibeflow-update.sh` 152 s, `test-dev-orchestrator.sh` 42 s, `test-roles-e2e.sh` 35 s) |

---

## Sampling Rate

- **After every task commit:** la suite du fichier touché + `bash plugin/conductor/scripts/check-instruction-budget.sh` si un agent ou un `AGENT.md` a bougé
- **After every plan wave:** `check-agents.sh` (3 commandes CI), `check-skills.sh`, `check-version-sync.sh`, `check-planning-consumers-registered.sh`
- **Before `/gsd-verify-work`:** porte de phase (dernier plan) verte
- **Max feedback latency:** 160 secondes

---

## Per-Task Verification Map

Raffinée à la planification (2026-10-27) : une ligne par tâche, commandes reprises des `<verify>` des plans (chacune suivie
d'un `<fails_when>` dans le plan). Toutes commencent par `bash`, donc identiques sous bash et zsh.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 59-01-T1 | 01 | 1 | PRDT-02 | T-59-01 | gabarit lu par `mark-complete`, 2 lignes changées | preuve moteur | `bash -c '…mark-complete PRD-01…'` (59-01) | ❌ créé par la tâche | ⬜ pending |
| 59-01-T2 | 01 | 1 | PRDT-02 | — | charte produit sans identifiant gras | structure | `bash -c '…titres…'` (59-01) | ❌ créé par la tâche | ⬜ pending |
| 59-01-T3 | 01 | 1 | PRDT-02, 12 | T-59-02 | existant de planning-core intact | diff + triade | `git diff --name-status` contre la base ; `check-version-sync.sh` filtré planning-core | ✅ | ⬜ pending |
| 59-02-T1 | 02 | 1 | PRDT-05, 09 | T-59-05 | rc 1 nommant l'ID, trailer COUVERT | suite + gate | `bash plugin/product-team-bundle/scripts/tests/test-check-prd.sh` ; `check-ajout-retrait.sh --root . --strict` | ❌ créé par la tâche | ⬜ pending |
| 59-02-T2 | 02 | 1 | PRDT-03, 05 | T-59-04 | BRIEF à cinq rubriques, contenu jamais réimprimé | suite | `bash plugin/product-team-bundle/scripts/tests/test-check-prd.sh` (+ `/bin/bash`) | ✅ après T1 | ⬜ pending |
| 59-02-T3 | 02 | 1 | PRDT-05 | T-59-03, T-59-06 | lien/FIFO/dossier/gros → 5, codes {0,1,3,5,64} | suite | idem + sonde FIFO bornée | ✅ après T1 | ⬜ pending |
| 59-02-T4 | 02 | 1 | PRDT-05 | T-59-07 | 8 mutants tués | suite à mutants | idem ; `check-planning-consumers-registered.sh`, `check-python-isolation.sh`, `check-machine-paths.sh` | ✅ après T1 | ⬜ pending |
| 59-03-T1 | 03 | 1 | PRDT-07 | T-59-08 | pointeur avant FIRST-02, INSTR ≤ baseline | suite + gate | `bash plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` ; `check-instruction-budget.sh` (ligne du head) | ✅ | ⬜ pending |
| 59-03-T2 | 03 | 1 | PRDT-07 | T-59-09 | carte, index, carte exhaustive | suite + gate | idem ; `check-capability-activation.sh` | ✅ | ⬜ pending |
| 59-03-T3 | 03 | 1 | PRDT-07, 12 | T-59-10 | minor, G-1 respecté | triade + G-1 | `bash -c '…VERSION…'` ; `check-baseline-arbitrage.sh` (0 ou 3) | ✅ | ⬜ pending |
| 59-04-T1 | 04 | 2 | PRDT-08, 12 | T-59-15 | visible product/solo, invisible dev | suite | `bash plugin/_internal/tests/test-module-roles.sh` ; `module-roles.sh visible` ; jq | ✅ (à adapter) | ⬜ pending |
| 59-04-T2 | 04 | 2 | PRDT-01, 09 | T-59-14 | monde fermé, témoin I6 | gate | `check-agents.sh` ×3 (forme CI) + copie mutée | ❌ créé par la tâche | ⬜ pending |
| 59-04-T3 | 04 | 2 | PRDT-04 | T-59-11, T-59-12 | rubric = 100, ancres du juge | structure + gate | `bash -c '…somme rubric…'` ; `check-agents.sh` | ✅ après T2 | ⬜ pending |
| 59-04-T4 | 04 | 2 | PRDT-03, 01 | — | workers cloisonnés | structure + gate | `bash -c '…ancres…'` ; `check-agents.sh` | ✅ après T2 | ⬜ pending |
| 59-04-T5 | 04 | 2 | PRDT-06 | T-59-13 | halte sous le seuil, proposition sans lancement | structure + gate | `bash -c '…ancres…'` ; `check-agents.sh` monde fermé | ✅ après T2 | ⬜ pending |
| 59-05-T1 | 05 | 2 | PRDT-01, 09 | T-59-18 | skill classé, front door à 3 avertissements, trailer | gates | `check-skills.sh --strict --file` ; `check-agents.sh --file` ; `check-ajout-retrait.sh` | ❌ créé par la tâche | ⬜ pending |
| 59-05-T2 | 05 | 2 | PRDT-01 | T-59-16, T-59-19 | jamais en Task, geste simple contrôlé | structure + gate | `bash -c '…ancres…'` ; `check-agents.sh --file` | ✅ après T1 | ⬜ pending |
| 59-05-T3 | 05 | 2 | PRDT-03 | — | BRIEF brut rc 1 (5 rubriques), rempli rc 0 | preuve croisée | `bash -c '…check-prd.sh --brief…'` | ❌ créé par la tâche | ⬜ pending |
| 59-05-T4 | 05 | 2 | PRDT-08, 11 | T-59-17 | README : vue pas droit, pose par install --all | doc | `bash -c '…première ligne…'` ; `check-machine-paths.sh` | ❌ créé par la tâche | ⬜ pending |
| 59-06-T1 | 06 | 3 | PRDT-10, 11 | T-59-21 | 5 lignes de baseline en `OK` | suite + gate | `bash plugin/product-team-bundle/scripts/tests/test-product-team-bundle.sh` ; `check-instruction-budget.sh` ; `check-baseline-arbitrage.sh` | ❌ créé par la tâche | ⬜ pending |
| 59-06-T2 | 06 | 3 | PRDT-01, 04, 06, 09 | T-59-20 | mutants de frontmatter et de clauses | suite à mutants | `bash plugin/product-team-bundle/scripts/tests/test-product-team-bundle.sh` | ✅ après T1 | ⬜ pending |
| 59-06-T3 | 06 | 3 | PRDT-02, 08 | — | gabarits ↔ script ↔ moteur, filtre du catalogue | preuves croisées | idem ; `bash plugin/installer/scripts/tests/test-build-module-catalog.sh` | ✅ après T1 | ⬜ pending |
| 59-06-T4 | 06 | 3 | PRDT-11 | — | 18 modules, suites recomptées, release intacte | gate | `bash scripts/check-version-sync.sh` ; `git diff --quiet` VERSION et manifestes | ✅ | ⬜ pending |
| 59-07-T1..T4 | 07 | 3 | PRDT-11 | T-59-23, T-59-24 | comptes recomptés, exposition dite | gate doc | `bash manual/.tools/check-manual.sh` + vérifs de faits par page | ✅ | ⬜ pending |
| 59-08-T1 | 08 | 4 | PRDT-01..12 | T-59-26 | job gates extrait de ci.yml | porte | `replay-ci-jobs.sh --job gates --list` puis `--job gates` ; `check-instruction-budget.sh` | ✅ | ⬜ pending |
| 59-08-T2 | 08 | 4 | PRDT-01..12 | T-59-27 | 15 suites une à une, périmètre, G-2 = 3 | porte | boucle séquentielle bornée (600 s par suite) ; liste blanche du diff ; `check-gate-touche.sh` | ✅ | ⬜ pending |
| 59-08-T3 | 08 | 4 | PRDT-12 | T-59-25 | ledger à la main, arrêt avant merge | ledger | `check-state-integrity.sh --file …/STATE.md` ; comptage SUMMARY/ROADMAP ; `git diff --quiet` release | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Pas de vague 0 séparée : chaque suite naît dans le plan qui pose ce qu'elle garde, en tâche tracer (témoin rouge à HEAD).

- [ ] `plugin/product-team-bundle/scripts/tests/test-check-prd.sh` — PRDT-03, 05 — plan 59-02 (vague 1)
- [ ] `plugin/product-team-bundle/scripts/tests/test-product-team-bundle.sh` — PRDT-01, 02, 04, 06, 08, 09, 10 — plan 59-06 (vague 3)
- [ ] fixtures de `test-check-prd.sh` GÉNÉRÉES À L'EXÉCUTION (`printf` sous `mktemp -d`), aucun dossier `fixtures/` versionné (P59-PL-07)
- [ ] adaptation de `plugin/_internal/tests/test-module-roles.sh` (MR-LIST, MR-REAL, MR-PRODUIT) — plan 59-04, avec le `module.json` (P59-PL-12)
- [ ] cas `T44` de `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` — PRDT-07 — plan 59-03 (P59-PL-11)

États intermédiaires nommés (P59-PL-15), jamais des échecs de plan : `check-version-sync.sh` rouge sur les comptes de
suites et de modules de la vague 1 à 59-06 ; `check-instruction-budget.sh` rc 2 SANS-BASELINE sur exactement les cinq
chemins neufs du bundle entre la vague 2 et 59-06.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Run réel complet BRIEF → PRD → `prd-gate` ≥ 80 sur un lab désigné par Samuel | PRDT-08 | précondition de la bascule `proposable:true`, hors de cette phase | PR tracée ultérieure |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 160s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
