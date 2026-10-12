# Phase VFDO-31: Manifeste d'install + dry-run — Pattern Map

**Mapped:** 2026-08-16
**Files analyzed:** 4 (2 modified engine scripts, 1 new test suite, 1 draft response — non-code)
**Analogs found:** 4 / 4 (all in-repo, no external analog needed — this phase is a pure internal refactor)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `plugin/_internal/vibeflow-update.sh` (write helper `vf_place`/`vf_record` + ~35 call-site migration + `--dry-run` flag + manifest read/diff/converge in `update_module`) | service/engine (self-modified) | CRUD + file-I/O | itself — `mark_installed` (115-124) is the exact atomic-write analog to copy | exact (same file, same conventions) |
| `plugin/_internal/merge-hooks.sh` (new plan-preview mode, regime B) | service/CLI script (self-modified) | file-I/O, transform | itself — existing `merge`/`remove` mode dispatch (46-60) is the analog for adding a third `plan` mode | exact |
| `plugin/_internal/tests/test-manifest.sh` (new) | test | integration (file-I/O assertions) | `plugin/_internal/tests/test-vibeflow-update.sh` (primary) + `plugin/_internal/tests/test-merge-hooks.sh` (secondary, for numbered-T convention and mutation-proof documentation style) | exact (explicitly designated in task brief) |
| Draft response to issue #20 (on-disk, never posted) | non-code artifact | N/A | none needed — free-form prose, no pattern to copy | n/a |

## Pattern Assignments

### `plugin/_internal/vibeflow-update.sh` — write helper (engine, CRUD/file-I/O)

**Analog:** itself, `mark_installed()` at lines 115-124.

**Atomic-write pattern to copy** (lines 115-124):
```bash
mark_installed() {
  local mod="$1"
  local version="$2"
  mkdir -p "$(dirname "$INSTALLED_REGISTRY")"
  touch "$INSTALLED_REGISTRY"
  # Remove old entry if exists
  grep -v "^$mod=" "$INSTALLED_REGISTRY" > "${INSTALLED_REGISTRY}.tmp" 2>/dev/null || true
  echo "$mod=$version" >> "${INSTALLED_REGISTRY}.tmp"
  mv "${INSTALLED_REGISTRY}.tmp" "$INSTALLED_REGISTRY"
}
```
This is the tmp-file-then-`mv` idiom D-31-02 mandates for the manifest ("patron `mark_installed` (115-124)"). The new helper must reproduce: `mkdir -p` on the parent dir, write to a `.tmp` sibling, `mv` into place — never write the target file directly.

**Logging convention to copy** (lines 30-31):
```bash
log() { echo "[vibeflow-update] $*" >&2; }
err() { echo "[vibeflow-update] ERROR: $*" >&2; exit 1; }
```
`log`/`err` are the only diagnostic channels today and both write to **stderr**. The new `--dry-run` plan output (D-31-05) must NOT use `log()` — it is a new stdout channel, modeled on `show_status` (898-914), the engine's only current stdout producer. Do not invent a third convention; either reuse `log()` verbatim for diagnostics or `printf`/`echo` un-prefixed to stdout for `[plan] ...` lines, matching `show_status`'s existing precedent.

**Flag pre-parse pattern to copy** (lines 41-65, `--scope` handling):
```bash
_positional=()
while [ "$#" -gt 0 ]; do
  case "$1" in
    --scope)
      [ "$#" -ge 2 ] || err "--scope nécessite une valeur (user|project|local)"
      VF_SCOPE="$2"
      shift 2
      ;;
    --scope=*)
      VF_SCOPE="${1#--scope=}"
      shift
      ;;
    *)
      _positional+=("$1")
      shift
      ;;
  esac
done
if [ "${#_positional[@]}" -gt 0 ]; then
  set -- "${_positional[@]}"
else
  set --
fi
```
D-31-06 mandates `--dry-run` parses "in the same pre-parse as `--scope`" — extend this exact `while`/`case` loop with a `--dry-run) DRY_RUN=1; shift ;;` branch (no `=value` form needed, it's a boolean flag), before `cmd="$1"` is set later in the file.

**Registry/version lookup pattern** (lines 106-113, `module_version_installed`) — same shape to copy for a `manifest_path_for()`/`read_manifest()` helper: guard on `[ -f "$FILE" ]`, fall back gracefully (`echo "—"` becomes "manifest absent, not an error" per D-31-07) rather than erroring.

**Write-site call pattern to migrate** — every one of the ~35 sites inside `install_module` (569-761, excerpted above lines 597-668 show the `mkdir -p` + `cp`/`cp -r` pairs) is the mechanical-refactor target. Example of the two regimes that must route through the new helper differently:
- File-by-file glob (natural manifest grain), e.g. lines 647-650 (rules):
```bash
if [ -d "$module_dir/rules" ]; then
  mkdir -p "$TARGET_ROOT/rules"
  cp "$module_dir/rules/"*.md "$TARGET_ROOT/rules/" 2>/dev/null || true
  log "  copied rules/ → $TARGET_ROOT/rules/"
fi
```
- Whole-directory `cp -r` (MUST be expanded file-by-file at manifest-write time per D-31-02), e.g. lines 605-612 (nested skills):
```bash
if [ -d "$module_dir/skills" ]; then
  for skill_dir in "$module_dir/skills/"*/; do
    [ -d "$skill_dir" ] || continue
    skill_name=$(basename "$skill_dir")
    mkdir -p "$TARGET_ROOT/skills/$skill_name"
    cp -r "$skill_dir"* "$TARGET_ROOT/skills/$skill_name/" 2>/dev/null || true
    log "  copied nested skill → $TARGET_ROOT/skills/$skill_name/"
  done
fi
```

**Exclusion case to preserve verbatim** — Type 4 doc module (lines 633-641) stays OUT of the manifest per D-31-03 but must still emit a `--dry-run` plan line (it's a real write):
```bash
if [ -d "$module_dir/content" ]; then
  local doc_target="docs/$mod"
  mkdir -p "$doc_target"
  cp -r "$module_dir/content/"* "$doc_target/" 2>/dev/null || true
  log "  copied content/ → $doc_target/ (doc module, hors TARGET_ROOT)"
fi
```

**Regime A indirect-write sites** (predicted exactly, enter manifest, sub-process not invoked in dry-run) — lines 682-689 and 697-704 show the pattern (`VF_INDEX_OUT=... bash "$TARGET_ROOT/scripts/build-gsd-index.sh"`), best-effort wrapped in `if ... then ... else log fallback fi`. The dry-run branch replaces the `bash "..."` call with the predicted output path announcement, never invoking the sub-process.

**Regime C indirect-write sites** (announced, not enumerated) — lines 720-726 (`ensure-design-deps.sh --quiet`) and the `seed_module_registres "$mod"` call at line 742 are the shape: best-effort, ignore exit code, log-only degradation. Dry-run must emit `[plan] ~ <target> (effet de <script>, contenu non énuméré)` instead of invoking them.

**Regime B delegation point** — line 758, `merge_module_hooks "$mod"` — this is where the engine calls into `merge-hooks.sh`; the dry-run branch must call `merge-hooks.sh` in its new `plan` mode instead of `merge`, never reimplement the merge simulation locally (D-31-04, "Don't Hand-Roll" table).

---

### `plugin/_internal/merge-hooks.sh` — add `plan` mode (regime B delegation)

**Analog:** itself, mode dispatch at lines 46-60.

**Mode dispatch + arg parsing pattern to copy** (lines 42-60):
```bash
set -euo pipefail

err() { echo "[merge-hooks] ERROR: $*" >&2; exit 1; }

MODE="${1:-}"
FRAGMENT="${2:-}"
SETTINGS=""
PREFIX=""
SETTINGS_LOCAL=""

[ -n "$MODE" ] && [ -n "$FRAGMENT" ] || { grep '^# ' "$0" | sed 's/^# //'; exit 1; }
case "$MODE" in merge|remove) : ;; *) err "mode inconnu : $MODE (attendu merge|remove)" ;; esac
[ -f "$FRAGMENT" ] || err "fragment introuvable : $FRAGMENT"

shift 2
while [ "$#" -gt 0 ]; do
  case "$1" in
    --settings)         [ "$#" -ge 2 ] || err "--settings nécessite une valeur"; SETTINGS="$2"; shift 2 ;;
    --settings=*)       SETTINGS="${1#--settings=}"; shift ;;
```
Add `plan` to the `case "$MODE" in merge|remove)` allowlist. The new mode reuses the exact same flag surface (`--settings`, `--scripts-prefix`, `--settings-local`) since D-31-05 requires the preview line to reflect the *real* merge target routing (project vs local), which only this parsing block already knows how to resolve.

**Error/diagnostic convention** (line 44): `[merge-hooks] ` prefix on stderr, same idiom as the engine's `log()`/`err()` — reuse verbatim for any new diagnostics inside `plan` mode; the new preview line itself goes to **stdout** to match D-31-05 (engine's `--dry-run` plan channel), not stderr.

**Existing delegation boundary already relied upon by the engine** — `merge_module_hooks`/`find_hooks_merger` at lines 351-408 of `vibeflow-update.sh` is the call site the engine already uses to invoke `merge-hooks.sh merge ...`; the dry-run branch adds a parallel call to `merge-hooks.sh plan ...` at the same call site, per D-31-04 regime B ("interdit : réimplémenter la logique de merge côté engine").

---

### `plugin/_internal/tests/test-manifest.sh` (new) — test suite

**Analog:** `plugin/_internal/tests/test-vibeflow-update.sh` (primary structural analog) + `plugin/_internal/tests/test-merge-hooks.sh` (secondary, for T-numbering/mutation-documentation convention).

**Header/pass-fail-skip scaffold to copy** (test-vibeflow-update.sh, lines 1-46):
```bash
#!/usr/bin/env bash
# test-manifest.sh — Suite de vérification du manifeste d'install + dry-run (Phase VFDO-31).
#
# Couvre MANI-01..04 + QUAL-01 :
#   T1 ... (describe each numbered test here, following the header-comment convention)
#
# Convention : asserts numérotés, helpers ok()/ko()/skip(), exit 0 si tout passe (SKIP non
# bloquant), exit 1 si au moins un KO. Calqué sur le pattern de test du repo.

set -uo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
INTERNAL_DIR="$(cd "$TESTS_DIR/.." && pwd)"
REPO="$(cd "$INTERNAL_DIR/.." && pwd)"
INSTALLER="$INTERNAL_DIR/vibeflow-update.sh"

pass=0; fail=0; skipped=0
ok()   { echo "  ✓ $1"; pass=$((pass+1)); }
ko()   { echo "  ✗ $1"; fail=$((fail+1)); }
skip() { echo "  ⊘ SKIP $1"; skipped=$((skipped+1)); }

GREP="$(command -v grep)"

echo "== test-manifest (engine: $INSTALLER) =="
```
Note: `set -uo pipefail` (no `-e`) — same as both existing suites, deliberate so a failing assertion doesn't abort the whole run before `ok`/`ko` tallying and the final exit-code decision.

**Isolation pattern to copy** (test-vibeflow-update.sh, lines 48-67): snapshot real `$HOME/.claude` before/after (`snapshot_home_claude`), and a `prepare_module()` helper that copies a real module from `$REPO` into a `mktemp -d` cache:
```bash
prepare_module() {
  local cache="$1" mod="$2"
  mkdir -p "$cache/$mod"
  cp -r "$REPO/$mod/." "$cache/$mod/" 2>/dev/null || return 1
  [ -f "$cache/$mod/VERSION" ] || return 1
  return 0
}
```
Reuse this verbatim for the manifest suite's fixtures — MANI-02's two required fixtures (regime-A/no-regime-C module for the exact dry-run==disk-diff equality test, and a regime-C-triggering module for the announce-line presence test) both need a real module copied into an isolated `LAB="$(mktemp -d)"` cache, exactly like T1-T5 in the existing suite (lines 69-80 show the `LAB`/`CACHE`/`FAKE_HOME` setup for T1).

**Per-test structure to copy** (test-vibeflow-update.sh T1, lines 69-80): each test block creates its own `LAB="$(mktemp -d)"`, runs the installer with `HOME=... VF_SCOPE=... VIBEFLOW_CACHE=...` env overrides, then asserts file existence/content with a local `miss=0` counter pattern before calling `ok`/`ko`.

**Numbered-T + mutation-documentation convention to copy** (test-merge-hooks.sh header, lines 1-80): every test gets a `# T<n> — <one-line what it proves>` comment in the file header before the code, and known architectural boundaries are documented inline as "attendu et documenté, pas une régression" (see T20b, lines 62-65) rather than silently passed. QUAL-01's mutation-red requirement (assertion + expected + actual trace) should be documented the same way this suite documents its edge cases — inline comments explaining exactly what a given assertion proves and why.

**Non-regression check to run alongside** (per RESEARCH.md Validation Architecture): `bash plugin/_internal/tests/test-vibeflow-update.sh && bash plugin/_internal/tests/test-merge-hooks.sh` must stay green before/after the ~35-site helper migration — treat both existing suites as the regression oracle for the mechanical refactor lot (D-31-01's "commit atomique... suite existante verte avant/après").

**CI discovery pattern (why no registration step is needed)**: `.github/workflows/ci.yml:210-237` discovers suites via `find plugin scripts -type f -path '*/tests/test-*.sh' | sort`. `test-manifest.sh` just needs the correct path/naming to be auto-discovered — no config file, no manual registration.

---

## Shared Patterns

### Atomic write (tmp + mv)
**Source:** `plugin/_internal/vibeflow-update.sh:115-124` (`mark_installed`)
**Apply to:** the new manifest-write helper (`vf_place`/`vf_record`), and any manifest-close-time sort/write (`LC_ALL=C sort` before the final `mv`, per D-31-02).

### Logging channel discipline (stderr diagnostics vs stdout product)
**Source:** `plugin/_internal/vibeflow-update.sh:30-31` (`log`/`err`, stderr) vs `show_status` at lines 898-914 (stdout, the engine's only current stdout producer)
**Apply to:** `--dry-run` plan output must go to stdout (D-31-05); all diagnostics/errors during dry-run still go through `log`/`err` on stderr. Same split applies inside `merge-hooks.sh`'s new `plan` mode (its own `err()` at line 44 is stderr; its new preview line is stdout).

### Best-effort sub-process wrapping (never amputate the pose)
**Source:** `plugin/_internal/vibeflow-update.sh:682-689, 697-704, 720-726` (three near-identical `if ... bash "$SCRIPT" ...; then log success; else log degraded; fi` blocks)
**Apply to:** regime A and regime C dry-run branches — same shape, but the `then` branch becomes "announce predicted path" (regime A) or "announce effect, unenumerated" (regime C) instead of invoking the sub-process at all.

### Flag pre-parse before `cmd="$1"`
**Source:** `plugin/_internal/vibeflow-update.sh:41-65` (`--scope` handling)
**Apply to:** `--dry-run` flag parsing (D-31-06) — same loop, same restore-positionals-via-`set --` idiom.

### CRLF/`\r` stripping at read time
**Source:** `plugin/_internal/vibeflow-update.sh:962` (existing pattern for `--with-deps`, per RESEARCH.md's Security Domain section — read directly if exact excerpt needed, not reproduced here since RESEARCH.md already cites the line)
**Apply to:** manifest read path (D-31-07's `\r`-residual-triggers-unparsable rule).

## No Analog Found

None. All four files in scope have an exact in-repo analog (three are self-referential — the phase modifies existing files following their own established conventions — and the new test suite has two explicit sibling suites to follow).

## Metadata

**Analog search scope:** `plugin/_internal/` (engine, `merge-hooks.sh`, `tests/`) — no search outside this directory was needed; RESEARCH.md and CONTEXT.md already pinned every relevant line number.
**Files scanned:** `plugin/_internal/vibeflow-update.sh` (partial, lines 1-135 + 569-768), `plugin/_internal/merge-hooks.sh` (partial, lines 1-60), `plugin/_internal/tests/test-vibeflow-update.sh` (partial, lines 1-80), `plugin/_internal/tests/test-merge-hooks.sh` (header, lines 1-80).
**Pattern extraction date:** 2026-08-16
