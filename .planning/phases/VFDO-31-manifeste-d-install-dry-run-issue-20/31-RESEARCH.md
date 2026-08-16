# Phase VFDO-31: Manifeste d'install + dry-run (issue #20) - Research

**Researched:** 2026-08-16
**Domain:** Bash shell engine internals (`plugin/_internal/vibeflow-update.sh`), install/update/uninstall
lifecycle, no external packages, no web research required — this is a refactor + capability-addition
phase entirely internal to this repo.
**Confidence:** HIGH — every fact below is `[VERIFIED: file:line]`, sourced from the `rech-moteur` DAG
node (agent `Explore`, read-only, full read of the three target scripts + CI workflow + gate scripts),
persisted at `31-RECHERCHE-moteur.md` in this same directory. This RESEARCH.md reformats that
anatomical work into the canonical structure the planner expects — it does not add new findings.

<user_constraints>
## User Constraints (from 31-CONTEXT.md)

31-CONTEXT.md does not use the `## Decisions` / `## Claude's Discretion` / `## Deferred Ideas`
headers verbatim — it is structured as ten numbered arbitrages (D-31-01..10, all pre-tranchés,
"Claude's Discretion documented" regime, not reopenable), execution constraints (§4), anti-patterns
(§5), risks (§6), and out-of-scope remontées (§7). Mapping onto the expected shape:

### Locked Decisions (§3 of 31-CONTEXT.md — do not reopen)

- **D-31-01** — Manifest is recorded AT WRITE TIME via one unique helper (indicative name
  `vf_place`/`vf_record`) that either (a) writes AND records the path, or (b) announces the path
  without writing. First work lot = introduce the helper and migrate the ~35 write sites — mechanical
  refactor, atomic commit, zero observable behavior change.
- **D-31-02** — Manifest format: one path per line, relative to `TARGET_ROOT`, LF terminator,
  `LC_ALL=C sort`, no header/comment. No directory-type lines — a directory laid by `cp -r` is
  recorded file-by-file. Atomic write (tmp + `mv`), pattern of `mark_installed` (115-124). Zero
  absolute path in the file (gate `check-machine-paths.sh` would flag it in `project` scope where
  `.claude/` is versioned).
- **D-31-03** — Manifest only records artifacts EXCLUSIVELY owned by the module. Closed exclusion
  list: `scripts/vf-portable.sh` (engine property, posed by `copy_engine_lib` 319-344, shared across
  modules) · `.claude/memory/*` (seeded by `seed-registres.sh`, live lab data) ·
  `scripts/.vibeflow-installed`, `scripts/.vibeflow-manifest-*` (engine state, not module content) ·
  `.backups/**` (safety net, never auto-delete candidate) · `docs/<module>/**` (written outside
  `TARGET_ROOT`, relative to cwd — appears in `--dry-run` plan but never in the manifest; a
  test fixes this asymmetry).
- **D-31-04** — Three regimes for indirect writes via 7 sub-processes: **A. Predicted exactly**
  (`generate-agent-commands.sh` → `commands/<mod>.md` @264, `build-gsd-index.sh` via `VF_INDEX_OUT`
  @680, `build-gsd-capabilities-index.sh` via `VF_CAPS_INDEX_OUT` @695) → exact `[plan] + <path>`
  line, sub-process NOT invoked, enters manifest. **B. Delegated preview** (`merge-hooks.sh` @396-400)
  → `merge-hooks.sh` learns a plan mode and renders its own `~ settings.json hooks.X += …` line;
  forbidden to reimplement merge logic engine-side. **C. Announced, not enumerated**
  (`seed-registres.sh` @482, `inject-mcp-tools.sh` @293, `ensure-design-deps.sh` @717) →
  `[plan] ~ <target> (effect of <script>, content not enumerated)` line; out of manifest scope.
  MANI-02's proof: two distinct tests — total equality on a fixture triggering no regime-C
  sub-process, and presence-of-announce-lines on a fixture that does trigger them.
- **D-31-05** — Output format = the issue #20 format, on **stdout** (engine's `log()` is stderr,
  §1.5 below): `[plan] + <path> (<module> vX)` / `[plan] ~ <path> <effect>` / `[plan] - <path>
  (disappeared from module, backed up)`. Path shown with `TARGET_ROOT` prefix (user-facing view);
  manifest storage stays relative (D-31-02) — display and storage are two separate contracts.
- **D-31-06** — Flag surface: `--dry-run` parsed in the same pre-parse as `--scope` (43-59), valid
  before `cmd="$1"`. Accepted on `install` and `update` only (no `calibrate` sub-command exists in
  the engine — `/vf-calibrate` is a skill that calls `update <module>`, §1.4 below). On `uninstall`,
  `rollback`, `status`, `sync`: explicit error, exit 1 — never silently ignored (would risk an
  accepted-then-ignored `--dry-run` on the most dangerous verb). A dry-run writes NOTHING — no
  registry, no `.gitignore`, no backup, no manifest.
- **D-31-07** — MANI-03 convergence order: read old manifest → pose (helper records new) → diff →
  backup → delete → write new manifest. A path is deleted only if ALL hold: present in old manifest
  · absent from new · exists on disk · resolves under `TARGET_ROOT` after normalization (no `..`
  escape) · outside the exclusion list. Systematic backup to `$BACKUP_DIR/<mod>-<ts>-removed/`
  before deletion, listed to the user. **Unparsable manifest = LOUD and NON-destructive** (blank
  line, absolute path, `..`, residual `\r` → refuse to use manifest for deletion, refuse loudly,
  delete nothing). **Missing manifest = graceful fallback**, not an error (pre-Phase-31 install
  base) — no convergence deletion this update, manifest written this run, next update converges.
- **D-31-08 (RÉVISÉ, commit `1baf63a`)** — README "N suites" counter (`README.md:124`,
  `README.fr.md:128`): manual update in the commit that creates the new suites, no NEW gate to
  create. **CORRECTION of the original research premise**: the claim "no gate controls this
  counter" was FALSE — `scripts/check-version-sync.sh` §9 already compares
  `find plugin scripts -path '*/tests/test-*.sh' | grep -c .` against both README's first
  `[0-9]+ suites` match and fails on mismatch. The gate exists; this phase must keep it green, not
  avoid creating a duplicate. Re-measure via
  `find plugin scripts -type f -path '*/tests/test-*.sh' | wc -l` (61 at cadrage time, so 62+ after
  the phase). Both README also carry a SECOND, historical "61 suites" mention each (README.md:145,
  README.fr.md:150, inside the v2.53.0 changelog narrative) that the gate does not read (`head -1`
  on first match) — those are a record of that past release and must NOT be touched by this phase.
- **D-31-09** — Manifest readers: `update_module` is THE deliverable (MANI-03). Passing
  `uninstall_module` to the manifest (same graceful fallback if absent) is planned as an explicitly
  **abandonable last wave** if the plan grows too large. Validator/vf-audit reader is out of scope
  (already "later" per ARCHITECTURE.md).
- **D-31-10** — Consumer skill wiring (`/vibeflow-install` step 5, `/vf-calibrate` step 4): minimal
  edit — call the verb with `--dry-run`, display output, pose after existing go/no-go (ADR-031), no
  UX overhaul. Bump `VERSION` + `CHANGELOG.md` of touched modules per repo discipline
  (`check-version-sync.sh` gates the `**Version**` header of module READMEs).

### Claude's Discretion (remaining COMMENT/découpage choices — planner's freedom)

The phase's WHAT/WHY is locked (above); the plan owns HOW/decoupage: wave breakdown, exact helper
signature, `merge-hooks.sh` plan-mode flag name and output line format, `test-manifest.sh` file
layout and assertion numbering, exact mutation to prove red per suite. All of these are the
planner's job per the mandate — see `<downstream_consumer>` in the plan-phase workflow.

### Deferred Ideas (OUT OF SCOPE — §7 of 31-CONTEXT.md, do not plan these)

1. Adding a SECOND, dedicated gate for the "N suites" README counter — moot: `check-version-sync.sh`
   §9 already gates it (D-31-08 revised, commit `1baf63a`). Nothing left to defer on this point.
2. `--dry-run` on `uninstall` — refused in v1 by scope discipline (D-31-06).
3. `docs/<module>/` being written relative to cwd instead of scope — pre-existing engine
   inconsistency, NOT corrected here (D-31-03) — deserves its own decision later.
</user_constraints>

## Summary

The engine (`plugin/_internal/vibeflow-update.sh`, 1040 lines [re-verified post-hotfix `a396e88`, was 1036 at cadrage time]) has **no manifest of what a module's
pose actually wrote** — `uninstall_module` (812-899) reconstructs the file list by re-reading the
**cache** at uninstall time, which is wrong the moment a module has left the cache (patched over today
by a hardcoded `retired-modules.txt`, 7 lines, 1 active entry). Three functions — `install_module`
(573-765), `gitignore_add_paths` (175-244), `uninstall_module` (812-899) — each reimplement their own
enumeration of "which files belong to module X" by re-deriving it from convention-detection over the
cache directory. Phase VFDO-31 replaces these three parallel enumerations with **one manifest, written
as a side-effect of the actual pose**, consumed by `update_module` for convergence (MANI-03) and shown
in advance via `--dry-run` (MANI-02) — both fed by the *same* code path (D-31-01), which is the only
shape that makes "dry-run lied" structurally impossible instead of merely tested-against.

**Primary recommendation:** Introduce one write helper (`vf_place`/similar) used by every one of the
~35 disk-write call sites in `vibeflow-update.sh`; in "real" mode it writes + appends the path (relative
to `TARGET_ROOT`, LF, `LC_ALL=C sort` at manifest-close time) to the module's manifest file; in
"--dry-run" mode it announces the same line on stdout and performs no I/O. `merge-hooks.sh` gets a
companion plan-mode flag so its own preview line (regime B) is not reimplemented engine-side.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Manifest write (MANI-01) | Engine (`vibeflow-update.sh`) | — | sole writer of module artifacts, must be the sole writer of the manifest |
| Dry-run plan rendering (MANI-02) | Engine (same call sites, gated by the write helper) | `merge-hooks.sh` (regime B delegation) | dry-run must share the write path, not a parallel one (D-31-01, `REQUIREMENTS.md:959`) |
| Convergence delete (MANI-03) | Engine `update_module` (573-765 pose + 921-944 orchestration) | — | already owns the pose; convergence is its natural extension |
| Hooks preview line (regime B) | `merge-hooks.sh` (351-408 delegation boundary already exists post-Phase-30) | — | engine already delegates hook writes here; delegating the preview keeps the single-writer invariant |
| Test suite (QUAL-01) | `plugin/_internal/tests/test-manifest.sh` (new) | CI discovery (`ci.yml:210-237`, pattern `find plugin scripts -type f -path '*/tests/test-*.sh'`) | matches the existing per-target suite convention, zero new runner infra needed |

## Engine Anatomy (full detail in `31-RECHERCHE-moteur.md`, this section is the load-bearing excerpt)

### Functions relevant to this phase [VERIFIED: plugin/_internal/vibeflow-update.sh]

| Lines | Function | Role |
|---|---|---|
**[RE-VERIFIED post-hotfix `a396e88`, v2.53.1 — the engine grew by exactly 4 lines (a comment
expansion inside `scripts_prefix_for_scope`, around line 356), shifting every range that starts
after that point by +4 vs. the numbers this table originally carried]**

| Lines | Function | Role |
|---|---|---|
| 115-124 | `mark_installed` | writes the module registry (tmp+mv) — the atomic-write pattern the manifest helper must copy (unchanged, before the shift point) |
| 175-244 | `gitignore_add_paths` | one of the three parallel enumerations; covers 2 paths install's enumeration misses: `.claude/memory/` (221) and `scripts/vf-portable.sh` (243) (unchanged, before the shift point) |
| 350-386 | `find_hooks_merger` (350-355) + `merge_module_hooks` (369-386) | delegation boundary to `merge-hooks.sh` — regime B's insertion point |
| 445-469 | `copy_module_scripts` | globs `*.sh/.mjs/.js` (chmod +x) and `*.txt` flat into `scripts/`, plus `scripts/tests/*` |
| 573-765 | `install_module` | full pose of a module — every write site inside this function must route through the new helper |
| 789-809 | `rollback_module` | `rm -rf` + `cp` from last backup — out of this phase's manifest scope but must remain green (non-regression) |
| 812-899 | `uninstall_module` | second parallel enumeration; D-31-09's optional last-wave target |
| 902-918 | `show_status` | not manifest-relevant, cited only because `update_module` follows it immediately |
| 921-944 | `update_module` | orchestrates delta-version → `install_module`, else `sync_module_governance`; convergence (MANI-03) inserts here |

### Full write-site inventory (the raw material for MANI-02's dry-run coverage)

**Direct writes** [RE-VERIFIED post-hotfix, plugin/_internal/vibeflow-update.sh:118-899, exact line numbers in
`31-RECHERCHE-moteur.md` §1.2] — registry (118-130), `.gitignore` (168, 170, scope `local` only),
engine lib (330, 336, 341), settings backup (380-381), module scripts (445-462), retired cleanup
(563), `install_module`'s 9 `mkdir -p`/`cp[-r]` pairs (595-668, including the `docs/<mod>/` cwd-relative
case at 634-635 that stays out-of-manifest per D-31-03), `backup_module` (769-779), `rollback_module`
(794-800), `uninstall_module`'s 10 removal statements (815-886).

**Indirect writes via sub-process** [RE-VERIFIED post-hotfix, plugin/_internal/vibeflow-update.sh:257-742 — exact per-callsite numbers shift +4 vs. the figures below, verify on pieces before editing] — this is
the D-31-04 three-regime table's source: `generate-agent-commands.sh` (264, regime A),
`inject-mcp-tools.sh` (293, regime C), `merge-hooks.sh` (396-400/427-429, regime B, writes BOTH
`settings.json` and `settings.local.json`), `build-gsd-index.sh` (680, regime A),
`build-gsd-capabilities-index.sh` (695, regime A), `ensure-design-deps.sh` (717, regime C),
`seed-registres.sh` (482/499/738, regime C). Non-deterministic timestamp calls (`date` at 381/767)
must be neutralized for the "dry-run == disk diff" equality test to be stable.

### TARGET_ROOT / scope resolution [VERIFIED: plugin/_internal/vibeflow-update.sh:39-89]

`--scope`/`--dry-run` both parse in the pre-`cmd="$1"` block (43-59). Scopes: `user → $HOME/.claude`,
`project|local → ./.claude`; `project` vs `local` differ ONLY in `gitignore_add_paths` gating (178)
and the `--settings-local` routing (391-393, 422-424) which is active for both `project` and `local`.
`BACKUP_DIR="$TARGET_ROOT/.backups"` (83) — the destination for MANI-03's pre-deletion backups.

### Command surface [RE-VERIFIED post-hotfix, plugin/_internal/vibeflow-update.sh:952-1040]

`case` on `cmd="$1"`: `install` (952-970, `--all`/`--with-deps <mod>`/`<mod>`) · `update` (971-995,
`--all` runs `cleanup_retired_modules` then loops the registry then `ensure_mandatory_baseline`;
`<mod>` → `update_module`) · `uninstall` (996-1020) · `rollback <mod>` (1021-1024) · `status`
(1025-1027) · `sync` (1028-1031, explicit no-op) · default (1032-1035, usage + exit 1). **No
`calibrate` sub-command exists** — confirms D-31-06's "install + calibrate = these two verbs" mapping.
**No `--dry-run`, `--plan`, or `--verbose` flag exists anywhere today** — this phase creates the flag
from nothing, there is no prior art to extend.

### Logging conventions [RE-VERIFIED post-hotfix, plugin/_internal/vibeflow-update.sh:30-31 (unchanged, before the shift point) — the 900-912 range no longer isolates a logging-specific block post-shift; see `show_status`/`uninstall_module` tail instead]

Single helper `log()` → **stderr**, fixed prefix `[vibeflow-update] `. No level system, no `[ok]`/
`[plan]` prefixes exist today (D-31-05's format is new, not reused). `show_status` (898-914) is the
engine's ONLY current stdout output (`printf` tabulated) — confirms D-31-05's choice of stdout for
the dry-run plan as consistent with existing precedent, not a new convention invented from nothing.
`merge-hooks.sh` has its own separate stderr prefix `[merge-hooks] ` (line 411).

### Existing manifest-adjacent state [VERIFIED: plugin/_internal/vibeflow-update.sh:82, 111-114]

Written: `$TARGET_ROOT/scripts/.vibeflow-installed`, format `module=version` — the ONLY state the
engine persists today. Read-only, never written: `retired-modules.txt` (format `module:artefact`),
`<mod>/module.json` (`requires`/`mandatory` only — **not** read for "what files to pose", confirmed
below), `<mod>/VERSION`. `known-versions.txt` belongs to the `infrastructure-audit` module's own data,
not an install manifest — do not confuse the two in the plan.

### How a module's files are decided at pose time [RE-VERIFIED post-hotfix, plugin/_internal/vibeflow-update.sh:573-765]

**The engine does NOT read `module.json` to decide what to pose.** `install_module()` uses
convention-detection (`if [ -f ]`/`if [ -d ]` tests) over the cache directory:

| Type | Test (line) | Source → Destination |
|---|---|---|
| 1 skill mono | `-f SKILL.md` (594) | → `skills/<mod>/SKILL.md` |
| 2 multi-skills | `-d skills/` (601) | `skills/<n>/*` → `skills/<n>/` (`cp -r`, whole dir) |
| 3 agent / 3b multi | `-f AGENT.md` (612) / `-d agents/` (620) | → `agents/<mod>.md` or `agents/*.md` |
| 4 doc | `-d content/` (632) | → `docs/<mod>/` (**outside TARGET_ROOT, cwd-relative** — D-31-03 exclusion) |
| 5 rules | `-d rules/` (643) | → `rules/*.md` |
| refs skill / refs agent / config | 650 / 658 / 666 | → `skills/<mod>/references\|config/` or `agents/<mod>-references/` |
| scripts | `copy_module_scripts` (441-465) | globs `*.sh/.mjs/.js` (chmod +x), `*.txt` (no chmod), flat into `scripts/`, plus `scripts/tests/*` |
| hooks | `-f hooks/hooks.json` (367) | delegated merge, not a direct write (regime B) |

Two write regimes mixed: **file-by-file via glob** (rules, agents, scripts — natural manifest grain)
vs. **whole-directory via `cp -r <dir>/*`** (nested skills, content, references, config — MUST be
expanded file-by-file at manifest-write time per D-31-02, since the manifest never records a directory
line).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Hooks merge preview | A second JSON-merge simulator inside `vibeflow-update.sh` | `merge-hooks.sh`'s new plan mode (regime B) | `merge-hooks.sh` already owns dedup-by-basename (161, 175-196) and dual-target routing (`is_local_entry`, 201-206) post-Phase-30; reimplementing it engine-side is exactly the "dry-run in a separate code path" anti-pattern `REQUIREMENTS.md:959` forbids |
| Test suite discovery | A new local runner script | Existing CI pattern `find plugin scripts -type f -path '*/tests/test-*.sh' \| sort` (`.github/workflows/ci.yml:210-237`) | no local runner exists today by design; `test-manifest.sh` just needs to match the naming convention to be auto-discovered |
| Atomic manifest write | A bespoke lock/rename scheme | The existing `mark_installed` pattern (tmp file + `mv`, 115-124) | already proven in this exact codebase for the registry file; the manifest has the identical atomicity requirement |

## Environment Availability

N/A — this phase has zero external dependencies beyond what the repo already uses everywhere
(`bash`, POSIX coreutils, `python3` via `merge-hooks.sh`'s existing `resolve_bash_abs()`/`PYBIN`
resolution at 72-114, already proven working post-Phase-30). No new tool, runtime, or package is
introduced.

## Package Legitimacy Audit

N/A — this phase installs no external packages (npm/pypi/crates or otherwise). Pure shell refactor
+ new test suite within the existing repo.

## Common Pitfalls

### Pitfall 1: Manifest as a second enumeration instead of a write-time side-effect
**What goes wrong:** Building a dedicated "list what this module owns" function that walks the cache
directory the same way `install_module`/`gitignore_add_paths`/`uninstall_module` already do.
**Why it happens:** It looks like the natural place to "add a manifest feature."
**How to avoid:** D-31-01 is explicit: the manifest is the side-effect of the *same* write call the
pose already makes, via one shared helper. A fourth enumeration reproduces the exact bug this phase
closes (three enumerations to keep in sync becomes four).
**Warning signs:** A new function whose only job is "list files under `$CACHE_DIR/$mod`" without
routing through the write helper.

### Pitfall 2: Directory-line manifest entries
**What goes wrong:** Recording `skills/<mod>/` as one manifest line for a `cp -r` pose, instead of
every file inside it.
**Why it happens:** `install_module` already treats whole-directory poses (`cp -r <dir>/*`) as one
logical unit — mirroring that grain into the manifest is the path of least resistance.
**How to avoid:** D-31-02 forbids directory lines outright — a directory-owning convergence delete
(`rm -rf`) is exactly what would let MANI-03 destroy a third-party file dropped into that same
directory, which the success criterion 3 test exists to catch.
**Warning signs:** A manifest line ending in `/` or a convergence step calling `rm -rf` on a path
read straight from the manifest without expanding to individual files first.

### Pitfall 3: Non-deterministic dry-run/real diff (timestamps)
**What goes wrong:** The "dry-run plan == real disk diff" equality test (D-31-04's proof requirement)
flakes because `backup_module`/`merge_module_hooks` embed `$(date ...)` (381, 767) in real paths that
a dry-run cannot predict without also calling `date`.
**Why it happens:** Backups are timestamped by design; a naive equality test compares the announced
path literally against the realized path.
**How to avoid:** Neutralize/freeze the timestamp source in the test fixture (inject a fixed clock or
compare path *patterns* rather than exact strings for the backup line only — the manifest content
itself, per D-31-02, never contains timestamps).
**Warning signs:** An intermittently-failing MANI-02 equality test that only fails around backup
lines.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Bash test scripts, no external test runner — convention: `set -uo pipefail`, `ok()/ko()/skip()` helpers, numbered asserts, exit 1 if ≥1 KO. Model: `plugin/_internal/tests/test-vibeflow-update.sh:29-41` [VERIFIED] |
| Config file | none — CI discovers suites by filesystem pattern, no config file to register a new suite |
| Quick run command | `bash plugin/_internal/tests/test-manifest.sh` (new suite, single file) |
| Full suite command | `find plugin scripts -type f -path '*/tests/test-*.sh' \| sort \| while read t; do bash "$t" \|\| echo "FAIL $t"; done` — mirrors CI's own discovery+run pattern [VERIFIED: .github/workflows/ci.yml:210-237] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| MANI-01 | pose writes `scripts/.vibeflow-manifest-<module>` | integration | `bash plugin/_internal/tests/test-manifest.sh` | ❌ Wave 0 (new suite) |
| MANI-02 | `--dry-run` plan == real disk diff (regime-A/no-regime-C fixture); announce-lines present (regime-C fixture) | integration, 2 distinct assertions | same suite, two fixtures | ❌ Wave 0 |
| MANI-03 | update deletes only manifested+absent+on-disk+under-TARGET_ROOT paths, with backup; third-party file untouched | integration | same suite | ❌ Wave 0 |
| QUAL-01 | 3 issues (PASS/FAIL/unparsable-BRUYANT) + proven mutation red | integration + mutation | same suite, mutation run manually documented in SUMMARY.md (trace of assertion/expected/actual) | ❌ Wave 0 |
| Non-regression | `test-vibeflow-update.sh` and `test-merge-hooks.sh` stay green before/after each lot | regression | `bash plugin/_internal/tests/test-vibeflow-update.sh && bash plugin/_internal/tests/test-merge-hooks.sh` | ✅ exists |

### Sampling Rate
- **Per task commit:** `bash plugin/_internal/tests/test-manifest.sh` (once it exists) + the two
  non-regression suites above
- **Per wave merge:** full discovery command above, rerun on the committed tree (not the working
  tree — CONTEXT.md §4 point 5)
- **Phase gate:** full suite green + mutation-red trace recorded before this phase can be marked
  verified

### Wave 0 Gaps
- [ ] `plugin/_internal/tests/test-manifest.sh` — new suite, covers MANI-01/02/03/QUAL-01 (see map
      above); no shared fixtures beyond what the module already defines inline in sibling suites —
      follow `test-vibeflow-update.sh`'s existing self-contained fixture style (temp dir per test)

## Security Domain

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V5 Input Validation | yes | The manifest file is parsed on every `update`/`uninstall` — it is untrusted input relative to the process reading it (could be hand-edited, corrupted, or CRLF-mangled). D-31-07's "unparsable manifest = LOUD and NON-destructive" rule IS the ASVS V5 control: refuse to act on malformed input rather than best-effort parse. |
| V4 Access Control | n/a | no auth/session boundary in this phase — single-user local CLI |
| V2/V3 Auth/Session | n/a | not applicable — no network surface |
| V6 Cryptography | n/a | no secrets/crypto touched |

### Known Threat Patterns for this stack
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Path traversal via `..` in a manifest line | Tampering | D-31-07's mandatory normalization check ("resolved under `TARGET_ROOT` after normalization, no `..` escape") before any delete — reject the whole manifest as unparsable if violated, never delete on a per-line basis with partial trust |
| CRLF-injected manifest line (`\r` residual) causing a path to silently mismatch and escape the exclusion filter | Tampering | Strip `\r` at manifest-read time (existing pattern already present at line 962 for `--with-deps`, reuse it) — a mismatch must fail LOUD (route to unparsable-refusal), not silently drop the line |
| Absolute path smuggled into a relative-path manifest | Tampering / Elevation of Privilege (writes outside TARGET_ROOT) | Same normalization gate as path traversal — an absolute path never resolves as "under TARGET_ROOT" post-normalization, so it is caught by the same check, not a separate one |
| `rm -rf` on a manifest line resolving to a directory instead of a file | Tampering (accidental mass-deletion) | D-31-02's no-directory-line rule at write time + a defense-in-depth `-f` (file-type) check at delete time in MANI-03's convergence loop before any `rm` |

## Sources

### Primary (HIGH confidence, all `[VERIFIED: file:line]`)
- `plugin/_internal/vibeflow-update.sh` (1040 lines, re-verified post-hotfix `a396e88`) — full read, functions/line-ranges/write-sites
  per `31-RECHERCHE-moteur.md` §1
- `plugin/_internal/merge-hooks.sh` (412 lines) — full read, contract per `31-RECHERCHE-moteur.md` §2
- `plugin/_internal/resolve-deps.sh`, `.github/workflows/ci.yml`, `scripts/check-version-sync.sh`,
  `plugin/conductor/skills/vf-calibrate/SKILL.md` — per `31-RECHERCHE-moteur.md` §3-4 Sources
- `.planning/phases/VFDO-31-manifeste-d-install-dry-run-issue-20/31-CONTEXT.md` — cadrage, ten
  arbitrages D-31-01..10, all locked
- `.planning/phases/VFDO-31-manifeste-d-install-dry-run-issue-20/31-RECHERCHE-moteur.md` — the
  underlying anatomical research this document reformats; read it directly for any line-level detail
  not reproduced above

## Metadata

**Confidence breakdown:**
- Engine anatomy (write sites, functions, command surface): HIGH — full-file reads, cited by line
- Validation Architecture / test map: HIGH — infra facts verified, but the mutation-per-suite detail
  is the planner's job (Claude's Discretion), not pre-decided here
- Security Domain: MEDIUM — the four threat patterns follow directly from D-31-07's already-decided
  rules (not independently re-derived); ASVS category selection is a straightforward mapping for a
  single-user local CLI with no network surface

**Research date:** 2026-08-16
**Valid until:** this phase's completion — the engine anatomy is a point-in-time snapshot of
`vibeflow-update.sh`/`merge-hooks.sh` at HEAD `1981586` (branch `feat/phase-31-manifeste-dry-run`)
and will be invalidated by the phase's own refactor
