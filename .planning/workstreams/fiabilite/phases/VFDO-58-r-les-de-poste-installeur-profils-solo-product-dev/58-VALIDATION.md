---
phase: "58"
slug: r-les-de-poste-installeur-profils-solo-product-dev
status: verified-human-pending
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-16"
---

# Phase 58 — Validation Strategy

> Contrat de validation par phase. Source : `58-RESEARCH.md` § Validation Architecture (mesures du 2026-10-16).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | suites bash maison (`ok`/`ko`, compteurs, `exit` non nul si un KO), mutants par awk sur copie de script |
| **Config file** | aucun ; découverte CI : `find plugin scripts -type f -path '*/tests/test-*.sh'` (ci.yml:218) |
| **Quick run command** | `bash <suite neuve du plan>` |
| **Full suite command** | `bash .planning/milestones/fiabilite-v1.0-phases/VFDO-40.1-r-vision-adr-029-et-du-gate-du-budget-d-instructions/tools/replay-ci-jobs.sh --job tests` puis `--job gates` |
| **Estimated runtime** | ~30 s par suite neuve ; `test-vibeflow-update.sh` ~271 s (tâche de fond) |

Baselines vertes avant modification : `test-build-module-catalog.sh` 14 OK · `test-resolve-deps.sh` 5 · `test-resolve-preset.sh` 15 · `test-manifest.sh` 62 · `test-check-hook-paths.sh` 17 · `test-check-instruction-budget.sh` 69 · `test-vibeflow-update.sh` 93 · `check-version-sync.sh` vert (102 suites).

---

## Sampling Rate

- **After every task commit:** la suite neuve du plan.
- **After every plan wave:** toutes les suites neuves + les baselines ci-dessus + `scripts/check-version-sync.sh` + `plugin/conductor/scripts/check-instruction-budget.sh`.
- **Before `/gsd-verify-work`:** `replay-ci-jobs.sh --job tests` et `--job gates` verts, plus `test-vibeflow-update.sh`.
- **Max feedback latency:** 60 secondes (hors `test-vibeflow-update.sh`).

---

## Per-Task Verification Map

| Exigence | Suite | Échec attendu (mutant / témoin) | File Exists | Status |
|----------|-------|---------------------------------|-------------|--------|
| RLPO-01 | `plugin/_internal/tests/test-vibeflow-update-role.sh` | règle d'ignorance neutralisée ; conditionnel retiré | ✅ | ✅ green |
| RLPO-02 | `plugin/conductor/scripts/tests/test-vf-role.sh` | priorité inversée ; invalide → repli `solo` | ✅ | ✅ green |
| RLPO-03 | `plugin/conductor/scripts/tests/test-check-role-consistency.sh` | mauvaise clé lue (`vf_role`) | ✅ | ✅ green |
| RLPO-04 | `plugin/_internal/tests/test-module-roles.sh` | `[]` accepté ; `["qa"]` accepté | ✅ | ✅ green |
| RLPO-05 | `plugin/installer/scripts/tests/test-build-module-catalog-role.sh` + les 14 cas existants | filtre inversé ; fermeture `product` contenant un module dev | ✅ | ✅ green |
| RLPO-06 | `test-vibeflow-update-role.sh`, `plugin/_internal/tests/test-resolve-preset-role.sh` (58-12, 22 OK) | filtre `--all` neutralisé ; PRE-MUT-1..4 (filtre des presets neutralisé, inversé, solo filtré, priorité inversée) | ✅ | ✅ green |
| RLPO-07 | `test-vibeflow-update-role.sh` | avis omettant un module hors poste | ✅ | ✅ green |
| RLPO-08 | `test-check-role-consistency.sh` | un mutant rouge par issue 0 / 1 / 3 / erreur d'analyse | ✅ | ✅ green |
| RLPO-09 | `test-check-role-consistency.sh` + `test-check-hook-paths.sh` (T12) | contenu brut imprimé ; traduction 3→0 retirée | ✅ | ✅ green |
| RLPO-10 | `plugin/_internal/tests/test-roles-e2e.sh` + `check-ajout-retrait.sh` | titre ADR-077 absent ou dupliqué | ✅ | ✅ green |
| RLPO-11 | `test-roles-e2e.sh` | témoin : `VF_ROLE=product` doit différer de l'install sans poste | ✅ | ✅ green (critère 6 : manuel, en attente) |
| RLPO-11 (critère 1 amendé, Q19) | `test-roles-e2e.sh` — `E2E-C1-DEPS-DECISION` | décision d'amorçage lue au journal ; deux mutants rouges (arbitrage Samuel, AskUserQuestion session principale, 2026-10-20) | ✅ | ✅ green |
| RLPO-12 | `scripts/check-version-sync.sh` | VERSION ≠ module.json ; « N suites » faux | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `plugin/_internal/tests/test-module-roles.sh` — RLPO-04
- [x] `plugin/conductor/scripts/tests/test-vf-role.sh` — RLPO-02
- [x] `plugin/conductor/scripts/tests/test-check-role-consistency.sh` — RLPO-03, 08, 09
- [x] `plugin/installer/scripts/tests/test-build-module-catalog-role.sh` — RLPO-05
- [x] `plugin/_internal/tests/test-vibeflow-update-role.sh` — RLPO-01, 06, 07
- [x] `plugin/_internal/tests/test-roles-e2e.sh` — RLPO-10, 11, 12

Chaque suite est créée par la tâche qui introduit son objet (tracer-first) ; +6 suites ⇒ « N suites » des deux README racine à recalculer.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Critère 6 : aucun nom de client | RLPO-11 | aucune liste de noms n'existe dans le dépôt | l'humain fournit la liste ; balayage du diff `a2ed5094..HEAD` par mots-clés à l'exécution |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 60 s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** suites rejouées vertes le 2026-10-20 (21, 26, 55, 26, 54, 22 OK + e2e armée) ; reste le critère 6 (manuel, liste de clients de Samuel) et la vérification humaine de la question du poste
