---
phase: 29
slug: distiller-les-gains-icm-g1-g5-investigation-dag-sh-scope-d-a
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-08-15
---

# Phase 29 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | suites bash maison (`test-*.sh`, conventions du repo : cas verts/rouges, mutations cmp-attestées) |
| **Config file** | none — chaque suite est autoporteuse sous `plugin/<module>/scripts/tests/` |
| **Quick run command** | `bash plugin/conductor/scripts/tests/test-dag.sh` (suite du mécanisme à ne pas régresser) |
| **Full suite command** | `for t in plugin/conductor/scripts/tests/test-*.sh plugin/dev-orchestrator/scripts/tests/test-*.sh; do bash "$t" || exit 1; done` |
| **Estimated runtime** | ~60 seconds |

---

## Sampling Rate

- **After every task commit:** Run `bash plugin/conductor/scripts/tests/test-dag.sh` + la suite du script touché par la tâche
- **After every plan wave:** Run la commande full suite ci-dessus
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 90 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| *(rempli par le planner — chaque tâche G1/G2/G3/G5 + investigation doit pointer sa suite)* | | | | | | | | | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test-dag.sh` vert AVANT tout geste de la phase (baseline de non-régression `--scope`, T1-T33) — infrastructure existante, aucun stub à créer
- [ ] Toute nouvelle suite (`test-check-map-drift.sh` si G3 crée le script) naît AVEC son script, jamais après

*Sinon : "Existing infrastructure covers all phase requirements."*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Lisibilité des ajouts doctrine (G1 digest, G5 Edit-Source) | TBD (plan) | La qualité rédactionnelle d'une doctrine ne se teste pas en bash — sa présence et sa densité (ADR-029) si | Relire le diff ; vérifier lignes ≤ plafonds via `wc -l` |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 90s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
