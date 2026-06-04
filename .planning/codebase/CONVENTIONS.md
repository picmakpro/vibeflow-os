# Coding Conventions

**Analysis Date:** 2026-06-04

## Naming Patterns

**Files:**
- Shell scripts: `lowercase-with-hyphens.sh` (e.g., `archive.sh`, `detect-duplicates.sh`, `check-file-size.sh`)
- Python scripts: `lowercase_with_underscores.py` (e.g., `utils.py`, `run_eval.py`, `package_skill.py`)
- Markdown documents: `UPPERCASE.md` (e.g., `SKILL.md`, `AGENT.md`, `CHANGELOG.md`)
- Module directories: `lowercase-with-hyphens` (e.g., `consolidator`, `infrastructure-audit`, `skill-creator`)
- Registered items: `CAPS-DIGITS` (e.g., `LRN-001`, `ADR-031`, `BLK-005`, `EVAL-002`)

**Functions (Shell):**
- `snake_case_with_underscores` for helper functions (e.g., `age_days()`, `in_allowlist()`, `is_archivable_status()`)
- Leading `_` for private/internal functions (e.g., `_call_claude()`)
- Descriptive action verbs: `scan_`, `detect_`, `extract_`, `ensure_`, `mark_`, `sync_`

**Functions (Python):**
- `snake_case_with_underscores` for all functions (e.g., `parse_skill_md()`, `should_exclude()`, `find_project_root()`)
- Leading `_` for private functions (e.g., `_call_claude()`)
- Descriptive verbs: `parse_`, `detect_`, `validate_`, `package_`, `run_`, `improve_`

**Variables:**
- Shell: `UPPER_WITH_UNDERSCORES` for environment variables and constants (e.g., `MEMORY_DIR`, `DRY_RUN`, `THRESHOLD_DAYS`, `LOCK_FILE`)
- Python: `lower_with_underscores` for local vars, constants as `UPPER_CASE` (e.g., `skill_path`, `EXCLUDE_DIRS`, `pending_tool_name`)
- Abbreviations allowed: `ts` (timestamp), `msg` (message), `val` (value), `ref` (reference), `ref` (references count)

**Types (Python):**
- Standard Python type hints: `str`, `Path`, `int`, `bool`, `tuple[str, str, str]`, `list[str]`, `dict[str, int]`
- Type hints on all function signatures (no implicit `Any`)

## Code Style

**Formatting:**
- No enforced formatter (`.prettierrc` or `eslintrc` absent in repo)
- Shell: 2-space indentation for nested blocks (bash `if`, `while`, `for`), 4-space for heredoc content
- Python: 4-space indentation (PEP 8 standard)
- Line length: no enforced limit, but keep shell scripts ≤120 chars where practical
- No trailing whitespace

**Linting:**
- No enforced linter configuration (no `.eslintrc`, no `pylint.conf`)
- Shell scripts use `set -euo pipefail` as standard (strict mode: exit on error, undefined variables, pipe failures)
- Python scripts start with `#!/usr/bin/env python3` (not `/usr/bin/python3`)

**Comments:**
- **Shell**: Use `# ------` section dividers for major logical blocks (e.g., `# ---------- Arg parsing ----------`, `# ---------- Helpers ----------`)
- **Python**: Use docstring for module-level and function documentation (triple quotes `"""`); inline comments prefixed with `#` for clarity

## Import Organization

**Order (Shell):**
1. Shebang: `#!/usr/bin/env bash`
2. File header comment block (purpose, usage, references)
3. `set -euo pipefail` (or `set -uo pipefail` if some commands must fail)
4. Variable declarations and defaults
5. Helper function definitions
6. Main logic

**Order (Python):**
1. Shebang: `#!/usr/bin/env python3`
2. Module docstring (triple quotes)
3. Standard library imports (`sys`, `os`, `json`, `pathlib`, etc.)
4. Third-party imports (none in vibeflow-os — no external dependencies)
5. Local imports (`from scripts.utils import`, `from .constants import`)

**Path Aliases:**
- Relative imports in Python: `from scripts.utils import parse_skill_md` (used in skill-creator modules)
- Absolute paths via `.vibeflow-cache` or `$MEMORY_DIR` environment variables in shell scripts

## Error Handling

**Patterns (Shell):**
- Exit immediately on first error: `set -euo pipefail`
- Explicit error logging: `err() { echo "[script-name] ERROR: $*" >&2; exit 1; }`
- Error messages to stderr: `>&2`
- Functions return 0 (success) or non-zero (failure) implicitly
- Lock-based safety: check and acquire `$LOCK_FILE` before destructive operations (see `archive.sh`)

**Patterns (Python):**
- Return tuple `(bool, str)` for validation: `valid, message = validate_skill(skill_path)`
- Explicit `None` returns for errors (see `package_skill()` returns `None` on error)
- Exceptions caught and printed with emoji prefix for user clarity: `❌ Error: ...`, `✅ Success: ...`
- File operations wrapped in try-except with user-friendly messages

## Logging

**Framework:** No centralized logging library. Mix of:
- Shell: `echo` to stderr with timestamp and module prefix (e.g., `[vibeflow-update] message`)
- Python: `print()` with emoji prefixes (`✅`, `❌`, `🔍`, `📦`)

**Patterns:**
- Timestamp format (shell): ISO 8601 `date -Iseconds` fallback to `date "+%Y-%m-%dT%H:%M:%S%z"`
- Log file output: append to `${LOG_FILE}` with `tee -a`
- Verbosity: log major transitions (start, scan, decision points), skip minor iterations
- Example (shell): `log "start (threshold=${THRESHOLD_DAYS}j, mode=$([ "$DRY_RUN" = true ] && echo dry-run || echo apply))"`

## Comments

**When to Comment (patterns observed):**
- **Section headers** (shell): `# ---------- Helpers ----------` for major logical blocks
- **Complex regex/awk**: explain intent before the command (e.g., "Extract IDs from body headers, count occurrences")
- **Non-obvious logic**: comment the "why" not the "what" (e.g., "macOS: stat -f %m, Linux: stat -c %Y")
- **Edge cases**: mark with trailing comment (e.g., `# Note: actual deletion requires careful handling`)

**No Comments On:**
- Simple variable declarations
- Single-line conditionals
- Sequential obvious steps

**JSDoc/TSDoc:** Not used (project is shell + Python, not TypeScript)

## Function Design

**Size (Shell):**
- Helper functions: 5-40 lines (keep single responsibility)
- Main logic: 100-150 lines max (break into helpers if longer)
- Awk blocks: inline within shell function (acceptable when awk does heavy lifting)

**Size (Python):**
- Helper functions: 10-30 lines
- Main functions: 30-100 lines
- Use pathlib.Path consistently; avoid os.path

**Parameters:**
- Shell functions take positional args: `function_name() { local arg1="$1" arg2="$2"; ... }`
- Python functions use keyword arguments where applicable: `run_single_query(query: str, skill_name: str, timeout: int, ...)`
- Avoid global variables (constants like `MEMORY_DIR` are acceptable)

**Return Values:**
- Shell: exit code (0 = success, 1+ = failure) OR output to stdout (e.g., JSON, counts)
- Python: explicit return type hints; prefer tuple returns for validation (bool, str); None for errors

## Module Design

**Exports (Shell):**
- Scripts are standalone executables (#!/usr/bin/env bash at top)
- Helper functions prefixed with underscore are "private"
- Main logic runs at bottom (after function defs)

**Exports (Python):**
- Scripts are callable with `python3 script.py` (main entry point via `if __name__ == "__main__"`)
- Modules export functions explicitly via `from scripts.utils import parse_skill_md`
- No `__all__` pattern; all public functions exposed

**Barrel Files:** Not used (no aggregator index files)

## Architectural Conventions

**ADR References:**
- All breaking/major changes accompany an ADR (Architecture Decision Record) ID
- Example: `# Reference ADR-032 pilier 2 (Archivage)` in shell scripts
- Scripts and skills document their ADR dependencies in headers/frontmatter

**Iron Law Patterns:**
- Documented in skill frontmatter and SKILL.md sections
- Example (consolidator): *"La lecture d'un registre = lecture de l'index uniquement par défaut"*
- Example (infrastructure-audit): *"Une infrastructure non auditée est une infrastructure qui dérive silencieusement"*
- Enforced via guards or validation scripts

**Frontmatter (YAML):**
- SKILL.md files use frontmatter block bounded by `---` on lines 1 and N
- Required fields: `name:`, `description:` (multiline via YAML block scalar `>` or `|`)
- AGENT.md adds: `model:`, `memory:`, `skills:` (list)
- Descriptions use French (language of the project codebase)

**Testing Conventions:**
- Test suites live in `scripts/tests/test-*.sh` colocated with implementation
- Fixtures in `scripts/tests/fixtures/` directory
- Each test is a numbered assert: `assert "T1.1 — description" "$actual" "$expected"`
- Exit code 0 = all tests pass, 1 = any fail

---

*Convention analysis: 2026-06-04*
