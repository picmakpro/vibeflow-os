---
phase: 31
slug: manifeste-d-install-dry-run-issue-20
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-08-16
---

# Phase 31 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Bash test scripts — no external runner. Convention: `set -uo pipefail`, `ok()/ko()/skip()` helpers, numbered asserts, exit 1 if ≥1 KO. Model: `plugin/_internal/tests/test-vibeflow-update.sh:29-41`. |
| **Config file** | none — CI discovers suites by filesystem glob, no registration file |
| **Quick run command** | `bash plugin/_internal/tests/test-manifest.sh` |
| **Full suite command** | `find plugin scripts -type f -path '*/tests/test-*.sh' \| sort \| while read t; do bash "$t" \|\| echo "FAIL $t"; done` (mirrors `.github/workflows/ci.yml:210-237`) |
| **Estimated runtime** | ~5-15 seconds per suite (bash, no network, no build step) |

---

## Sampling Rate

- **After every task commit:** Run `bash plugin/_internal/tests/test-manifest.sh` (once it exists) plus the two non-regression suites (`test-vibeflow-update.sh`, `test-merge-hooks.sh`)
- **After every plan wave:** Run the full discovery command above, on the tree **as committed** (not the working tree — 31-CONTEXT.md §4 point 5)
- **Before `/gsd-verify-work`:** Full suite must be green, mutation-red trace recorded (assertion / expected / actual) for every new suite
- **Max feedback latency:** ~30 seconds (no test in this phase touches network or a build pipeline)

---

## Per-Task Verification Map

> Seeded at requirement granularity — the planner assigns exact Task IDs / waves when it splits this
> into PLAN.md files. Every row below MUST end up covered by at least one task's `<verify>`.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| TBD (planner) | TBD | TBD | MANI-01 | V5 unparsable-manifest refusal | manifest write is atomic (tmp+mv), relative paths only, no directory lines | integration | `bash plugin/_internal/tests/test-manifest.sh` | ❌ Wave 0 | ⬜ pending |
| TBD (planner) | TBD | TBD | MANI-02 | — | `--dry-run` writes nothing at all; plan == real disk diff on a no-regime-C fixture | integration | `bash plugin/_internal/tests/test-manifest.sh` | ❌ Wave 0 | ⬜ pending |
| TBD (planner) | TBD | TBD | MANI-02 (regime C) | — | announce-lines present, honest about non-enumeration | integration | `bash plugin/_internal/tests/test-manifest.sh` | ❌ Wave 0 | ⬜ pending |
| TBD (planner) | TBD | TBD | MANI-03 | V5 path-traversal / absolute-path rejection | convergence deletes only manifested+absent+on-disk+under-TARGET_ROOT paths, with backup; third-party file untouched | integration | `bash plugin/_internal/tests/test-manifest.sh` | ❌ Wave 0 | ⬜ pending |
| TBD (planner) | TBD | TBD | QUAL-01 | V5 unparsable = LOUD + non-destructive | 3 issues (PASS/FAIL/unparsable) covered, mutation red proven with trace | integration + mutation | `bash plugin/_internal/tests/test-manifest.sh` (+ documented mutation run) | ❌ Wave 0 | ⬜ pending |
| TBD (planner) | TBD | TBD | Non-regression | — | existing engine behavior unchanged by the ~35-site helper migration | regression | `bash plugin/_internal/tests/test-vibeflow-update.sh && bash plugin/_internal/tests/test-merge-hooks.sh` | ✅ exists | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `plugin/_internal/tests/test-manifest.sh` — new suite, covers MANI-01/02/03 and QUAL-01's three
      issues + mutation-red requirement (see map above). No shared fixture framework needed beyond
      the module's existing self-contained temp-dir-per-test style (`test-vibeflow-update.sh`).

*No framework install needed — bash + coreutils already present, `python3` already used by
`merge-hooks.sh`.*

---

## Manual-Only Verifications

*None — all phase behaviors (manifest write, dry-run parity, convergence delete, unparsable refusal)
are scriptable against a fixture module in a temp `TARGET_ROOT`, matching the existing suite's style.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
