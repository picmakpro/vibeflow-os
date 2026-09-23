---
phase: "42"
slug: "fabrique-manifeste-date-et-invariants-de-doctrine-du-gate-des-agents"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-23"
---

# Phase 42 — Validation Strategy

> Contrat de validation de la phase : échantillonnage des retours pendant l'exécution. Dérivé de
> `42-RESEARCH.md` § Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | suite bash maison `test-*.sh` (`ok`/`ko`, mutation prouvée par `cmp`) |
| **Config file** | aucun — découverte CI par `find plugin scripts -type f -path '*/tests/test-*.sh'` |
| **Quick run command** | `bash plugin/conductor/scripts/tests/test-check-agents.sh` |
| **Full suite command** | rejeu local des 3 étapes CI `check-agents` (`.github/workflows/ci.yml` ~l.252-320) + boucle des suites `test-*.sh` |
| **Estimated runtime** | ~5 s (quick) · plusieurs minutes (full) |

---

## Sampling Rate

- **After every task commit:** `bash plugin/conductor/scripts/tests/test-check-agents.sh`
- **After every plan wave:** les 3 étapes CI `check-agents` rejouées localement + `bash plugin/conductor/scripts/check-instruction-budget.sh`
- **Before `/gsd-verify-work`:** CI complète verte (`gates`, `tests`, `lab-frais`, `lab-frais-arme`) — `lab-frais` est le témoin direct de la copie du manifeste (D-16)
- **Max feedback latency:** 10 s pour la suite rapide

---

## Per-Task Verification Map

*Rempli par le planificateur (une ligne par tâche) ; état initial ci-dessous par exigence.*

| Requirement | Behavior | Test Type | Automated Command | File Exists | Status |
|-------------|----------|-----------|-------------------|-------------|--------|
| FABR-01 | manifeste absent/illisible → refus explicite | unit + mutation | `bash plugin/conductor/scripts/tests/test-check-agents.sh` | ❌ W0 | ⬜ pending |
| FABR-02 | périmé → avertissement hors CI, exit 3 sous l'option CI, jamais de refus sur liste fermée | unit + mutation (`verifie_le` reculé) | idem | ❌ W0 | ⬜ pending |
| FABR-03 | I1-I7, jumeau négatif par invariant | unit + mutation | idem | ❌ W0 | ⬜ pending |
| FABR-04 | découverte récursive + exclusions | unit (fixture synthétique) | idem | ❌ W0 | ⬜ pending |
| FABR-05 | corpus réel conforme `--strict` + `--resolve-agents=strict` | integration | 3 étapes CI rejouées localement | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Nouveaux cas `T77+` dans `plugin/conductor/scripts/tests/test-check-agents.sh` (manifeste absent, illisible, périmé lenient/strict, I1-I7 avec mutation, découverte récursive + exclusion)
- [ ] Cas de test de l'installeur prouvant qu'un `.json` sous `<module>/scripts/` est copié (D-16)

---

## Manual-Only Verifications

*All phase behaviors have automated verification.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
