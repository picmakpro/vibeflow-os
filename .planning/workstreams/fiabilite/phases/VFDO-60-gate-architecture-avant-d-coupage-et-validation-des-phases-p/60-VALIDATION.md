---
phase: "60"
slug: gate-architecture-avant-decoupage
status: planned
nyquist_compliant: true
wave_0_complete: false
created: "2026-10-29"
---

# Phase 60 — Validation Strategy

> Contrat de validation par phase. Source détaillée : `60-RESEARCH.md` § Validation Architecture.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | suites bash `*/tests/test-*.sh` (`ok()/ko()/skip()`, exit 1 si un KO) |
| **Config file** | aucune — découverte `find plugin scripts -type f -path '*/tests/test-*.sh'` (ci.yml) |
| **Quick run command** | `bash plugin/conductor/scripts/tests/test-check-phase-validation.sh` |
| **Full suite command** | suites touchées une à une (≤ 2 workers) ; porte : `replay-ci-jobs.sh --job gates` |
| **Estimated runtime** | ~160 s hors suites longues |

## Sampling Rate

- **Après chaque commit de tâche :** la suite du fichier touché + `check-instruction-budget.sh` si un agent, un `AGENT.md` ou un `SKILL.md` a bougé.
- **Après chaque vague :** `check-agents.sh` (3 appels forme CI), `check-skills.sh`, `check-version-sync.sh`, `check-planning-consumers-registered.sh`, `check-ajout-retrait.sh --root . --strict`.
- **Avant `/gsd-verify-work` :** porte de phase verte.
- **Latence max :** 160 s

## Per-Task Verification Map

Raffinée à la planification (2026-10-29) : une ligne par tâche, commandes reprises des `<verify>` des plans (chacune suivie
d'un `<fails_when>` dans le plan). Toutes commencent par `bash`, donc identiques sous bash et zsh. Base de phase dérivée :
parent du commit `docs(60): cadrage de la Phase 60` (P60-PL-18).

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 60-01-T1 | 01 | 1 | ARCG-02, 09 | T-60-03 | `proposed` → 1, absent → 0, phase absente → 3 ; trailers COUVERT/DECLARE | suite + gates | `bash plugin/conductor/scripts/tests/test-check-phase-validation.sh` ; `check-ajout-retrait.sh --root . --strict` ; `check-gate-touche.sh` (0) ; `check-planning-consumers-registered.sh` | ❌ créé par la tâche | ⬜ pending |
| 60-01-T2 | 01 | 1 | ARCG-01, 02 | T-60-04 | bonne section, compartiment `--ws` seul, jamais le poste | suite | idem (+ `/bin/bash`) | ✅ après T1 | ⬜ pending |
| 60-01-T3 | 01 | 1 | ARCG-02 | T-60-01, 02, 05 | lien/FIFO/dossier/gros → 5, contenu non réimprimé, dix mutants | suite à mutants | idem ; sonde FIFO bornée ; `check-python-isolation.sh`, `check-machine-paths.sh` | ✅ après T1 | ⬜ pending |
| 60-02-T1 | 02 | 1 | ARCG-06, 07, 09 | T-60-07 | gabarit brut → 1, rempli + validé → 0, absent → 1 | suite + gates | `bash plugin/conductor/scripts/tests/test-check-architecture.sh` ; `check-ajout-retrait.sh --strict` ; `check-gate-touche.sh` (0) | ❌ créé par la tâche | ⬜ pending |
| 60-02-T2 | 02 | 1 | ARCG-07 | T-60-08, 09, 10 | état, rubriques, carte descriptive refusée, entrées hostiles → 5 | suite | idem (+ `/bin/bash`) | ✅ après T1 | ⬜ pending |
| 60-02-T3 | 02 | 1 | ARCG-06, 07 | T-60-11 | neuf mutants ; planning-core : un ajout + quatre fichiers de bump | suite à mutants + diff | idem ; `git diff --name-status` contre la base ; triade de version | ✅ après T1 | ⬜ pending |
| 60-03-T1 | 03 | 2 | ARCG-01 | T-60-35, 36 | témoin négatif d'abord, puis `get-phase` et `analyze` identiques avec et sans marqueur, lab plat et partitionné | preuve moteur | `bash plugin/conductor/scripts/tests/test-check-phase-validation.sh` (CPV-GSD-NEG, GET, ANALYZE, WS) ; `check-gate-touche.sh` (0) | ✅ (créée en 60-01) | ⬜ pending |
| 60-03-T2 | 03 | 2 | ARCG-01 | T-60-36 | case cochée par `phase complete`, marqueur conservé par insert et remove | preuve moteur | idem (CPV-GSD-COMPLETE, RENUM) ; garde « moteur présent », six cas verts | ✅ | ⬜ pending |
| 60-04-T1 | 04 | 2 | ARCG-01, 09 | T-60-14 | pose puis validation, constatées 1 puis 0 par le gate | suite + gates | `bash plugin/conductor/scripts/tests/test-vf-validation.sh` ; `check-gate-touche.sh` (0) ; `check-planning-consumers-registered.sh` | ❌ créé par la tâche | ⬜ pending |
| 60-04-T2 | 04 | 2 | ARCG-01, 06 | T-60-12, 13, 15, 17 | refus au poste product sauf override tracé, poste illisible → 5, une ligne changée, mode conservé | suite | idem (+ `/bin/bash`) | ✅ après T1 | ⬜ pending |
| 60-04-T3 | 04 | 2 | ARCG-01 | T-60-14 | lecteurs GSD inchangés sur la sortie réelle, huit mutants | preuve moteur + mutants | idem ; suites des deux gates vertes | ✅ après T1 | ⬜ pending |
| 60-05-T1 | 05 | 3 | ARCG-08, 09 | T-60-19, 20 | monde fermé, I1/I2, registre : un ajout zéro retrait | gates + suite | `check-agents.sh` ×3 (forme CI) ; `check-instruction-budget.sh` (INSTR 36/17/13/24/21, architecte `OK`) ; `test-product-team-bundle.sh` | ✅ (à étendre) | ⬜ pending |
| 60-05-T2 | 05 | 3 | ARCG-08 | T-60-18, 22 | architecte ne valide jamais, carte lue jamais lancée ; manager 24, front door 36 | suite + gates | `test-product-team-bundle.sh` ; `check-instruction-budget.sh` ; `check-skills.sh --strict --file` ; `check-agents.sh --file` | ✅ | ⬜ pending |
| 60-05-T3 | 05 | 3 | ARCG-08, 11 | — | minor, `proposable:false`/`roles`/`requires` intacts | triade + suite | triade de version contre la base ; `test-product-team-bundle.sh` | ✅ | ⬜ pending |
| 60-06-T1 | 06 | 3 | ARCG-03, 09 | T-60-23, 26 | porte de vf-coder avant le cycle, commande citée jouée contre le gate ; INSTR 33/22/46 | suite à ablation + gate | `bash plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` (T45 a, f) ; `check-instruction-budget.sh` | ✅ (cas à ajouter) | ⬜ pending |
| 60-06-T2 | 06 | 3 | ARCG-04, 01 | T-60-23 | Étape 0 bis avant le moteur direct, champ de brief de la pose | suite + gates | idem (T45 b, c) ; `check-skills.sh --strict --file` ; BOOTSTRAP `ligne 2610` ; `check-capability-activation.sh` | ✅ | ⬜ pending |
| 60-06-T3 | 06 | 3 | ARCG-05, 11 | T-60-24, 25, 27 | §5 : poste ∧ BRIEF, une phrase, override tracé, solo inchangé ; minor | suite + gate + triade | idem (T45 d, e ; T44 vert) ; `check-instruction-budget.sh` ; triade de version | ✅ | ⬜ pending |
| 60-07-T1 | 07 | 4 | ARCG-02, 07, 11 | T-60-28 | conductor en minor, « Scripts (N) » = compte réel | triade + compte | triade de version contre la base ; compte `find -maxdepth 1` des scripts comparé au README | ✅ | ⬜ pending |
| 60-07-T2 | 07 | 4 | ARCG-11 | T-60-29 | compte de suites = découverte CI, release intacte | gate | `bash scripts/check-version-sync.sh` ; `git diff --quiet` VERSION et manifestes | ✅ | ⬜ pending |
| 60-08-T1 | 08 | 4 | ARCG-10 | T-60-31 | parcours utilisateur FR/EN, limites écrites | gate doc | `bash manual/.tools/check-manual.sh` ; présence du verbe et du fichier dans quatre pages | ✅ | ⬜ pending |
| 60-08-T2 | 08 | 4 | ARCG-10 | — | comptes d'agents bornés (36 → 37) recomptés FR/EN, commande bornée citée par la page, architecte listé | gate doc | compte borné = titre FR et EN ; absence de la commande non bornée ; `check-manual.sh` | ✅ | ⬜ pending |
| 60-08-T3 | 08 | 4 | ARCG-10 | T-60-30 | pages d'équipe à jour, aucun ancien compte, aucun chemin de machine | gate doc | contrôle des anciens comptes ; `check-manual.sh` ; `check-machine-paths.sh` | ✅ | ⬜ pending |
| 60-09-T1 | 09 | 5 | ARCG-11 | T-60-33 | job `gates` rejoué depuis `ci.yml` | porte | `replay-ci-jobs.sh --job gates --list` puis `--job gates` (alarme 1 800 s) ; `check-instruction-budget.sh` | ✅ | ⬜ pending |
| 60-09-T2 | 09 | 5 | ARCG-01..11 | T-60-34 | suites une à une, périmètre, contrôles négatifs, non-régression solo réelle, G-2 0, ajout-retrait 0, base réelle des gardes nommée face à PB | porte | liste blanche du diff ; quatorze suites sous alarme 600 s ; `check-phase-validation.sh --ws fiabilite` sur les phases 59 et 60 ; `check-gate-touche.sh` ; `check-ajout-retrait.sh --strict` | ✅ | ⬜ pending |
| 60-09-T3 | 09 | 5 | ARCG-01..11 | T-60-32 | ledger à la main, ARCG-01 en `Partial` (pose non prouvée), arrêt avant la PR | intégrité | `check-state-integrity.sh --file` ; plans cochés = SUMMARY ; aucun tag | ✅ | ⬜ pending |

## Wave 0 Requirements

Aucune vague 0 séparée : chaque suite neuve est créée par la tâche traceuse qui la rougit d'abord (TDD de tâche).

- [ ] `plugin/conductor/scripts/tests/test-check-phase-validation.sh` — créée par 60-01-T1 (marqueur, codes, mutants), étendue par 60-03 (CPV-GSD)
- [ ] `plugin/conductor/scripts/tests/test-check-architecture.sh` — créée par 60-02-T1 (gabarit, gate architecture)
- [ ] `plugin/conductor/scripts/tests/test-vf-validation.sh` — créée par 60-04-T1 (écrivain, poste, VFV-GSD)
- [ ] cas `T45` dans `test-dev-orchestrator.sh` — créé par 60-06-T1 (refus vf-coder / vf-auto / head par ablation de clause)
- [ ] extension `AGENTS`/`CORPUS` de `test-product-team-bundle.sh` — 60-05-T1 (worker architecte)
- [ ] témoin positif d'abord pour chaque sonde de mutation et chaque comparateur (CPV-GSD-NEG, VFV-GSD-NEG, `t414_mutant`, `mutant_ptb`)

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Run réel du flux produit complet sur un lab désigné | P59-D-11 / hors phase | geste humain (condition de `proposable:true`) | reporté |
| Confirmation de P60-H-01..04 | — | arbitrage Samuel | reporté |

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies (25 tâches, chaque `<automated>` suivi d'un `<fails_when>`)
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (suites créées par les tâches traceuses)
- [x] No watch-mode flags
- [x] Feedback latency < 160 s par tâche, sauf dérogation nommée de la porte (rejeu du job `gates` sous 1 800 s, `test-vibeflow-update.sh` ≈ 150 s)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** planned 2026-10-29 (planificateur, sous mandat Samuel, /vf-auto session principale, 2026-10-29) — exécution à venir
