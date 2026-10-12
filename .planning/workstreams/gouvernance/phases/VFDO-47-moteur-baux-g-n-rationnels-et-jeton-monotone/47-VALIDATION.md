---
phase: "47"
slug: moteur-baux-generationnels-et-jeton-monotone
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-12"
---

# Phase 47 — Validation Strategy

> Contrat de validation par phase. Le mapping détaillé exigence -> commande vit dans `47-RESEARCH.md` § Validation Architecture ; les commandes exactes (`<automated>` + `<fails_when>`) sont dans chaque `47-NN-PLAN.md`. Ce fichier est l'amorce (`draft`) : `gsd-validate-phase` le fait passer à `validated`.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Suites bash `*/tests/test-*.sh` avec sections Python embarquées (`ok`/`ko`, jumeaux négatifs, mutants tués pour leur raison) |
| **Config file** | none (découverte CI : `find plugin scripts -type f -path '*/tests/test-*.sh'`) |
| **Quick run command** | la suite du plan touché (ex. `bash plugin/planning-core/scripts/tests/test-baux-registre.sh`), par sections via `VF_BAUX_SECTIONS` |
| **Full suite command** | suites de `planning-core` + `bash plugin/conductor/scripts/tests/test-dag.sh` + `bash scripts/check-version-sync.sh` + `bash scripts/check-machine-paths.sh` |
| **Estimated runtime** | suite neuve < 120 s visée ; pré-filtre > 600 s sous charge : par sections |

## Sampling Rate

- **After every task commit:** la suite du plan (zsh ET bash 3.2, sans `timeout`, sans `diff`)
- **After every plan wave:** suites de `planning-core` + `test-dag.sh` + gates de dépôt, gates de planning rejoués à la main avec `--file .planning/workstreams/gouvernance/STATE.md`
- **Before `/gsd-verify-work`:** tout vert, mutants tous tués avec trace (assertion, attendu, obtenu)
- **Max feedback latency:** 600 s

## Per-Task Verification Map

Voir `47-RESEARCH.md` § Validation Architecture (table Phase Requirements -> Test Map, BAIL-01..BAIL-10) ; les identifiants de tâche et commandes exactes sont portés par chaque PLAN.md.

## Wave 0 Requirements

- [ ] `plugin/planning-core/scripts/tests/test-baux-registre.sh` — BAIL-01, 05
- [ ] `plugin/planning-core/scripts/tests/test-bail-gate.sh` (+ fixture du banc) — BAIL-02, 03, 04, 10
- [ ] `plugin/planning-core/scripts/tests/test-g2prime.sh` — BAIL-06
- [ ] cas T50-T52 dans `plugin/conductor/scripts/tests/test-dag.sh` — BAIL-07
- [ ] cas de concurrence dans `test-recalc-planning.sh` — BAIL-08
- [ ] extension des lieux qui recopient la liste des gates + test de recensement — BAIL-09

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Rejeu réel en lecture seule (étapes 7a/7b) puis armement | BAIL-09 | Décision humaine bornée au moment d'agir (checkpoint, réponse par défaut = non) | Plans de checkpoint de la phase |
| CI Linux (flock sur dossier, ext4) | BAIL-01, 05, 07, 08 | Linux non disponible en local | CI de la PR (geste de Willy) |

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 600s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
