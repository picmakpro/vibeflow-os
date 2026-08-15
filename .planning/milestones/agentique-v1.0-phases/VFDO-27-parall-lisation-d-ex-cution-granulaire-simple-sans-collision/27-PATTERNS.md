# Phase 27: Parallélisation d'exécution — Pattern Map

**Mapped:** 2026-08-05
**Files analyzed:** ~24 (1 doctrine + 1 gitignore + 1 new file + 13-19 agent frontmatters + 1 script + 1 test suite + 1 config + 1 decision doc + 1 measure doc)
**Analogs found:** 8 / 8 categories (100% — every file category has a concrete analog in this repo)

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `plugin/conductor/references/team-kernel.md` (L64-68 edit) | config/doctrine (markdown) | transform (text correction) | same file, adjacent doctrine sections (self-analog) | exact — edit is surgical, in-file precedent for tone |
| `plugin/*/agents/*.md` (13-19 files, `isolation: worktree` frontmatter line) | agent frontmatter (config) | transform (metadata addition) | `plugin/conductor/scripts/check-agents.sh` (validator that already knows the field) + any existing agent `.md` frontmatter block | role-match — no prior agent PR added a field repo-wide, but the validator is the exact contract to satisfy |
| `.gitignore` (root, new entry) | config | transform (append) | existing `.gitignore` entries, esp. the `.planning/DRIVER.lock/` block (commented, reasoned) | exact — same file, same convention (comment above each entry) |
| `.worktreeinclude` (root, new file) | config | transform (allow-list) | `.gitignore` (closest local prose/format convention for a path allow/deny list); no local precedent for inverse-gitignore syntax | role-match — format inferred by analogy, not copied verbatim (research flags `[ASSUMED]`) |
| `plugin/conductor/scripts/dag.sh` (extend `ready`/new field) | CLI script (bash+python3 heredoc) | request-response (JSON emit) + event-driven (DAG state transitions) | same file — `status`/`mark`/`reopen` actions already follow the pattern to replicate | exact — in-file precedent, same script |
| `plugin/conductor/scripts/tests/test-dag.sh` | test | request-response (assert on stdout) | same file — T1-T10 blocks | exact — in-file precedent |
| `.planning/config.json` (`claude_orchestration.*` keys) | config | CRUD (read/write JSON) | existing top-level blocks (`parallelization`, `hooks`, `intel`) already in the file | exact — same file, same nesting convention |
| `27-0X-DECISION-claude_orchestration.md` (new, phase dir) | doctrine/decision doc | transform (written record) | `.planning/phases/VFDO-24-.../24-COLLISIONS.md` (decision-record format: status banner, verdict table, per-item sections) | exact — same repo convention for "activation or refusal, written" |
| `27-0X-MESURE-GAIN.md` (new, phase dir) | doctrine/measurement doc | transform (written method + results) | `24-COLLISIONS.md` again for structure; ADR-069 for "renvoi, pas copie" citation convention | role-match |

---

## Pattern Assignments

### `plugin/conductor/references/team-kernel.md` (doctrine, L64-68)

**Analog:** same file, surrounding sections (self-consistent doctrine style).

**Text to replace** (verified verbatim on disk, L64-68):
```
**La conséquence doctrinale, en une ligne :** sur ce runtime, le parallélisme **intra-étape** (les
vagues de plans d'une même étape, côté moteur) est **perdu**, et le parallélisme **inter-nœuds**
porté par la frontière `ready` de `vf-dev-manager` est le **seul effectif**. Notre couche
d'orchestration ne duplique donc pas celle du moteur : **elle est la seule qui parallélise
réellement**.
```

**Convention to preserve** (doctrine prose style used throughout this file — bold key terms, one-line "conséquence doctrinale" summary, footnote-style pointer to protocol docs rather than inline numbers): see the line immediately below in the same file —
```
Protocole complet, trois configurations, horodatages bruts et réserves de la mesure (la profondeur
2 → 3 n'a pas été mesurée) : `.planning/missions/2026-07-31-mesure-m2-dispatch-parallele.md` du
dépôt VibeFlow. **Renvoi, pas copie** — les chiffres ne se recopient pas d'ici, ils se relisent
là-bas.
```
Apply the same "renvoi, pas copie" convention when pointing to the new `dag.sh` capability (Livrable 3) — per RESEARCH.md recommendation, document that pointer in `mission-flow.md`, not inline here, to keep this edit surgical and disjoint from Livrable 3's files.

**Also update, same block** — the line that names the restoring mechanism, already partially correct nearby (L52-53 area, "Toute bascule sur la capability amont `claude_orchestration`..."), keep as-is; only the "perdu" → "éteint par défaut" substitution is in scope (D-04).

---

### `plugin/*/agents/*.md` (frontmatter, `isolation: worktree`)

**Analog:** `plugin/conductor/scripts/check-agents.sh` (the validator, already accepts the field) + existing frontmatter blocks.

**Frontmatter shape to extend** (`plugin/dev-orchestrator/agents/vf-coder.md:1-9`, worker/non-manager, group A candidate):
```yaml
---
name: vf-coder
description: ...
tools: Read, Write, Edit, Bash, Glob, Grep, Skill, Agent(...)
model: sonnet
effort: medium
memory: project
vf-internal: true
vf-mcp-consumer: true
---
```
Insert `isolation: worktree` as a new top-level key (validator only checks `isolation` value ∈ `{worktree}`, no ordering requirement — `check-agents.sh` excerpt below).

**Manager frontmatter shape** (`plugin/dev-orchestrator/agents/vf-dev-manager.md:1-8`, group B — do NOT apply mechanically, needs an explicit decision task per RESEARCH.md Q3):
```yaml
---
name: vf-dev-manager
description: ...
tools: Read, Write, Bash, Glob, Grep, Skill, AskUserQuestion, Agent(...)
model: opus
effort: high
memory: project
---
```

**Validator contract to satisfy** (`plugin/conductor/scripts/check-agents.sh`, `KNOWN` set and isolation check):
```python
KNOWN = {"name", "description", "tools", "disallowedTools", "model", "permissionMode",
         "maxTurns", "skills", "mcpServers", "hooks", "memory", "background", "effort",
         "isolation", "color", "initialPrompt", "vf-internal", "vf-mcp-consumer", "vf-mcp-tools"}
...
iso = fm.get("isolation")
if iso and iso != "worktree":
    errors.append(f"{base} : isolation invalide ({iso}) — seul worktree est admis")
```
`isolation` is optional (no "absent" error) — adding it is purely additive, no other agent needs to change.

**Group A (13 agents, apply mechanically):** `vf-coder`, `vf-crafter`, `vf-business-commercial`, `vf-business-delivery`, `vf-business-finance`, `vf-content-repurposer`, `vf-content-strategist`, `vf-content-writer`, `campaign-analyst`, `channel-strategist`, `copywriter-sequences`, `vf-app-fixer`, `vf-test-runner`.

**Group B (6 managers, needs explicit include/exclude decision task, not silent default):** `vf-business-manager`, `vf-content-manager`, `vf-design-manager`, `vf-dev-manager`, `vf-growth-manager`, `vf-test-orchestrator`.

---

### `.gitignore` (root)

**Analog:** same file, existing reasoned-entry convention (comment block above each addition).

**Excerpt to imitate** (verbatim, current `.gitignore`):
```
# Verrou de driver d'une mission d'équipe (conductor/scripts/driver-lock.sh) :
# état runtime local, jamais versionné — un lock committé bloquerait toute
# mission ultérieure sur les autres clones.
.planning/DRIVER.lock/
```
New entry should follow the same shape — a short comment explaining *why* it's runtime-local, then the path:
```
# Worktrees d'agents isolés (isolation: worktree, Phase 27) : arbre de travail
# éphémère par agent dispatché, jamais versionné.
.claude/worktrees/
```
Note: `.claude/` is **already** gitignored at root (`.claude/` line already present in `.gitignore`) — RESEARCH.md flags the exact subpath `.claude/worktrees/` as `[ASSUMED]` (A2, unverified on disk since 0 worktree exists yet). The planner/implementer should verify empirically once the first isolated agent runs, and may find the dedicated line is redundant with the existing blanket `.claude/` ignore (in which case document that fact instead of adding a no-op line).

---

### `.worktreeinclude` (root, new file)

**Analog:** no local precedent for this exact file; closest format-convention analog is `.gitignore` itself (gitignore-style path patterns, one per line, per RESEARCH.md's own inference `[ASSUMED — A1, BASSE confiance]`).

**Content to include, per RESEARCH.md's own audit** (`git status --ignored=matching -s` — 6 entries found):
```
# Mémoire persistante d'agent (memory: project) — critique, sans elle un worker
# en worktree isolé perd tout apprentissage accumulé.
.claude/agent-memory/
```
Exclude: `.bak` files (4 entries, no runtime reader identified) and `docs/reference/` (no reader identified — `[ASSUMED — A5]`, flag for verification rather than including speculatively, consistent with D-11 simple-before-complete).

**Antecedent to cite, not contradict:** `.planning/quick/260801-17w-isolation-multi-session/PLAN.md:75-77` (ADR-064 predecessor) explicitly refused to *build tooling* around `.worktreeinclude`, not to *create the content file* itself — cite this to preempt a false "revirement" reading.

---

### `plugin/conductor/scripts/dag.sh` (extend `ready` / add `stages` field)

**Analog:** same file — `status` action already computes and emits a derived, non-stored view (`frozen`), and `add`/`mark`/`reopen` already follow the emit-JSON-with-comment-above-key convention.

**Pattern to replicate — the `status` action's "derived field, always present, never a stale copy" convention:**
```python
if action == "status":
    counts = {}
    for n in nodes:
        counts[n["status"]] = counts.get(n["status"], 0) + 1
    frozen = sorted(
        ({"id": n["id"], "status": n["status"], "scope": n.get("scope", [])}
         for n in nodes if n["status"] != "done" and n.get("scope", [])),
        key=lambda f: f["id"],
    )
    emit({"file": file, "total": len(nodes), "counts": counts,
          "ready": [n["id"] for n in nodes if n["status"] == "ready"],
          "frozen": frozen})
    sys.exit(0)
```

**Current `ready` action to extend (additive, per RESEARCH.md recommendation — do not replace `ready`/`count`):**
```python
if action == "ready":
    frontier = [n["id"] for n in nodes if n["status"] == "ready"]
    emit({"ready": frontier, "count": len(frontier)})
    sys.exit(0)
```
Target shape (additive field `stages`, computed by shelling out to `gsd-tools claude-orchestration emit-workflow`, reading `summary.stagesByWave[0]`, degrading to the flat frontier if `gsd-tools`/`node` is unavailable — never crash `dag.sh ready`):
```python
if action == "ready":
    frontier = [n["id"] for n in nodes if n["status"] == "ready"]
    result = {"ready": frontier, "count": len(frontier)}
    stages = compute_disjoint_stages(nodes, frontier)  # new helper, shells out to gsd-tools
    if stages is not None:
        result["stages"] = stages
    emit(result)
    sys.exit(0)
```

**Field-tolerant-read convention already established in this file** (P-02, cite when reading `scope[]`):
```python
# Absent sur les DAG ecrits avant ce champ : toute lecture tolere l'absence, jamais
# d'acces direct a la cle (P-02).
```
Apply the same tolerance pattern when reading each node's `scope` to build the manifest for `emit-workflow` — `n.get("scope", [])`, never `n["scope"]`.

**Naming convention to respect (D-08):** whatever new field/flag is added must not collide semantically with `check-overlaps.sh` (third-party routing, ADR-057) or reuse "scope"/"overlap" alone as a new script name — RESEARCH.md recommends **not** creating a separate script, extending `dag.sh` itself instead (avoids the naming trap entirely).

---

### `plugin/conductor/scripts/tests/test-dag.sh`

**Analog:** same file, T1-T10 block structure and `assert`/`assert_not`/`assert_exit` helpers.

**Pattern to replicate exactly** (header + helpers, verbatim):
```bash
#!/usr/bin/env bash
# test-dag.sh — Suite de tests pour dag.sh (ADR-053, Pattern B)
#
# T1 init + add (ready/blocked selon deps) · T2 mark done promeut la frontière
# ...
set -uo pipefail
cd "$(dirname "$0")/../.."
SCRIPT="$(pwd)/scripts/dag.sh"

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT
F="$WORK_DIR/m.dag.json"

PASS=0; FAIL=0
assert()     { if [[ "$2" == *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: $3"; echo "     obtenu:  $2"; FAIL=$((FAIL+1)); fi; }
```

**Test case shape to add (per RESEARCH.md Wave 0 gap):** two `ready` nodes with overlapping `scope[]`, assert they land in *distinct* `stages` entries after the wiring — follow the exact `assert` call convention used by T1-T3:
```bash
echo "=== T11 — scope[] recouvrant → étages distincts ==="
"$SCRIPT" add --file="$F2" --id=X --step=code --scope=src/a.ts >/dev/null
"$SCRIPT" add --file="$F2" --id=Y --step=code --scope=src/a.ts >/dev/null
out=$("$SCRIPT" ready --file="$F2")
assert "T11.1 — X,Y dans des étages distincts" "$out" ...  # exact assertion TBD by planner
```

---

### `.planning/config.json` (`claude_orchestration.*`)

**Analog:** same file — existing sibling blocks `parallelization`, `hooks`, `intel` (verbatim, current state):
```json
  "parallelization": {
    "enabled": true,
    "plan_level": true,
    "task_level": false,
    "skip_checkpoints": true,
    "max_concurrent_agents": 3,
    "min_plans_for_parallel": 2
  },
  "hooks": {
    "context_warnings": true,
    "workflow_guard": true
  },
  "intel": {
    "enabled": true
  },
```
New block, same nesting/naming convention (per D-09/RESEARCH.md Q4a-Q4d — fail-closed BETA capability):
```json
  "claude_orchestration": {
    "enabled": true,
    "execution_backend": "auto"
  },
```
Insert alongside these sibling blocks, before `"project_code"` (current key order in file). Confirmed absent today (`claude_orchestration` re-verified absent from the file this session).

---

### `27-0X-DECISION-claude_orchestration.md` (new, phase dir — Livrable 4 written decision)

**Analog:** `.planning/phases/VFDO-24-.../24-COLLISIONS.md` — decision-record format used by this repo for "activation or written refusal" (GSDA-06/08/10 pattern cited by CONTEXT.md/RESEARCH.md).

**Structure to replicate** (verbatim excerpt of the format — status banner, verdict table, per-item sections with "Loi/Usage/Fondé sur/Proposition" or equivalent PASS/FAIL columns):
```markdown
# Phase 24 — Inventaire des collisions « GSD-first »

**Établi le :** ... · **Par :** ...
**Origine :** ...

> ## ⛔ STATUT DE CE DOCUMENT
>
> **Chaque entrée est une PROPOSITION, sauf deux.** ...

| # | Loi / ADR | Usage GSD contrarié | Fondé sur | Proposition |
|---|---|---|---|---|
| **C-1** | ... | ... | ... | **RÉVISÉE — ✅ APPLIQUÉE le ...** |
```
Adapt to Livrable 4's own PASS/FAIL criteria already drafted in RESEARCH.md §Q4d (3 PASS conditions, 3 FAIL conditions) — use the same "status banner at top + numbered criteria table + narrative per criterion" shape. On FAIL, follow "refus motivé et écrit" pattern (GSDA-06/08/10 precedent, not audited in this session but named as the repo's existing convention for dormant-capability refusals).

---

### `27-0X-MESURE-GAIN.md` (new, phase dir — Livrable 5 measurement method)

**Analog:** same `24-COLLISIONS.md` structural convention (status banner + explicit "what is measured vs not" distinction), plus ADR-069's citation convention ("renvoi, pas copie" — point to the raw data file rather than duplicating numbers inline), directly named by RESEARCH.md as the precedent to follow:
```
Protocole complet, trois configurations, horodatages bruts et réserves de la mesure (la profondeur
2 → 3 n'a pas été mesurée) : `.planning/missions/2026-07-31-mesure-m2-dispatch-parallele.md` du
dépôt VibeFlow. **Renvoi, pas copie** — les chiffres ne se recopient pas d'ici, ils se relisent
là-bas.
```
Required sections per D-10/D-13 (gravé chiffre = méthode + re-dérivable): baseline (before activation, clock time), measurement (after activation, clock time), explicit method, explicit statement that the 3.00× stage-compression ceiling (Phase 24) is **not** a clock-time gain — do not conflate.

**DAG-native sequencing (per RESEARCH.md):** if this phase models its own Livrable 5 tasks via `dag.sh`, use the existing `--deps=` mechanism to enforce baseline-before-measurement ordering — no new mechanism needed:
```bash
dag.sh add --file=F --id=baseline --step="chronométrer dispatch inline, ≥2 plans disjoints"
dag.sh add --file=F --id=mesure-apres --step="même volume sous claude_orchestration activé" --deps=baseline
```

---

## Shared Patterns

### Fail-closed activation (D-09, applies to Livrable 4)
**Source:** `~/.claude/gsd-core/bin/lib/claude-orchestration.cjs` `detectWorkflowBackend` (7 gates, first-failure-wins, cited verbatim by RESEARCH.md) — same repo-level pattern already used for `broken-windows`, `hooks.community` (Phase 24 dormant capabilities).
**Apply to:** `.planning/config.json` edit + the decision document — any gate failure must degrade to `inline`, byte-identical to current behavior, never a crash.

### Tolerant field reads on `dag.sh` nodes (P-02)
**Source:** `plugin/conductor/scripts/dag.sh` (comment at top of file, and `status` action's `n.get("scope", [])`).
**Apply to:** any new code in `dag.sh` reading `scope[]` per node for the Livrable 3 wiring — never `n["scope"]` directly, DAGs written before this capability existed must not break.

### "Renvoi, pas copie" for cited numbers (D-13)
**Source:** `plugin/conductor/references/team-kernel.md` (closing line of "Étage de parallélisme réellement effectif" section) and ADR-069.
**Apply to:** `27-0X-MESURE-GAIN.md`, `27-0X-DECISION-claude_orchestration.md`, and the corrected `team-kernel.md` passage — every number cited must point to its raw source, never be recopied as a bare fact.

### Written decision on capability activation/refusal (GSDA-06/08/10 pattern)
**Source:** `24-COLLISIONS.md` structure (status banner, explicit verdict per item, "PROPOSITION vs APPLIQUÉE" distinction).
**Apply to:** Livrable 4's decision artifact — PASS/FAIL criteria pre-written (already drafted in RESEARCH.md §Q4d), decision recorded regardless of outcome.

---

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `.worktreeinclude` (root, new) | config | transform | No file of this exact semantic (inverse-gitignore allow-list) exists anywhere in this repo or in `gsd-core` (`grep -rln worktreeinclude ~/.claude/gsd-core/` → empty, per RESEARCH.md). Syntax must be treated as `[ASSUMED]` gitignore-style and verified empirically at first use. |
| `dag.sh` → `gsd-tools claude-orchestration emit-workflow` shell-out | integration point | request-response (subprocess) | No prior `dag.sh` code shells out to `node`/`gsd-tools` — today it only invokes `python3`. This is a genuinely new dependency shape for this script; RESEARCH.md flags it explicitly as "reversibility: costly" and recommends a documented fallback to the flat frontier if `gsd-tools` is unreachable. |

---

## Metadata

**Analog search scope:** `plugin/conductor/scripts/`, `plugin/conductor/references/`, `plugin/*/agents/*.md` (25 files), `.planning/config.json`, `.gitignore`, `.planning/phases/VFDO-24-.../24-COLLISIONS.md`, `docs/ADR.md` (ADR-069 excerpt).
**Files scanned:** ~10 read directly (dag.sh full, test-dag.sh head, team-kernel.md full-ish, check-agents.sh targeted, 2 agent frontmatters, .gitignore full, config.json full, 24-COLLISIONS.md head).
**Pattern extraction date:** 2026-08-05
