---
phase: 28
slug: preuve-que-ce-qui-est-arm-dans-le-plugin-est-arm-chez-l-util
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-08-10
---

# Phase 28 — Validation Strategy

> Contrat de validation de la phase, pour l'échantillonnage de feedback pendant l'exécution.
> Source : `28-RESEARCH.md` §Validation Architecture (l. 1164+), faits mesurés le 2026-08-10.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | harness bash maison, zéro dépendance (`ok()` / `ko()` / `PASS` / `FAIL`) |
| **Config file** | aucune — la **convention de nommage est le roster** : `*/tests/test-*.sh` sous `plugin/` ou `scripts/` |
| **Découverte** | `find plugin scripts -type f -path '*/tests/test-*.sh' \| sort` [`.github/workflows/ci.yml:207`], plancher « 0 suite = échec » [`ci.yml:211-214`] |
| **Quick run command** | `bash plugin/dev-orchestrator/scripts/tests/test-check-capability-activation.sh` |
| **Full suite command** | boucle de découverte de `ci.yml:205-233` — **52 suites** mesurées le 2026-08-10 |
| **Estimated runtime** | quick ~secondes · full ~minutes |

---

## Sampling Rate

- **After every task commit:** la suite du gate seule (`quick run command`).
- **After every plan wave:** les 52 suites (boucle de découverte de `ci.yml:205-233`).
- **Before `/gsd-verify-work`:** CI verte sur les 3 jobs, job `lab-frais` inclus (D-04).
- **Max feedback latency:** quick < 30 s.

---

## Per-Task Verification Map

> Rempli par les plans (`28-NN-PLAN.md`) : chaque tâche porte son `<verify>` automatisé.
> Comportements à couvrir, dérivés des décisions du CONTEXT et de `28-RESEARCH.md` :

| Comportement (décision) | Requirement | Test Type | Automated Command | Status |
|---|---|---|---|---|
| Armement sans précondition ⇒ ROUGE (D-01b/D-02) | ARMD-03 | unit, fixture synthétique | `bash plugin/dev-orchestrator/scripts/tests/test-check-capability-activation.sh` | ⬜ pending |
| Désarmement ⇒ VERT sur la même fixture (D-06) | ARMD-07 | unit, mutation `cmp`-vérifiée | idem | ⬜ pending |
| `ensure-*` déclaré + câblé ⇒ VERT (D-02) | ARMD-04 | unit | idem | ⬜ pending |
| `ensure-*` non discriminant ⇒ refusé (A-4 ii) | ARMD-05 | unit | idem | ⬜ pending |
| Corpus d'artefacts vide ⇒ exit 2, jamais 0 (plancher) | ARMD-06 | unit | idem | ⬜ pending |
| Le gate tourne dans un lab **installé** (D-04) | ARMD-08 | intégration CI | étape neuve du job `lab-frais` | ⬜ pending |
| Le gate reste vert sur l'arbre réel | ARMD-09 | non discriminant, **après** les mutations | `bash plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` (T14d d/e) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] **Aucun.** L'infrastructure existe (harness, découverte par convention, fixtures, distribution
      par glob). **Rien à installer, rien à inscrire dans un roster.** [`28-RESEARCH.md` §Wave 0]

*Existing infrastructure covers all phase requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Recette humaine `mcp__*` | — | infaisable dans ce dépôt (aucun `.mcp.json`, serveur non connecté) — toute preuve produite ici serait fabriquée | reporté sur un lab iOS équipé (WINDOWS #3, `28-CONTEXT.md` §Deferred) |

*Tout le reste des comportements de la phase a une vérification automatisée.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
