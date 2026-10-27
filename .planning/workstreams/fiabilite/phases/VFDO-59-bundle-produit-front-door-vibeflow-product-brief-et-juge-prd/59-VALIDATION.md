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

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 59-xx | voir PLAN | voir PLAN | PRDT-01 | — | agents cloisonnés, allowlist exacte | suite + gate | `bash plugin/product-team-bundle/scripts/tests/test-product-team-bundle.sh` | ❌ W0 | ⬜ pending |
| 59-xx | voir PLAN | voir PLAN | PRDT-02 | — | gabarits existants identiques à l'octet | suite | `bash plugin/product-team-bundle/scripts/tests/test-product-team-bundle.sh` | ❌ W0 | ⬜ pending |
| 59-xx | voir PLAN | voir PLAN | PRDT-03, 05 | T-59 fichier non fiable | refus lien/FIFO/gros fichier, rc 0/1/3/5/64 | suite à mutants | `bash plugin/product-team-bundle/scripts/tests/test-check-prd.sh` | ❌ W0 | ⬜ pending |
| 59-xx | voir PLAN | voir PLAN | PRDT-04, 06 | T-59 injection par le livrable jugé | juge lecture seule, halte sous le seuil | suite | `bash plugin/product-team-bundle/scripts/tests/test-product-team-bundle.sh` | ❌ W0 | ⬜ pending |
| 59-xx | voir PLAN | voir PLAN | PRDT-07 | — | 0 instruction de plus, T3/T5/T37 verts | gate + suite | `bash plugin/conductor/scripts/check-instruction-budget.sh` ; `bash plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` | ✅ | ⬜ pending |
| 59-xx | voir PLAN | voir PLAN | PRDT-08 | — | `roles`, `requires`, fermeture, `proposable:false` | suites | `bash plugin/_internal/tests/test-module-roles.sh` ; `bash plugin/installer/scripts/tests/test-build-module-catalog.sh` | ✅ | ⬜ pending |
| 59-xx | voir PLAN | voir PLAN | PRDT-09..12 | — | lignes ≤ 250, baselines, compteurs, bumps | gates | `bash scripts/check-version-sync.sh` ; `bash plugin/conductor/scripts/check-ajout-retrait.sh --root . --strict` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `plugin/product-team-bundle/scripts/tests/test-check-prd.sh` — PRDT-03, 05
- [ ] `plugin/product-team-bundle/scripts/tests/test-product-team-bundle.sh` — PRDT-01, 02, 04, 06, 08, 09, 10
- [ ] `plugin/product-team-bundle/scripts/tests/fixtures/` — REQUIREMENTS conforme / sans critère / gabarit non rempli, BRIEF complet / incomplet, CRLF, fence
- [ ] adaptation de `plugin/_internal/tests/test-module-roles.sh` (MR-LIST, MR-REAL)

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
