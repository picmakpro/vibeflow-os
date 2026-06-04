# Codebase Concerns

**Analysis Date:** 2026-06-04

## Tech Debt

**Shell script portability — macOS/Linux stat differences**
- Issue: Archive lock age detection uses platform-specific `stat` syntax
- Files: `consolidator/scripts/archive.sh` (line 54)
- Impact: Scripts fail silently on platforms where `stat -f` or `stat -c` is unavailable; lock mechanism unreliable
- Fix approach: Implement fallback chain with error handling validation; test cross-platform or use Perl/Python for timestamp calculation

**Python 3 dependency without explicit version pinning**
- Issue: Multiple scripts invoke `python3` without version specification; no way to verify minimum version available
- Files: `consolidator/scripts/reindex.sh`, `consolidator/scripts/detect-duplicates.sh`, `consolidator/scripts/detect-promotions.sh`, `infrastructure-audit/scripts/audit-infra.sh`
- Impact: Scripts may fail on systems with Python 2 as default `python3`; no graceful degradation if Python unavailable
- Fix approach: Add explicit version check in `vibeflow-update.sh` installer; document Python 3.8+ requirement in INSTALL.md; provide error message if missing

**Missing dependency verification in installer**
- Issue: `vibeflow-update.sh` doesn't verify required CLI tools (bash, awk, grep, sed, python3, jq, git, date) before module installation
- Files: `_internal/vibeflow-update.sh`
- Impact: Modules install successfully but fail at runtime with cryptic errors; silent failures in unattended installations
- Fix approach: Add `verify_dependencies()` function to installer; list required deps per module in module README

**Script test suite coverage gaps**
- Issue: Only 2 modules have test files; 5 modules without automated tests
- Files: `consolidator/scripts/tests/test-consolidator.sh` (exists), `software-architecture/scripts/tests/test-check-file-size.sh` (exists); `infrastructure-audit/scripts/audit-infra.sh` (no test), others
- Impact: Regressions in infrastructure-audit, reference-content modules undetected; no validation pipeline for docstring/schema changes
- Fix approach: Create test suite for `infrastructure-audit/scripts/audit-infra.sh` (JSON schema, hooks validation, version detection); add basic schema validation tests for `reference/` module

## Known Bugs

**Orphaned registries not completed**
- Symptoms: BLK-005 debt inherited from VibeFlow Lab; 32 LRN entries have index rows but no body content
- Files: Installed labs' `.claude/memory/LEARNINGS.md`
- Trigger: When `reindex.sh --apply` preserves index entries without corresponding body section
- Workaround: Manual completion required; `reindex.sh --audit` detects orphans but does not guide completion
- Recommendation: Create `/consolidate --pillar=recovery` skill to guide orphan completion

**ITERATION_LOG format not fully supported by consolidator**
- Symptoms: `reindex.sh`, `archive.sh`, `detect-duplicates.sh` skip ITERATION_LOG because format differs (Session headers, no standard ID pattern)
- Files: `consolidator/CHANGELOG.md` (line 54), scripts use hardcoded `^## [A-Z]+-[0-9]+` pattern
- Impact: ITERATION_LOG never archived, never checked for recent refs — archive.sh's C3 criterion ("0 recent refs in ITERATION_LOG") unreliable
- Fix approach: Add optional `--register-format=session-log` mode to reindex/archive; or create separate `consolidate-iteration-log.sh` script

**Archive script uses append-only, source cleanup manual**
- Symptoms: `archive.sh` appends entries to archive but doesn't remove from source file
- Files: `consolidator/scripts/archive.sh` (lines 227-228, explicit note)
- Impact: Source LEARNINGS/BLOCKERS/ADR files grow unbounded; audit accumulates duplicates (archived + source); confusing state
- Fix approach: Add `--cleanup` flag to `archive.sh` to remove archived entries from source after successful append; include safety check for backup integrity

## Security Considerations

**No secret/credential validation in installation pipeline**
- Risk: `.env` files, API keys, secrets may be accidentally copied into `.claude/` structure during module installation
- Files: `_internal/vibeflow-update.sh` (no filtering on what gets copied)
- Current mitigation: Relies on developer discipline; `.planning/codebase/` directory post-installation likely safe because Anthropic doesn't scan user secrets
- Recommendations: (1) Add `.gitignore` check before installation; (2) Warn if target lab contains `.env*` files; (3) Explicitly filter out credential patterns in copy operations (e.g., `cp` with `--exclude="*.env*"`)

**Shell injection risk in dynamic path construction**
- Risk: `vibeflow-update.sh` uses user-provided `--register=` argument in path expansion without validation
- Files: `_internal/vibeflow-update.sh` (lines 29-40 arg parsing), used in `register_file()` function
- Current mitigation: Argument passed through case statement (limited exposure); module names hardcoded
- Recommendations: Explicitly whitelist module names in arg parser; reject any `--register=` value containing `/`, `..`, or special chars

**Allowlist file permissions not enforced**
- Risk: `archive.sh` reads `archive.allowlist` without permission checks; writable by regular users
- Files: `consolidator/scripts/archive.sh` (line 20)
- Current mitigation: Only read, never write
- Recommendations: Document expected permissions (0644 or 0444); add warning if allowlist is world-writable

## Performance Bottlenecks

**Duplicate detection uses full Cartesian product comparison**
- Problem: `detect-duplicates.sh` compares all entry pairs (O(n²) title similarity checks)
- Files: `consolidator/scripts/detect-duplicates.sh` (lines 110-125 Python loop)
- Cause: No bucketing by category; compares LRN-001 vs LRN-500 even if unrelated
- Improvement path: (1) Bucket entries by category/tag before comparison; (2) Skip pairs beyond Jaccard threshold early; (3) Limit to last N entries (only recent learnings vs older)

**reindex.sh Python section extraction loads entire file into memory**
- Problem: For large registers (100+ entries), Python regex operations on full file content may be slow
- Files: `consolidator/scripts/reindex.sh` (lines 92-180)
- Cause: No streaming; re-reads file for each section extraction
- Improvement path: Single-pass Python parser; cache results in temp file

**Archive lock check on every SessionEnd**
- Problem: Every async archive check recalculates lock age and touches filesystem
- Files: `consolidator/scripts/archive.sh` (lines 52-61)
- Cause: No memoization; runs even if last archive was seconds ago
- Improvement path: Store last archive timestamp in registry; skip if < 1h since last run

## Fragile Areas

**validator agent orchestration via frontmatter `skills:`**
- Files: `validator/AGENT.md` (depends on native Claude Code frontmatter support)
- Why fragile: Depends on Claude Code version recognizing `skills:` in AGENT.md frontmatter (ADR-030 revised); if Anthropic changes syntax or parser, agent silently fails to delegate
- Safe modification: (1) Add fallback text instructions if frontmatter parsing fails; (2) Document minimum Claude Code version required; (3) Test frontmatter parsing during `infrastructure-audit` scan
- Test coverage: `validator` has no automated tests; no validation that frontmatter parses correctly; manual testing only

**skill-creator module has hardcoded VibeFlow Lab references**
- Files: `skill-creator/skills/skill-creator-workflow/SKILL.md` (contains `[NOM_LAB]` placeholders and VibeFlow-specific process)
- Why fragile: Module installed as-is without variable substitution; Lab teams must manually edit after install; high chance of copy-paste errors
- Safe modification: Create post-install hook that prompts for lab name and auto-replaces placeholders; validate that `[NOM_LAB]` is removed before marking install complete
- Test coverage: CHANGELOG lists "Personalization manual required after install" as known limitation; no automated validation that personalization happened

**reindex.sh preserves orphaned index entries by design, but no guidance for completion**
- Files: `consolidator/scripts/reindex.sh` (lines 261-280), tests verify orphans preserved
- Why fragile: Orphans accumulate; no automatic cleanup; no skill to guide completion; manual completion required but not enforced
- Safe modification: (1) Add `--orphan-report` flag to generate markdown list of incomplete entries with templates; (2) Create `/consolidate --pillar=recovery` skill; (3) Document that orphans block promotion
- Test coverage: `test-consolidator.sh` T3 specifically tests orphan preservation but does not test completion workflow

**detect-promotions.sh Python import dependencies**
- Files: `consolidator/scripts/detect-promotions.sh` (lines 27-78 uses `re`, `defaultdict` modules)
- Why fragile: Script assumes Python standard library is available; no error handling if modules missing
- Safe modification: Add try/except for imports; fallback to bash-only Jaccard calculation or skip that phase
- Test coverage: No test for Python unavailability scenario

## Scaling Limits

**Lock file TTL fixed at 5 minutes**
- Current capacity: Supports concurrent SessionEnd hooks on same lab
- Limit: If process takes > 5 minutes, lock expires; next session's archive runs in parallel → race condition possible
- Scaling path: (1) Make TTL configurable via env var; (2) Implement file-lock with process PID; (3) Log lock collisions; (4) Add `--force` flag to override stale locks

**Consolidator scripts load entire registers into memory**
- Current capacity: Tested on VibeFlow Lab (5 registers, ~200 entries each)
- Limit: Registers > 10k lines may cause Python regex timeout; no progress indication for large files
- Scaling path: (1) Stream processing for large files; (2) Add `--chunk-size=1000` option; (3) Implement resumable mode for interrupted operations

**infrastructure-audit hardcoded list of known tools and hooks**
- Current capacity: 8 hook events, ~20 native tools documented
- Limit: New Claude Code features (new hook events, new tools) require manual code update; drift undetected until audit runs
- Scaling path: (1) Move tool/event list to external JSON file pulled from Anthropic docs; (2) Add `--fetch-latest` mode; (3) Alert when docs out of date

## Dependencies at Risk

**Anthropic skill-creator module is frozen**
- Risk: Anthropic may release new version; no auto-update path
- Impact: Lab teams stuck on 248KB old version; new Anthropic skill features unavailable
- Migration plan: (1) Monitor Anthropic releases; (2) Create `skill-creator-next` branch; (3) Manual repackaging quarterly; (4) Version bump with release notes in CHANGELOG

**Python regex engine for learning/blocker parsing**
- Risk: Complex regex patterns in `reindex.sh` may behave differently on different Python versions
- Impact: Field extraction failures; orphans created incorrectly
- Migration plan: Add Python version requirement (3.8+); test regex on target Python versions

**`jq` dependency in infrastructure-audit**
- Risk: Not all systems have `jq` installed by default
- Impact: `audit-infra.sh` fails silently if `jq` missing
- Migration plan: Add to dependency check; provide alternative using Python JSON parsing

## Missing Critical Features

**No auto-completion guide for orphaned index entries**
- Problem: 32 LRN orphans exist in Lab but have no workflow to complete them
- Blocks: Cannot promote incomplete learnings; debt accumulates; completion requires manual guidance
- Recommendation: Create `/consolidate --pillar=recovery` skill with templates and guided form

**Drift detection between installed module version and available version**
- Problem: `vibeflow-update.sh status` shows versions but doesn't alert to security patches or critical updates
- Blocks: Security-critical fixes may be missed until next manual check
- Recommendation: Add `--check-updates` hook to SessionStart; email/alert if critical updates available

**No rollback validation after module downgrade**
- Problem: `vibeflow-update.sh rollback` restores files but doesn't verify integrity
- Blocks: Rollback may leave system in partially-migrated state if network fails
- Recommendation: Add checksum validation post-rollback; document recovery if interrupted

## Test Coverage Gaps

**infrastructure-audit has no unit tests**
- What's not tested: JSON schema validation, hook contract parsing, version detection regex, cross-platform stat usage
- Files: `infrastructure-audit/scripts/audit-infra.sh`
- Risk: Regressions in version detection (critical for Claude Code drift detection) undetected
- Priority: **HIGH** — validates runtime environment; should have >= 80% coverage

**validator agent orchestration not tested**
- What's not tested: Frontmatter skill parsing, Phase 4 process scanning, escalation to audit-architecture skill
- Files: `validator/AGENT.md`, `validator/` (no test directory)
- Risk: Agent silently fails to invoke skills if Anthropic changes syntax
- Priority: **HIGH** — orchestration layer critical; need manual regression test per release

**skill-creator installation not validated**
- What's not tested: Post-install personalization (placeholder replacement), skill availability after install
- Files: `skill-creator/`
- Risk: Installed module missing required fields; teams find out weeks later
- Priority: **MEDIUM** — installation should validate placeholders removed

**consolidator edge cases not covered**
- What's not tested: Very large files (1000+ entries), files with unusual encoding, dates outside 1970-2100 range, register names with special chars
- Files: `consolidator/scripts/reindex.sh`, `detect-duplicates.sh`
- Risk: Silent failures on edge-case inputs; register corruption possible
- Priority: **MEDIUM** — add fuzzing tests with generated data

**No integration tests across module dependencies**
- What's not tested: validator → consolidator → infrastructure-audit → software-architecture interaction
- Files: No integration test suite
- Risk: Module A works alone but breaks when combined with Module B after update
- Priority: **MEDIUM** — Add cross-module integration test in test-consolidator.sh or new suite

---

*Concerns audit: 2026-06-04*
