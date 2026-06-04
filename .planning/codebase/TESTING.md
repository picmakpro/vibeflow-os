# Testing Patterns

**Analysis Date:** 2026-06-04

## Test Framework

**Runner:**
- Bash: native `test` expressions and manual exit codes (no external framework)
- Python: no test framework (tests run via subprocess CLI calls, results validated externally)

**Assertion Pattern (Bash):**
Custom assert function used in all test suites:
```bash
assert() {
  local name="$1"
  local actual="$2"
  local expected="$3"
  if [[ "$actual" == *"$expected"* ]]; then
    echo "  ✅ PASS — $name"
    PASS=$((PASS + 1))
  else
    echo "  ❌ FAIL — $name"
    echo "     Expected: $expected"
    echo "     Actual:   $actual"
    FAIL=$((FAIL + 1))
  fi
}
```

**Run Commands:**
```bash
# Run all tests for a module
./scripts/tests/test-consolidator.sh

# Single test suite
./scripts/tests/test-check-file-size.sh

# Exit code: 0 if all pass, 1 if any fail
```

## Test File Organization

**Location:**
- Colocated with implementation: `<module>/scripts/tests/test-*.sh`
- Fixtures in same directory: `<module>/scripts/tests/fixtures/*.md`
- Example structure:
  - `consolidator/scripts/archive.sh` → `consolidator/scripts/tests/test-consolidator.sh`
  - `consolidator/scripts/tests/fixtures/LEARNINGS-mini.md`
  - `consolidator/scripts/tests/fixtures/BLOCKERS-mini.md`

**Naming:**
- Test file: `test-<module>.sh` or `test-<script>.sh`
- Fixture files: realistic data in expected format (e.g., `LEARNINGS-mini.md` = reduced real LEARNINGS.md)

**Structure:**
```
consolidator/
├── scripts/
│   ├── archive.sh
│   ├── reindex.sh
│   ├── detect-duplicates.sh
│   ├── detect-promotions.sh
│   └── tests/
│       ├── test-consolidator.sh
│       ├── fixtures/
│       │   ├── LEARNINGS-mini.md
│       │   └── BLOCKERS-mini.md
```

## Test Structure

**Suite Organization (example from test-consolidator.sh):**
```bash
#!/usr/bin/env bash
# Header comment: describe all tests
# Usage: ./test-consolidator.sh
# Exit code: 0 if all tests pass, 1 if any fail

set -uo pipefail

cd "$(dirname "$0")/../.."  # Move to module root

FIXTURES_DIR="scripts/tests/fixtures"
WORK_DIR="$(mktemp -d)"
trap "rm -rf $WORK_DIR" EXIT  # Cleanup on exit

# Setup: copy fixtures into isolated memory dir
mkdir -p "$WORK_DIR/.claude/memory"
cp "$FIXTURES_DIR/LEARNINGS-mini.md" "$WORK_DIR/.claude/memory/LEARNINGS.md"

PASS=0; FAIL=0

# Define assert function
assert() { ... }

# Run test groups with section headers
echo "=== T1 — reindex.sh --audit détecte gaps ==="
output=$(cd "$WORK_DIR" && MEMORY_DIR=".claude/memory" "$WORK_DIR/.claude/scripts/reindex.sh" --register=LEARNINGS --audit 2>&1)
assert "T1.1 — LEARNINGS index_count" "$output" '"index_count": 4'
assert "T1.2 — LEARNINGS body_count" "$output" '"body_count": 3'

echo ""
echo "=== BILAN ==="
echo "PASS : $PASS / FAIL : $FAIL"
[ "$FAIL" -eq 0 ]  # Exit with appropriate code
```

**Patterns:**
- **Setup**: Create isolated work directory with `mktemp -d`, trap cleanup
- **Fixtures**: Copy realistic data (not mocked) into temp environment
- **Isolation**: Each test runs in subprocess with `cd` or env var override
- **Teardown**: Use `trap` to clean up on exit or test failure

## Mocking

**Framework:** No mocking library (Bash has none; Python tests call real scripts via subprocess)

**Patterns:**
- **Environment override**: Use env vars to redirect paths (e.g., `MEMORY_DIR=".claude/memory"` redirects where scripts look for registries)
- **Fixture data**: Create minimal but realistic files (e.g., `LEARNINGS-mini.md` with 4 entries instead of full 100+)
- **Subprocess execution**: Tests call actual scripts as black boxes, validate exit codes + output
- **File system isolation**: Each test suite gets its own `$WORK_DIR` via `mktemp -d`

**What to Mock:**
- File system paths: use env vars to redirect (e.g., `$MEMORY_DIR`, `$ARCHIVE_DIR`)
- Timestamps: fixture files use fixed dates (2026-01-01) so tests don't depend on clock

**What NOT to Mock:**
- Core script logic (test real script, not extracted functions)
- External CLI tools (python3, awk, grep, sed — test integration)
- File I/O (use real files in temp directory)

## Fixtures and Factories

**Test Data (observed patterns):**

Example fixture (`consolidator/scripts/tests/fixtures/LEARNINGS-mini.md`):
```markdown
## Index

| ID | Date | Titre | #Ligne |
|----|------|-------|--------|
| LRN-001 | 2026-01-01 | Premier learning fixture | 8 |
| LRN-002 | 2026-01-02 | Toujours valide operationnel | 20 |
| LRN-003 | 2026-01-03 | Learning orphelin sans body | 30 |
| LRN-004 | 2026-01-04 | Dernier learning | 40 |

## LRN-001 : Premier learning fixture

**Date** : 2026-01-01
**Resume** : Debut fixture

Body content...

## LRN-001 : Doublé (collision)

**Date** : 2026-01-01
Body content (duplicate ID)...

## LRN-002 : Toujours valide operationnel

**Date** : 2026-01-02
Body content with operational keywords...

## LRN-004 : Dernier learning

**Date** : 2026-01-04
Body content...
```

**Location:**
- `<module>/scripts/tests/fixtures/` directory
- Named to match real register files (LEARNINGS-mini.md, BLOCKERS-mini.md, etc.)
- Sized down but structurally complete (index + body sections)

**What Each Fixture Tests:**
- `LEARNINGS-mini.md`: index with gap (LRN-003 orphaned), collision (LRN-001 x2), mixed statuses
- `BLOCKERS-mini.md`: entries with archivable status (RÉSOLU) + active status (ACTIF)

**Factory Pattern:** None used (fixtures are static files, not generated)

## Coverage

**Requirements:** No enforced coverage target (no `coverage.py` or `nyc` config)

**View Coverage:**
- Manual: Count test cases in test-*.sh files
- Example (consolidator): 14 test cases across 6 test groups (T1–T6)
- Example (software-architecture): 4 test cases (small, focused suite)

**Coverage Goals (observed):**
- All major script modes (`--dry-run`, `--apply`, `--audit`, etc.) tested
- Edge cases: orphaned entries, collisions, old entries (age threshold)
- Integration: script chaining (consolidator runs all 4 pillars in sequence)

## Test Types

**Unit Tests:**
- Scope: Single script in one mode (e.g., `reindex.sh --audit`)
- Approach: Isolated temp directory, fixtures as input, assert on stdout JSON or exit code
- Example: `assert "T1.1 — LEARNINGS index_count" "$output" '"index_count": 4'`

**Integration Tests:**
- Scope: Multi-step workflows (e.g., reindex → archive → detect-promotions)
- Approach: Sequential script calls in same temp environment, validate state changes
- Example (from consolidator): reindex + detect-duplicates + detect-promotions in same test session
- Not explicitly separate from unit tests (all in `test-consolidator.sh`)

**E2E Tests:**
- Framework: Not used (project is modules distributed to labs, not deployed services)
- Alternative: Lab VibeFlow used as guinea pig for validation before releases
- Reference: "Validé en production" sections in CHANGELOG.md (e.g., `consolidator/CHANGELOG.md`)

## Common Patterns

**Async Testing:**
```bash
# Fire script in background, poll for output
.claude/scripts/archive.sh --async --apply &
sleep 1
[ -f "$MEMORY_DIR/.lock" ] && echo "lock acquired (expected)" || echo "lock missing (error)"
wait  # Wait for background job
```

**Error Testing:**
```bash
# Capture exit code and stderr
output=$(./.../script.sh --invalid-flag 2>&1)
exit_code=$?
assert "script rejects invalid flag" "$exit_code" "1"
assert "error message mentions flag" "$output" "unrecognized flag"
```

**JSON Output Testing:**
```bash
# Scripts output JSON on stdout, assert on parsed values
output=$(script.sh --audit 2>&1)
assert "key exists" "$output" '"index_count": 4'  # substring match
# For strict validation, pipe through `jq` if available
echo "$output" | jq '.index_count' | grep -q '^4$'
```

**Exit Code Testing:**
```bash
# Some tests validate exit codes directly
bash script.sh >/dev/null 2>&1
[ $? -eq 0 ] && echo "pass" || echo "fail"
```

## Regression Tests

**Specific Examples:**

1. **LRN-106 regression (consolidator)**
   - Issue: `reindex.sh --apply` deleted orphaned entries (broken in earlier version)
   - Test (T3): Verify orphelins are preserved after apply
   - Fixture: `LEARNINGS-mini.md` with LRN-003 orphaned (in index, no body)
   - Assert: `assert "T3.2 — LRN-003 (orphelin) toujours dans index" "$orphan_line" "LRN-003"`

2. **BLK-005 known bug (consolidator)**
   - Status: Documented in CHANGELOG as "32 LRN orphelins... to complete later"
   - Test: Not blocked (regression test acknowledges the debt)

3. **Version drift (infrastructure-audit)**
   - Test: `audit-infra.sh --quick` validates Claude Code version vs whitelist
   - Prevents silent failures from Anthropic updates

## Test Execution

**Command Line:**
```bash
# From module root
./scripts/tests/test-consolidator.sh
./scripts/tests/test-check-file-size.sh

# From .planning/codebase perspective, referenced paths are:
# consolidator/scripts/tests/test-consolidator.sh
# software-architecture/scripts/tests/test-check-file-size.sh
```

**Output Format:**
- Test results printed to stdout (not logged to file)
- Summary line: `BILAN : 14 PASS / 0 FAIL / 14 tests`
- Exit code: 0 (pass), 1 (fail)

**CI/CD Integration:**
- No CI pipeline detected (vibeflow-os is a module distribution repo, not deployed)
- Module releases manually tested in Lab VibeFlow before GitHub release
- Pre-release gate: all `scripts/tests/test-*.sh` must pass

---

*Testing analysis: 2026-06-04*
