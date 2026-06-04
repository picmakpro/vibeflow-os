<!-- refreshed: 2026-06-04 -->
# Architecture

**Analysis Date:** 2026-06-04

## System Overview

VibeFlow-OS is a **modular distribution system** for reusable VibeFlow methodology components. It centralizes methodology artifacts (agents, skills, rules, references, scripts) and distributes them to labs via a version-controlled installer. The architecture is built on **semantic versioning**, **type-composable modules**, and **machine-enforced distribution**.

```text
┌────────────────────────────────────────────────────────────────┐
│              vibeflow-os Repository (Central)                  │
│              Versioned Module Library + Installer              │
├────────────────┬──────────────────┬───────────────┬───────────┤
│  Consolidator  │  Validator Agent │  Skill Creator│ Software  │
│  (v1.0.0)      │  (v1.1.0)        │  (v1.0.0)    │Architecture│
│  skill+scripts │  agent+skills    │  agent+2     │  (v1.0.0)  │
│                │                  │  skills      │ skill+rules│
└────────────────┴──────────────────┴───────────────┴───────────┘
                                      │
                    ┌─────────────────┴──────────────────┐
                    │                                    │
         ┌──────────▼─────────────┐      ┌──────────────▼──────────┐
         │  vibeflow-update.sh    │      │  Module Type Registry   │
         │  (Installer/Updater)   │      │  (Single-skill/Agent/   │
         │  `.vibeflow-cache/`    │      │   Doc-only/Rules/Multi) │
         └────────────┬───────────┘      └─────────────────────────┘
                      │
        ┌─────────────┴──────────────┬───────────────────┐
        │                            │                   │
        ▼                            ▼                   ▼
   ┌─────────────┐    ┌──────────────────┐   ┌──────────────────┐
   │   Lab A     │    │   Lab B          │   │   Lab N          │
   │ .claude/    │    │ .claude/         │   │ .claude/         │
   │  skills/    │    │  skills/         │   │  skills/         │
   │  agents/    │    │  agents/         │   │  agents/         │
   │  rules/     │    │  rules/          │   │  rules/          │
   │  scripts/   │    │  scripts/        │   │  scripts/        │
   └─────────────┘    └──────────────────┘   └──────────────────┘
```

## Component Responsibilities

| Component | Responsibility | File |
|-----------|----------------|------|
| `consolidator` | 4-pillar memory consolidation (indexing, archiving, fusion, promotion) | `consolidator/SKILL.md` |
| `infrastructure-audit` | Automated audit of Lab runtime, hooks, scripts, drift detection | `infrastructure-audit/SKILL.md` |
| `validator` | Master audit agent orchestrating 5 phases (infrastructure, density, debt, process audit, synthesis) | `validator/AGENT.md` |
| `skill-creator` | Sole authorized channel for skill creation; decomposes topic into facets + parallel research | `skill-creator/AGENT.md` + `skill-creator/skills/` |
| `software-architecture` | AI-safe code architecture doctrine (SOLID/SoC, ≤300L files, machine-enforced gates) | `software-architecture/SKILL.md` |
| `audit-architecture` | Designs multi-layer audit structures for any process (brief→output) | `audit-architecture/SKILL.md` |
| `reference` | Complete methodology documentation (Core v4.2, 9 principles, 11 patterns, 33 templates) | `reference/content/` |
| `vibeflow-update.sh` | Universal installer/updater for all module types; manages versions, backups, rollbacks | `_internal/vibeflow-update.sh` |

## Pattern Overview

**Overall:** Distributed Methodology Library with Type-Composable Modules

**Key Characteristics:**
- **Modular distribution** — Each skill/agent/doc is independently versioned and installable
- **Type polymorphism** — Modules declared by their content type (single-skill, multi-skill, agent-only, doc-only, rules)
- **Version isolation** — Each module has its own `VERSION` file; repo global version tags represent last major change
- **Idempotent installation** — `vibeflow-update.sh` is re-runnable; backups created before overwrites
- **Central-to-Lab pull model** — Labs pull from `.vibeflow-cache/` (git clone); never push back to central
- **Iron Law enforcement** — Each skill/agent encodes its own operational constraints (max density, consolidation cycles, audit scope)

## Layers

**Module Definition Layer:**
- Purpose: Declare what a module is (skill, agent, rules, doc) and what it contains
- Location: Each module root (`consolidator/`, `validator/`, etc.)
- Contains: `VERSION`, `CHANGELOG.md`, `README.md`, `SKILL.md` or `AGENT.md` or `content/`
- Depends on: None (self-contained)
- Used by: `vibeflow-update.sh` (type detection), Lab developers (reference)

**Distribution Layer:**
- Purpose: Detect module type and copy to correct location in target Lab
- Location: `_internal/vibeflow-update.sh`
- Contains: Install logic (5 type handlers), version registry logic, backup/rollback
- Depends on: Bash 4+, git, standard Unix tools (awk, grep, sed)
- Used by: Labs during `vibeflow-update.sh install|update|rollback`

**Methodology Layer:**
- Purpose: Define VibeFlow principles, patterns, and decision rules
- Location: `reference/content/methodology/` (VIBEFLOW_CORE.md, patterns/, templates/)
- Contains: 9 Core principles (P1-P9), 11 architectural patterns, 33 templates, vocabulary
- Depends on: None (documentation only)
- Used by: Lab designers, skill-creator, validator (for consistency checks)

**Skills Ecosystem Layer:**
- Purpose: Executable skills tied to specific VibeFlow principles (mostly P9, P8)
- Location: Each skill module root (`consolidator/SKILL.md`, `software-architecture/SKILL.md`, etc.)
- Contains: SKILL.md + bundled references/scripts/assets
- Depends on: Methodology (reference to ADRs/principles) + each other (validator delegates to skills)
- Used by: Agents (via skill tool), hooks (async invocation), CLI (manual execution)

**Agent Orchestration Layer:**
- Purpose: Coordinate multi-skill audits and repair recommendations
- Location: `validator/AGENT.md` (master) + `skill-creator/AGENT.md` (specialized)
- Contains: Frontmatter (model, memory, skills list) + procedures (5 phases, delegation rules)
- Depends on: Skills (listed in frontmatter), methodology (Iron Laws from reference)
- Used by: Labs at `/checkpoint`, periodically, or post-Claude-update

## Data Flow

### Primary Distribution Path (Install/Update)

1. **User invokes installer** (`./vibeflow-update.sh install <module>` or `update --all`) — `_internal/vibeflow-update.sh:1`
2. **Ensure cache exists** (git clone if needed) — `_internal/vibeflow-update.sh:28-33`
3. **Type detection** — Read `<module>/VERSION`, scan for `SKILL.md` / `AGENT.md` / `content/` / `rules/` — `_internal/vibeflow-update.sh:86-150`
4. **Backup existing** (if installed) → `.claude/.backups/` — `_internal/vibeflow-update.sh:99-103`
5. **Copy by type**:
   - **Single-skill**: `SKILL.md` → `.claude/skills/<mod>/` + `references/` — `_internal/vibeflow-update.sh:106-110`
   - **Multi-skill**: `skills/<name>/SKILL.md` → `.claude/skills/<name>/` — `_internal/vibeflow-update.sh:113-121`
   - **Agent**: `AGENT.md` → `.claude/agents/<mod>.md` — `_internal/vibeflow-update.sh:124-128`
   - **Doc**: `content/` → `docs/<mod>/` — `_internal/vibeflow-update.sh:131-136`
   - **Rules**: `rules/*.md` → `.claude/rules/` — `_internal/vibeflow-update.sh:139-143`
6. **Mark installed** in `.vibeflow-installed` registry — `_internal/vibeflow-update.sh:66-75`

### Primary Audit Path (Lab Health Check)

1. **User triggers `/checkpoint` or agent detects drift** — User prompt or scheduled hook
2. **vibeflow-validator agent loads** — `.claude/agents/vibeflow-validator.md` (Opus model, project memory)
3. **Phase 1 — Infrastructure audit** → delegates to `infrastructure-audit` skill
4. **Phase 2 — Agent density audit** → delegates to `agent-density-auditor` skill
5. **Phase 3 — Memory + debt audit** → delegates to `consolidator` + `dette-detector`
6. **Phase 4 — Process audit** → delegates to `audit-architecture` skill (scans lab processes)
7. **Phase 5 — Synthesis** → generates `reports/validator/YYYY-MM-DD-validator.md` (score 0-100, recommendations)

**State Management:**
- **Module state**: `.vibeflow-installed` registry (name=version pairs)
- **Infrastructure state**: INFRASTRUCTURE_SNAPSHOT.md (before/after diffs)
- **Memory state**: `.claude/memory/*.md` (ADR/LEARNINGS/BLOCKERS/ITERATION_LOG/EVALS registries)
- **Backup state**: `.claude/.backups/<mod>-<timestamp>/` (pre-update snapshots)

## Key Abstractions

**Module:**
- Purpose: Represents a reusable, versionable unit of methodology (skill, agent, docs, or rules)
- Examples: `consolidator/SKILL.md`, `validator/AGENT.md`, `reference/content/`, `software-architecture/rules/`
- Pattern: Self-contained directory with `VERSION`, `CHANGELOG.md`, `README.md` + type-specific content

**Type Composability:**
- Purpose: Allow modules to mix types (e.g., skill-creator = agent + 2 nested skills)
- Examples: `skill-creator/AGENT.md` + `skill-creator/skills/skill-creator/SKILL.md` + `skill-creator/skills/skill-creator-workflow/SKILL.md`
- Pattern: Installer scans module for all type markers; if found, installs them independently

**Iron Law:**
- Purpose: Encode non-negotiable operational constraint as part of skill/agent definition
- Examples: "Consolidation memory index = read header only (≤50 entries per read)" (consolidator), "No file > 300L without decomposition plan" (software-architecture), "One skill per invocation" (skill-creator)
- Pattern: Named in SKILL.md/AGENT.md frontmatter + definition, enforced by machine gates (scripts) or architectural refusal

**Skill Bundling:**
- Purpose: Encapsulate executable logic, reference docs, and test scripts together
- Examples: `consolidator/` contains `SKILL.md` + `scripts/{archive,reindex,detect-*}.sh` + `references/{indexation,archiving}.md`
- Pattern: Resources in `scripts/`, `references/`, `assets/` subdirectories; SKILL.md loads as needed

## Entry Points

**Lab Onboarding (Installation):**
- Location: `.vibeflow-cache/` → `.claude/scripts/vibeflow-update.sh`
- Triggers: First setup, new module deployment, periodic updates
- Responsibilities: Detect module type, copy to correct Lab path, manage version registry, create backups

**Lab Audit (Validation):**
- Location: `.claude/agents/vibeflow-validator.md`
- Triggers: `/checkpoint` command, post-Claude-update, scheduled hook (e.g., monthly)
- Responsibilities: Orchestrate 5 audit phases, synthesize findings, propose remediations (never auto-fix per ADR-031)

**Skill Creation (Methodology Extension):**
- Location: `.claude/agents/skill-creator.md` + `skill-creator/skills/skill-creator*/SKILL.md`
- Triggers: New skill needed (never created outside this agent per rule 3)
- Responsibilities: Decompose topic → parallel research → dense synthesis → draft SKILL.md → escalate to orchestrator

**Lab-Native Skills Invocation:**
- Location: Each skill is invoked via Claude Code skill tool (loaded via agent frontmatter or user `/skill` command)
- Triggers: When agent determines skill is appropriate; or user manually invokes `/consolidate`, `/audit-infra`, etc.
- Responsibilities: Execute skill logic, read bundled references as needed, return verdict or recommendations

## Architectural Constraints

- **Modular immutability** — Once a module is installed, it is not modified by the Lab; updates come via `vibeflow-update.sh update`, never manual edits to installed files
- **Central-only source of truth** — All module updates flow from `picmakpro/vibeflow-os`; Labs never fork or contribute back (PR model on central repo only)
- **Type-safe distribution** — Module type is detected once, then all type handlers run (no hybrid installation; if a module declares both `SKILL.md` and `AGENT.md`, both are installed)
- **Backup before overwrite** — Every update creates a timestamped backup in `.claude/.backups/`; rollback is always possible
- **No circular skill dependencies** — Validators, architects, consolidators all delegate *down* to specialized skills; never upward or sideways
- **Iron Law enforcement by machine** — Constraints encoded in SKILL.md are not suggestions; they are enforced by `scripts/` hooks, gates, or architectural refusal (e.g., consolidator refuses to open a full register; software-architecture gates at 300L)

## Anti-Patterns

### Distributed Fixing Without Validation

**What happens:** A drift is detected (e.g., agent density violation), validator fixes it, then notifies user afterward
**Why it's wrong:** Violates ADR-031 (never correct without validation); drifts may be intentional; automated fixes breed silent dependency on audits
**Do this instead:** Validator (per `validator/AGENT.md:Phase 5`) detects, proposes, but never corrects. User approves remediations. If automation is needed, create a new skill via skill-creator and assign escalation rules.

### Module Type Ambiguity

**What happens:** A module contains both `SKILL.md` at root AND `content/` directory; installer doesn't know which to prioritize
**Why it's wrong:** Type is the only signal for where to install; ambiguity breaks Lab structure assumptions
**Do this instead:** One primary type per module. If a skill needs bundled docs, put them in `references/` (sub-bundle of skill), not at `content/` (module-level doc marker). See `skill-creator/` (agent + multi-skill) as example of intentional composition: type composability is declared, not accidental.

### Manual Installation Over Installer

**What happens:** Developer copies `consolidator/SKILL.md` manually to `.claude/skills/` instead of running `vibeflow-update.sh install consolidator`
**Why it's wrong:** Breaks version tracking (`.vibeflow-installed` registry not updated); prevents rollback; masks when updates are available
**Do this instead:** Always use `vibeflow-update.sh install|update|rollback`. Manual copy is only for debugging (and temporary).

### Skill Scope Creep (Multi-Skill Invocation)

**What happens:** skill-creator agent receives a request like "create skills for X and Y" in one invocation
**Why it's wrong:** Per skill-creator rule 2: one skill per invocation. Multiple skills would deploy multiple sub-agents in parallel, degrading each skill's quality
**Do this instead:** skill-creator refuses immediately and escalates to orchestrator (named [ORCHESTRATING_AGENT]) for N parallel invocations.

### Iron Law as Guidance, Not Gate

**What happens:** Software-architecture skill says "≤300L per file" but developer adds a 450-line file with a comment "we'll refactor later"
**Why it's wrong:** Iron Laws without machine gates are not enforced; drift accumulates silently (LRN-115: "described policy ≠ enforced policy")
**Do this instead:** Gate is in `software-architecture/scripts/check-file-size.sh` (warn at 250L, block at 300L unless marked `[DEBT]`). Hook gates into pre-commit or CI.

## Error Handling

**Strategy:** Fail-fast with clear diagnostics; no silent degradation

**Patterns:**
- **Installer errors** (missing cache, invalid module): `vibeflow-update.sh` exits with code 1; logs reason to stderr
- **Type detection**: If neither `SKILL.md` nor `AGENT.md` nor `content/` nor `rules/` found, module is skipped with warning (not an error; allows future additions)
- **Skill invocation errors**: Skill returns structured verdict (PASS/FAIL/WARN + details); calling agent (validator, etc.) stops execution if FAIL and recommends manual intervention
- **Circular dependencies**: Not possible by design (agents delegate only to skills, never other agents)
- **Backup/rollback**: If backup fails, entire install/update aborts before making changes (atomicity)

## Cross-Cutting Concerns

**Versioning:** Each module has independent `VERSION` (semver). Repo `VERSION` file tracks last major change. Installer reads both. Update checks compare module versions only (no global version lock).

**Auditability:** Every install/update logs to stderr with `[vibeflow-update]` prefix. Skill audits generate dated reports (`YYYY-MM-DD-validator.md`, `INFRASTRUCTURE_SNAPSHOT.md`). Version registry `.vibeflow-installed` is human-readable (name=version lines).

**Backward Compatibility:** Installer v1.3.0+ supports all 5 module types. If older Lab runs installer v1.2.1, it skips doc-only modules (no error). New major installer version (v2.0) would be released as breaking change; Labs explicitly update `vibeflow-update.sh` to adopt.

---

*Architecture analysis: 2026-06-04*
