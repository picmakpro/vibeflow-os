---
phase: "69"
slug: "suivi-travail-en-cours-cockpit"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-11-03"
---

# Phase 69 — Validation Strategy

> Contrat de validation par phase. Source : `69-RESEARCH.md` § Validation Architecture. Le tableau par tâche est complété par le planificateur.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | suites bash maison (`assert_eq`/`assert_has`/`assert_ge`), sondes node écrites par la suite, `hygiene.sh` |
| **Config file** | aucun ; découverte par `find plugin scripts -path '*/tests/test-*.sh'` |
| **Quick run command** | `bash plugin/cockpit/scripts/tests/test-cockpit-<suite>.sh` |
| **Full suite command** | découverte complète des suites du module cockpit (liste produite par `scripts/ci-shard-suites.sh --all`, filtrée sur `plugin/cockpit/`), séquentielle, plus `plugin/_internal/tests/test-vibeflow-update-cockpit.sh` |
| **Estimated runtime** | 20 à 60 s par suite |

## Sampling Rate

- **After every task commit:** la suite de l'exigence touchée
- **After every plan wave:** toutes les suites du cockpit (au plus 2 en parallèle)
- **Before `/gsd-verify-work`:** porte de phase rejouée depuis `ci.yml`, job `gates`, découverte complète
- **Max feedback latency:** 60 secondes

## Per-Task Verification Map

Rempli par le planificateur (une ligne par tâche, exigence CKPT-13..28, direction d'échec, témoin rouge joué avant le code).

## Wave 0 Requirements

- [ ] `plugin/cockpit/scripts/tests/test-cockpit-avancement.sh` — CKPT-13..18 (laboratoires a-d et mutation)
- [ ] `plugin/cockpit/scripts/tests/test-cockpit-equipe.sh` — CKPT-19..22, 23 (sonde), 28
- [ ] `plugin/cockpit/scripts/tests/test-cockpit-forme-claude.sh` — CKPT-27
- [ ] `plugin/cockpit/scripts/tests/test-cockpit-transcript.sh` — CKPT-24..26
- [ ] `69-RED-TRACE.md` — sortie rouge (assertion, attendu, obtenu) de chaque suite avant le code

## Manual-Only Verifications

Aucune comportement de la phase n'est laissé sans vérification automatisée ; la recette humaine de la phase relève de `gsd-verify-work`.

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
