---
phase: 30
slug: portabilit-windows-ii
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-08-15
---

# Phase 30 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | bash test suites maison (convention repo : discrimination par mutation) — aucun framework externe |
| **Config file** | none — les suites sont des scripts autonomes sous `plugin/*/tests/` et `scripts/tests/` |
| **Quick run command** | `bash plugin/_internal/tests/test-merge-hooks.sh` |
| **Full suite command** | `bash plugin/_internal/tests/test-merge-hooks.sh && bash plugin/_internal/tests/test-windows-crlf.sh && bash plugin/consolidator/scripts/tests/test-windows-guards.sh && bash plugin/_internal/tests/test-vf-portable.sh && bash scripts/tests/test-hook-exit-parc.sh` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `bash plugin/_internal/tests/test-merge-hooks.sh` (quick)
- **After every plan wave:** Run the full suite command above (les suites Wave 0 n'existant pas encore sont ignorées tant que leur plan n'est pas passé)
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

> Granularité : une ligne par plan — la carte par tâche vit dans le bloc `<verify><automated>` de
> chaque tâche des 8 PLAN.md (tous en portent un, vérifié par le plan-checker, Dimension 8 PASS).

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 30-01-* | 01 | 1 | PORT-02, PORT-04 | TM 30-01 | substitution args sans injection, dédup cross-forme | suite bash | `bash plugin/_internal/tests/test-merge-hooks.sh` | ✅ | ⬜ pending |
| 30-02-* | 02 | 1 | LEDG-03 | — | RFC jamais postée sans validation humaine | assertion fichier | `test -f 30-RFC-UPSTREAM.md && grep -qi 'non post' …` | ✅ | ⬜ pending |
| 30-03-* | 03 | 1 | WKTR-03 | — | jamais le dist-tag `next`, cache quotidien | suite bash | `bash scripts/tests/test-check-gsd-core-update.sh` | ❌ W0 | ⬜ pending |
| 30-04-* | 04 | 2 | PORT-03 | — | silence nominal au harness, translation `--hook` | inventaire + suite | `bash plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` | ✅ | ⬜ pending |
| 30-05-* | 05 | 2 | PORT-01 | TM 30-05 | locator jamais `source` muet, probe anti-stub WindowsApps | suite bash | `bash plugin/_internal/tests/test-vf-portable.sh` | ❌ W0 | ⬜ pending |
| 30-06-* | 06 | 3 | PORT-03 | — | parité 0/3 sur le parc gouvernance | suite bash | `bash scripts/tests/test-hook-exit-parc.sh` | ❌ W0 | ⬜ pending |
| 30-07-* | 07 | 3 | PORT-02 | TM 30-07 | fragments exec valides, zéro `{{VF_SCRIPTS}}` littéral | JSON + suite | `python3 -m json.tool …/hooks.json && bash plugin/_internal/tests/test-merge-hooks.sh` | ✅ | ⬜ pending |
| 30-08-* | 08 | 4 | PORT-05 | — | preuve par exécution CI lab frais | gates repo | `bash scripts/check-version-sync.sh && bash scripts/check-machine-paths.sh && …` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `plugin/_internal/tests/test-vf-portable.sh` — créée par le plan 30-05 (la lib naît avec sa suite)
- [ ] `scripts/tests/test-check-gsd-core-update.sh` — créée par le plan 30-03
- [ ] `scripts/tests/test-hook-exit-parc.sh` — créée par le plan 30-06

*Le reste : "Existing infrastructure covers all phase requirements" (test-merge-hooks, test-windows-crlf, test-windows-guards, test-dev-orchestrator existent déjà).*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Post public de la RFC upstream | LEDG-03 | Geste externe gaté humain (D-09) | Relire le draft `30-RFC-UPSTREAM.md`, valider, poster l'issue, coller le lien dans STATE + REQUIREMENTS |
| Constat CI verte sur lab frais après push | PORT-05 | Le push et la lecture du run sont hors sandbox d'exécution | Push de la branche, ouvrir le run Actions, vérifier suites windows-crlf + windows-guards + gates |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies (vérifié par le plan-checker, Dimension 8)
- [x] Sampling continuity: no 3 consecutive tasks without automated verify (idem)
- [ ] Wave 0 covers all MISSING references (à confirmer à l'exécution des plans 30-03/30-05/30-06)
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter (réservé à `/gsd-validate-phase` post-exécution)

**Approval:** pending
