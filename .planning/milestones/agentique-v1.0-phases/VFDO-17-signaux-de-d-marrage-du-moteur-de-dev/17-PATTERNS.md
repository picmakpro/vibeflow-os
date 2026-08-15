# Phase 17: Signaux de démarrage du moteur de dev - Pattern Map

**Mapped:** 2026-07-27
**Files analyzed:** 9 (5 created, 4 modified)
**Analogs found:** 9 / 9 (no analog for git-log heuristic — flagged below)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `plugin/dev-orchestrator/scripts/check-dev-bootstrap.sh` | utility (SessionStart hook script) | request-response (fact-check → stdout/exit) | `plugin/planning-core/scripts/detect-planning-debt.sh` (find/prune, exit contract) + `plugin/dev-orchestrator/scripts/discover-unintegrated-docs.sh` (env override, CLI loop, `say()`, mktemp+trap) | exact (composite) |
| `plugin/dev-orchestrator/scripts/check-doc-drift.sh` | utility (SessionStart hook script) | request-response | same composite analog; no git-shelling-out precedent exists in `plugin/**/scripts/*.sh` (see "No Analog Found") | role-match, partial on git usage |
| `plugin/dev-orchestrator/hooks/hooks.json` | config | event-driven | `plugin/planning-core/hooks/hooks.json` | exact |
| `plugin/dev-orchestrator/scripts/tests/test-check-dev-bootstrap.sh` | test | batch (fixture-driven assertions) | `plugin/dev-orchestrator/scripts/tests/test-discover-unintegrated-docs.sh` | exact |
| `plugin/dev-orchestrator/scripts/tests/test-check-doc-drift.sh` | test | batch | `plugin/dev-orchestrator/scripts/tests/test-discover-unintegrated-docs.sh` | exact |
| `plugin/dev-orchestrator/scripts/discover-unintegrated-docs.sh` (modified, `--hook` flag) | utility | request-response | itself (additive, in-file precedent) | exact |
| `plugin/dev-orchestrator/scripts/tests/test-discover-unintegrated-docs.sh` (modified, cases 17+) | test | batch | itself (cases 1-16 are the template for cases 17+) | exact |
| `plugin/dev-orchestrator/AGENT.md` (modified) | doctrine/config (agent frontmatter file) | transform (routing table insertion) | itself — "Amont & cadrage" table (lines 51-64) as the table-insertion model | exact |
| `plugin/dev-orchestrator/README.md`/`CHANGELOG.md`/`VERSION`/`module.json` (release-meta) | config | batch | `plugin/dev-orchestrator/CHANGELOG.md`/`README.md` prior entries (v2.4.0 → v2.5.0 precedent from phase 13's v2.1.1 → v2.2.0 bump) | exact |

## Pattern Assignments

### `plugin/dev-orchestrator/scripts/check-dev-bootstrap.sh` (utility, request-response)

**Analogs:** `plugin/planning-core/scripts/detect-planning-debt.sh` (find/prune + exit contract) and `plugin/dev-orchestrator/scripts/discover-unintegrated-docs.sh` (env override, arg loop, say(), mktemp/trap).

**Shebang + header doc comment convention** (`detect-planning-debt.sh:1-23`, `discover-unintegrated-docs.sh:1-41`):
```bash
#!/usr/bin/env bash
# <script-name> — <one-line question the script answers>
#
# Rôle (ADR-055 §3) : répondre au FAIT, jamais au métier. ...
#
# Usage:
#   <script-name> [--path <dir>] [--quiet]
# Defaults: --path .
#
# Env (surcharge — testabilité, modèle VF_INGEST_* de discover-unintegrated-docs.sh):
#   VF_BOOTSTRAP_PLANNING_DIR (défaut <path>/.planning)
#
# Exit codes:
#   0  = ...
#   3  = ...
#   64 = argument inconnu
set -uo pipefail
shopt -s nullglob
```

**CLI arg-parsing loop** (`discover-unintegrated-docs.sh:48-60`):
```bash
ROOT="."
QUIET=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --path)
      if [ "$#" -lt 2 ]; then
        echo "[discover-unintegrated-docs] --path nécessite une valeur" >&2
        exit 64
      fi
      ROOT="$2"; shift 2 ;;
    --quiet) QUIET=1; shift ;;
    -h|--help) grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
    *) echo "[discover-unintegrated-docs] argument inconnu : $1" >&2; exit 64 ;;
  esac
done
```
For `check-dev-bootstrap.sh`, add `--hook` alongside `--path`/`--quiet` and gate `--hook`+`--quiet` together → exit 64 (D-05/D-06 pattern, see discover-unintegrated-docs `--hook` extension below).

**`say()` helper** (`discover-unintegrated-docs.sh:68`):
```bash
say() { [ "$QUIET" -eq 1 ] || echo "[discover-unintegrated-docs] $*" >&2; }
```
Rename prefix to `[check-dev-bootstrap]`. Note: `detect-planning-debt.sh:42` uses the same helper but echoes to stdout (not stderr) — `discover-unintegrated-docs.sh`'s stderr variant is the correct analog since `check-dev-bootstrap.sh` must keep stdout reserved for the signal line only.

**`PRUNE_VENDOR` find-prune pattern — copy verbatim, then extend** (`detect-planning-debt.sh:49-54`):
```bash
# --- find borné : élaguer les dossiers vendorés/générés AVANT la descente (-prune, pas filtre post).
# POURQUOI : un node_modules réel = des dizaines de milliers de fichiers → gel du SessionStart
# (hook tué au timeout) ...
# Expansion NON quotée voulue aux sites d'appel (mots fixes sans espace, `(` passé en argument à find).
PRUNE_VENDOR='( -type d ( -name .git -o -name node_modules -o -name .venv -o -name vendor -o -name dist -o -name build -o -name .next ) ) -prune'
```
D-02 requires extending this list with `docs/`, `.planning/`, `.claude/` for this script specifically (these three don't count as "source code" per spec §3.1). Keep the exact `-type d (...) -prune` shape and the unquoted-expansion comment.

**Early-exit `head -n 1` existence check (no exhaustive counting)** (`detect-planning-debt.sh:79-82`):
```bash
# 1. Actif ? — O(1) : l'EXISTENCE d'un fichier modifié dans la fenêtre suffit,
#    head -n 1 stoppe find au premier trouvé (aucun stat spawné par fichier).
recent=$(find "$dir" $PRUNE_VENDOR -o -type f -mtime -"$ACTIVE_WINDOW" -print 2>/dev/null | head -n 1)
[ -n "$recent" ] || continue
```
Apply the same `find $PRUNE_VENDOR -o -type f -print | head -n 1` idiom for "at least one non-pruned file exists" (D-02's single-file-suffices contract).

**Env override pattern** (`discover-unintegrated-docs.sh:30-33,62-64`):
```bash
# Env (surcharge — testabilité, modèle VF_GSD_SKILLS_DIR de build-gsd-index.sh) :
#   VF_INGEST_SOURCES_DIR   (défaut <path>/docs/superpowers) — racine contenant specs/ et plans/
#   VF_INGEST_PLANNING_DIR  (défaut <path>/.planning)        — racine des registres GSD
...
SOURCES_ROOT="${VF_INGEST_SOURCES_DIR:-$ROOT/docs/superpowers}"
PLANNING_DIR="${VF_INGEST_PLANNING_DIR:-$ROOT/.planning}"
```
Copy directly for `VF_BOOTSTRAP_PLANNING_DIR="${VF_BOOTSTRAP_PLANNING_DIR:-$ROOT/.planning}"`.

**mktemp + trap idiom** (`discover-unintegrated-docs.sh:77-80`):
```bash
DOCS_TMP="$(mktemp)" || { echo "[discover-unintegrated-docs] mktemp a échoué" >&2; exit 64; }
REG_TMP="$(mktemp)" || { echo "[discover-unintegrated-docs] mktemp a échoué" >&2; rm -f "$DOCS_TMP"; exit 64; }
OUT_TMP="$(mktemp)" || { echo "[discover-unintegrated-docs] mktemp a échoué" >&2; rm -f "$DOCS_TMP" "$REG_TMP"; exit 64; }
trap 'rm -f "$DOCS_TMP" "$REG_TMP" "$OUT_TMP"' EXIT
```
Chain each `mktemp` failure with cleanup of prior temps, single `trap ... EXIT` at the end — this satisfies SC5 (D-15, no stray writes) and D-13.2 portability requirement.

**Multi-branch state machine — no direct analog exists (novel to this script)** for the 4-state continuum (D-01). Model it as sequential `if`/`elif` guarded early-returns in the same style as `detect-planning-debt.sh`'s single `if debt_found` gate, but chained for 4 states — write this branch fresh, following D-01 through D-04 in `17-CONTEXT.md`.

**Signal line format** (verbatim from spec §4.1, `docs/superpowers/specs/2026-07-27-signaux-demarrage-dev-design.md:200-211`):
```
[bootstrap] Projet initialisé, démarrage inachevé : config.json absent, codebase non cartographié.
            → propose gsd-config puis gsd-map-codebase (confirmation requise).
[onboard]   Code présent, aucun .planning/ — projet non cadré.
            → propose gsd-onboard (confirmation requise).
[gsd-engine] Projet piloté par GSD — milestone <milestone>, phase <current_phase> <état dérivé>.
             → cadrage : gsd-discuss-phase · plan : gsd-plan-phase · état : gsd-progress.
```

---

### `plugin/dev-orchestrator/scripts/check-doc-drift.sh` (utility, request-response)

**Analog:** same composite as above for shebang/header/arg-loop/say()/mktemp+trap/exit contract (64/3/0). No exit-1 branch exists (D-15).

**No git-shelling-out precedent found in `plugin/**/scripts/*.sh`.** Grep across `plugin/` for `git log`/`git rev-list`/`git rev-parse` in non-test scripts returned zero hits — this script is the first to shell out to git in this module family. Write the git usage from scratch following D-07/D-08/D-09:
- `git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1 || { say "not a git repo"; exit 3; }` (D-09).
- Count commits touching source since last doc-touching commit — use `git -C "$ROOT" log --oneline -- . ':!docs' ':!README*'` style pathspec exclusions, or two-step: find last commit touching `docs/**` or root `README*`, then `git rev-list --count <that-sha>..HEAD -- <source-paths>`.
- Threshold comparison: `[ "$count" -ge "$THRESHOLD" ]` → signal, else silence exit 3 (same shape as `detect-planning-debt.sh`'s `[ "$files" -ge "$MIN_TASKS" ]` early-exit gate at line 77).

**CLI flags to add**: `[--path <dir>] [--threshold <N>] [--hook] [--quiet]`, default `--path .  --threshold 20`. Same `--hook`+`--quiet` mutual exclusion gate as `check-dev-bootstrap.sh` (D-09, checked before any other logic — same position as the existing `--path` no-value gate in `discover-unintegrated-docs.sh:51-54`).

---

### `plugin/dev-orchestrator/hooks/hooks.json` (config, event-driven)

**Analog:** `plugin/planning-core/hooks/hooks.json` (verbatim structural model).

**Full structural model** (`plugin/planning-core/hooks/hooks.json:1-18`, `SessionStart` block only — ignore `UserPromptSubmit`/`Stop`, not needed for this module):
```json
{
  "description": "<one paragraph, cites relevant ADRs, explains advisory-not-blocking nature>",
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [
          { "type": "command", "command": "bash {{VF_SCRIPTS}}/<script>.sh || true" }
        ]
      }
    ]
  }
}
```

**Target content (already fixed verbatim by spec §3.4, D-10 — copy exactly, no redesign):**
```json
{
  "description": "Signaux de démarrage du moteur de dev : état du bootstrap projet, documents de cadrage orphelins de la feuille de route, dérive documentaire. Advisory (ADR-031) — chaque signal propose un geste, aucun ne l'exécute.",
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [
          { "type": "command", "command": "bash {{VF_SCRIPTS}}/check-dev-bootstrap.sh --hook || true" },
          { "type": "command", "command": "bash {{VF_SCRIPTS}}/discover-unintegrated-docs.sh --hook || true" },
          { "type": "command", "command": "bash {{VF_SCRIPTS}}/check-doc-drift.sh --hook || true" }
        ]
      }
    ]
  }
}
```
`{{VF_SCRIPTS}}` placeholder resolved by the engine at install (`plugin/_internal/vibeflow-update.sh` `merge_module_hooks`) — no engine change required, confirmed by CONTEXT.md D-10.

---

### `plugin/dev-orchestrator/scripts/tests/test-check-dev-bootstrap.sh` and `test-check-doc-drift.sh` (test, batch)

**Analog:** `plugin/dev-orchestrator/scripts/tests/test-discover-unintegrated-docs.sh` — copy the harness verbatim, only the fixtures/cases change.

**Harness header + helpers** (lines 1-24):
```bash
#!/usr/bin/env bash
# test-<script>.sh — Suite de vérification de <script>.sh (...)
#
# Un cas par piège (N assertions). Fixtures isolées via mktemp -d + --path, jamais sur le repo réel.

set -uo pipefail

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/<script>.sh"

PASS=0; FAIL=0
ok() { echo "  ✓ $1"; PASS=$((PASS+1)); }
ko() { echo "  ✗ $1 — $2"; FAIL=$((FAIL+1)); }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Prépare un socle minimal ... sous $TMP/<name>.
mk_root() { # <name> -> imprime le chemin
  local d="$TMP/$1"
  mkdir -p "$d/..."
  printf '%s' "$d"
}

echo "== test-<script> =="
```

**Numbered case block pattern** (lines 28-34, repeated per case):
```bash
# === Cas N — <description of the trap being tested> ======================
D="$(mk_root cN)"
<setup fixture files>
out="$(bash "$SCRIPT" --path "$D" [flags])"; rc=$?
if [ "$rc" -eq <expected> ] && [ ... ]; then ok "N <desc>"; else ko "N <desc>" "rc=$rc out=[$out]"; fi
```

**Footer / exit contract** (lines 148-150):
```bash
echo ""
echo "== résultat : $PASS ok, $FAIL ko =="
[ "$FAIL" -eq 0 ]
```

For `test-check-dev-bootstrap.sh`: per D-14, must include a **dedicated case** that positively asserts state 3 (`[gsd-engine]`) produces BOTH non-empty stdout AND exit 3 — do not combine into a single `[ "$rc" -eq 3 ] && [ -z "$out" ]` assertion pattern (that pattern is correct for states 0, but state 3 is the exception and needs `[ -n "$out" ]`). Also needs isolated fixtures per state to prove mutual exclusion (SC2) — one fixture per state, asserting no other signal string appears in `$out`.

For `test-check-doc-drift.sh`: fixtures need `git init` + scripted commits inside `mk_root`-created dirs (new territory — no existing test fixture in this module inits a real git repo; build this by extending `mk_root` with `git -C "$d" init -q && git -C "$d" -c user.email=t@t -c user.name=t commit ...`).

---

### `plugin/dev-orchestrator/scripts/discover-unintegrated-docs.sh` (modified, additive `--hook`)

**Insertion points** (read in full above, 142 lines):
- Arg loop (lines 48-60): add `--hook` case setting `HOOK=1`, and the `--hook`+`--quiet` mutual-exclusion gate immediately inside the loop at the same position as the existing `--path` no-value gate (lines 51-54) — i.e. gate before any other logic, matching D-06's "même position que le gate --path".
- Output branch (lines 139-142, currently `[ "$QUIET" -eq 1 ] && exit 0` then `LC_ALL=C sort "$OUT_TMP"; exit 0`): add a new branch before the existing sort/print — if `HOOK=1`, count grains (`awk -F'\t' '{c[$1]++} END{...}'` or simple `grep -c`) and print the aggregated line `[docs-ingest] N documents de cadrage hors feuille de route (X spec, Y plan).\n            → propose l'ingestion (...)`. Do not touch the non-hook path at all (contract frozen per D-06).
- Exit codes unchanged (0/3/64) in all branches, including `--hook`.

### `plugin/dev-orchestrator/scripts/tests/test-discover-unintegrated-docs.sh` (modified, cases 17+)

**Numbering continues directly from case 16** (lines 139-146 are the last existing case). New cases (17+) follow the exact same block shape shown above — one for `--hook` aggregate line content, one for `--hook`+`--quiet` → exit 64, one for `--hook` preserving exit 0/3 semantics unchanged.

---

### `plugin/dev-orchestrator/AGENT.md` (modified, doctrine table insertion)

**Analog (in-file):** the "Amont & cadrage" table itself (`AGENT.md:51-64`):
```markdown
### Amont & cadrage

| Intention | Brique |
|---|---|
| réfléchis / conçois / et si on… (idée à travailler) | skill `superpowers:brainstorming` (ou `gsd-explore` si très floue) |
...
```
Insertion point confirmed: between "Next steps & hygiène documentaire" (ends line 109) and "Heuristiques de routage" (starts line 111). Insert as a level-2 heading `## Signaux de démarrage` with a 4-row table (`[bootstrap]`, `[onboard]`, `[gsd-engine]`, `[doc-drift]` — NOT `[docs-ingest]`, already covered by the existing Amont & cadrage row at line 63). Each row: signal → geste → mention of confirmation required (ADR-031), per D-11.

Current file is 168 lines, ceiling 250 (ADR-029) — 4-row table leaves ample margin.

---

### Release-meta (`VERSION`, `module.json`, `CHANGELOG.md`, `README.md`)

**Analog:** the module's own prior bump precedent (Phase 13: v2.1.1 → v2.2.0 minor, per CONTEXT.md "Established Patterns"). Read the current `VERSION`/`module.json`/`CHANGELOG.md`/`README.md` at execution time to get exact current strings (not re-read here to avoid redundant tool calls — CONTEXT.md confirms current state is v2.4.0). Bump: `2.4.0` → `2.5.0` in `VERSION` (raw string) and `module.json`'s `"version"` field; add a new dated `CHANGELOG.md` entry; update `README.md`'s Version line, Historique section, and Structure du module section to list `hooks/hooks.json` + the 2 new scripts + their tests.

## Shared Patterns

### Exit-code contract (0/3/64, never 1)
**Source:** `plugin/dev-orchestrator/scripts/discover-unintegrated-docs.sh` (header comment lines 38-41) and `plugin/planning-core/scripts/detect-planning-debt.sh` (header comment lines 20-23, though that one uses exit 1 — do NOT copy the exit-1 branch, SC5/D-15 forbids it for this phase's scripts).
**Apply to:** `check-dev-bootstrap.sh`, `check-doc-drift.sh` — never exit 1; unknown arg → 64; nothing to report → silence + 3 (except the `[gsd-engine]` state-3 exception); something to report → 0.

### `say()` stderr helper + `[script-name]` prefix
**Source:** `discover-unintegrated-docs.sh:68`
**Apply to:** both new scripts — keeps stdout reserved purely for the machine-readable/hook signal line.

### mktemp + single `trap ... EXIT` cleanup chain
**Source:** `discover-unintegrated-docs.sh:77-80`
**Apply to:** both new scripts, satisfies SC5 (D-15: no stray filesystem writes outside mktemp/stdout/stderr).

### `find ... -prune` before descent (never post-filter)
**Source:** `plugin/planning-core/scripts/detect-planning-debt.sh:49-54,79-82`
**Apply to:** `check-dev-bootstrap.sh`'s source-code detection (D-02) — copy `PRUNE_VENDOR` verbatim then extend with `docs/`, `.planning/`, `.claude/`.

### Env override for testability (`VF_<MODULE>_<KEY>`)
**Source:** `discover-unintegrated-docs.sh:30-33,62-64`
**Apply to:** `VF_BOOTSTRAP_PLANNING_DIR` in `check-dev-bootstrap.sh` (D-05).

### Test harness (PASS/FAIL counters, `ok`/`ko`, `mk_root`, numbered `# === Cas N ===` blocks, `mktemp -d` + `trap ... EXIT`)
**Source:** `plugin/dev-orchestrator/scripts/tests/test-discover-unintegrated-docs.sh` (whole file)
**Apply to:** `test-check-dev-bootstrap.sh`, `test-check-doc-drift.sh`, and the extension cases in `test-discover-unintegrated-docs.sh` itself.

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `check-doc-drift.sh`'s git-log heuristic (D-07/D-08) | utility (sub-component) | request-response | No existing `plugin/**/scripts/*.sh` shells out to `git log`/`git rev-list`/`git rev-parse` — verified via repo-wide grep (zero hits outside test/CI contexts). Write this logic fresh, following D-07/D-08/D-09 exactly and reusing only the generic portability idioms listed in CONTEXT.md D-13.2 (`mktemp`, `trap EXIT`, `LC_ALL=C sort`, POSIX awk, `set -uo pipefail`) — none of which are git-specific. |
| 4-state continuum branching in `check-dev-bootstrap.sh` (D-01) | utility (control flow) | request-response | No existing script in this module family implements a 4-branch mutually-exclusive state machine with differentiated exit codes per branch (closest, `detect-planning-debt.sh`, has a single binary gate). Write fresh per D-01-D-04, using the existing `if`/`say`/`exit` idioms as building blocks but not as a structural template. |

## Metadata

**Analog search scope:** `plugin/dev-orchestrator/scripts/`, `plugin/dev-orchestrator/scripts/tests/`, `plugin/dev-orchestrator/hooks/` (target: none, doesn't exist yet), `plugin/dev-orchestrator/AGENT.md`, `plugin/planning-core/scripts/`, `plugin/planning-core/hooks/`, repo-wide grep for `git log`/`git rev-list`/`git rev-parse` in `plugin/**/*.sh`.
**Files scanned:** 6 read in full (`2026-07-27-signaux-demarrage-dev-design.md`, `discover-unintegrated-docs.sh`, `test-discover-unintegrated-docs.sh`, `detect-planning-debt.sh`, `planning-core/hooks/hooks.json`, `dev-orchestrator/AGENT.md`), 1 partial (`test-dev-orchestrator.sh` header for T20 numbering context).
**Pattern extraction date:** 2026-07-27
