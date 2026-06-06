# Codebase Structure

**Analysis Date:** 2026-06-06 (restructuration plugin/ — voir note ci-dessous)

## Directory Layout

> **Restructuration (2026-06-06)** : tout le distribuable a été isolé sous `plugin/` et
> `marketplace.json` pointe `source: "./plugin"`. `.planning/` et `docs/` restent à la racine du
> repo et **ne sont plus distribués** dans le bundle plugin. Les modules détaillés plus bas vivent
> désormais sous `plugin/<module>/` (affichés à l'indentation racine pour la lisibilité).

```
vibeflow-os/                  # repo root = marketplace
├── README.md                 # Overview, module table, installation guide
├── INSTALL.md                # Detailed installation walkthrough
├── VERSION                   # Global repo version (semver)
├── LICENSE
├── .gitignore                # includes .vibeflow-cache
├── .planning/                # GSD internal state — NOT distributed (hors bundle)
├── docs/                     # Dev specs — NOT distributed (hors bundle)
├── .claude-plugin/
│   └── marketplace.json      # Marketplace manifest → plugin source: "./plugin"
│
└── plugin/                   # ★ THE DISTRIBUTED BUNDLE — everything below lives here
    ├── .claude-plugin/
    │   └── plugin.json       # Plugin manifest (skills: ./installer)
    ├── installer/            # [ENTRY] /vibeflow-install skill + build-module-catalog.sh
    └── _internal/
        ├── vibeflow-update.sh    # [CORE] Universal installer/updater for all module types
        └── resolve-deps.sh       # Dependency transitive-closure resolver

# --- modules ci-dessous : tous sous plugin/<module>/ ---

├── consolidator/             # v1.0.0 — Memory consolidation 4-pillar system
│   ├── VERSION
│   ├── CHANGELOG.md
│   ├── README.md
│   ├── SKILL.md              # [ENTRY] Consolidation memory (indexing/archiving/fusion/promotion)
│   ├── references/           # Bundled docs
│   │   ├── indexation.md     # Index header convention, colonne #Ligne
│   │   ├── archiving.md      # Archive criteria (status/age/refs)
│   │   ├── fusion.md         # Deduplication LLM-based
│   │   └── promotion.md      # learning -> rule semi-auto
│   └── scripts/              # Executable scripts (invoked by skill or hook)
│       ├── archive.sh        # Archive entries by 3 criteria
│       ├── reindex.sh        # Regenerate index header
│       ├── detect-duplicates.sh
│       ├── detect-promotions.sh
│       └── tests/            # Test fixtures + test runs
│           ├── fixtures/
│           └── test-*.sh
│
├── infrastructure-audit/     # v1.0.0 — Lab runtime audit (Claude, hooks, scripts, drift)
│   ├── VERSION
│   ├── CHANGELOG.md
│   ├── README.md
│   ├── SKILL.md              # [ENTRY] Infrastructure audit in 4 axes
│   ├── references/           # Bundled docs
│   │   ├── claude-code-runtime.md
│   │   ├── hooks-contract.md
│   │   ├── scripts-integrity.md
│   │   └── drift-detection.md
│   └── scripts/
│       ├── audit-infra.sh    # Main auditor (4 axes)
│       ├── known-versions.txt # Claude Code version whitelist
│       └── tests/
│
├── validator/                # v1.1.0 — Master audit agent (orchestrates 5 phases)
│   ├── VERSION
│   ├── CHANGELOG.md
│   ├── README.md
│   └── AGENT.md              # [ENTRY] vibeflow-validator agent (Opus, delegates to skills)
│
├── skill-creator/            # v1.0.0 — Sole authorized skill creation channel
│   ├── VERSION
│   ├── CHANGELOG.md
│   ├── README.md
│   ├── AGENT.md              # [ENTRY] skill-creator agent (Opus, decomposes + research)
│   ├── skills/               # Multi-skill module (type composability example)
│   │   ├── skill-creator/    # Anthropic official skill-creator
│   │   │   ├── SKILL.md      # [ENTRY] Create/iterate skills + evals
│   │   │   ├── references/
│   │   │   │   └── *.md      # Guides for each phase
│   │   │   ├── scripts/
│   │   │   │   └── *.py      # Eval runner, viewer, benchmarker
│   │   │   ├── agents/       # Sub-agents (parallel research facets)
│   │   │   ├── assets/       # Templates
│   │   │   └── eval-viewer/  # evaluate_results.py, generate_review.py
│   │   └── skill-creator-workflow/  # Internal workflow
│   │       ├── SKILL.md      # [ENTRY] 5-phase workflow (decompose → research → synthesis → draft → escalate)
│   │       └── references/
│
├── software-architecture/    # v1.0.0 — AI-safe code architecture (P9: Modularize for cognition)
│   ├── VERSION
│   ├── CHANGELOG.md
│   ├── README.md
│   ├── SKILL.md              # [ENTRY] AI-safe architecture (SOLID/SoC, ≤300L, machine gates)
│   ├── references/           # Bundled docs
│   │   ├── solid-soc.md      # SOLID principles + SoC + structure
│   │   ├── anti-patterns.md  # God file, feature envy, couplage circulaire
│   │   ├── restructuration-playbook.md  # Brownfield 6-wave playbook
│   │   └── universal-vs-dev.md  # P9 for non-code projects
│   ├── rules/                # Path-scoped rules auto-loaded by Claude Code
│   │   └── production-code-architecture.md  # `production-code/` subdirs only
│   └── scripts/
│       ├── check-file-size.sh       # Gate: warn 250L, block 300L
│       ├── detect-cycles.sh         # Circular dependency detection
│       ├── verify-boundaries.sh     # eslint-plugin-boundaries enforcement
│       └── tests/
│
├── audit-architecture/       # v1.0.0 — Design multi-layer audit structures (P8)
│   ├── VERSION
│   ├── CHANGELOG.md
│   ├── README.md
│   ├── SKILL.md              # [ENTRY] Audit architect (derives structure → forces it)
│   └── references/           # Bundled docs
│       ├── decomposition-method.md  # 4-time method (identify → derive dimensions → order → choose enforcement)
│       ├── enforcement-spectrum.md  # Script ← Test/Lint ← Checklist ← Rubric/LLM
│       └── anti-boucle.md          # Escalation limits + verdict flow
│
├── reference/                # v2.1.1 — Complete methodology documentation (doc-only module)
│   ├── VERSION
│   ├── CHANGELOG.md
│   ├── README.md
│   └── content/              # [INSTALLED TO] docs/reference/ in target Lab
│       ├── README-CLIENT.md        # Onboarding guide for end users
│       ├── VERSION.md              # Release notes v2.0 → v2.1.1
│       ├── LICENSE.md              # Usage license
│       ├── methodology/
│       │   ├── VIBEFLOW_CORE.md    # [CORE DOC] Bible v4.2 (9 principles P1-P9)
│       │   ├── VIBEFLOW_PHILOSOPHY.md
│       │   ├── VIBEFLOW_EXPLAINED.md
│       │   ├── patterns/            # 11 architectural patterns
│       │   │   ├── 01-constitution.md
│       │   │   ├── 02-registres.md
│       │   │   ├── 03-agents.md
│       │   │   ├── 04-skills.md
│       │   │   ├── 05-regles.md
│       │   │   ├── 06-capitalisation.md
│       │   │   ├── 07-transposition.md
│       │   │   ├── 08-evaluer.md
│       │   │   ├── 09-meta-procedures.md
│       │   │   ├── 10-plan-review-adversarial.md
│       │   │   └── 11-halt-conditions.md
│       │   ├── vocabulary/          # Lexique + forks mapping + dos/don'ts
│       │   │   └── *.md
│       │   └── templates/           # 33 reusable templates
│       │       ├── memory/          # 5 registry templates
│       │       ├── agents/          # 8 agent templates + contracts
│       │       ├── triggers/        # 5 trigger patterns
│       │       ├── rules/           # 1 rule template
│       │       ├── docs/            # 5 doc templates
│       │       └── skills/          # 4 skill templates
│       │           ├── agent-density-auditor/
│       │           ├── skill-creator/
│       │           ├── safe-execute/
│       │           └── debugger/
│       └── examples/
│           └── PetitsCoursFlow/     # Fictitious end-to-end example (Sophie K., music teacher)
│               ├── .claude/         # Example Lab structure
│               │   ├── agents/
│               │   ├── memory/
│               │   └── rules/
│               └── *.md             # Example decisions, conventions
│
├── .planning/
│   └── codebase/             # Generated codebase maps (this repo's own documentation)
│       ├── ARCHITECTURE.md   # System design, layers, data flow
│       └── STRUCTURE.md      # Directory layout, file locations
│
└── .git/                     # Git repository (main branch, private)
```

## Directory Purposes

**Module Directories** (`consolidator/`, `infrastructure-audit/`, `validator/`, etc.):
- Purpose: Self-contained, versionable units of methodology
- Contains: `VERSION`, `CHANGELOG.md`, `README.md`, type-specific content (`SKILL.md`, `AGENT.md`, `content/`, `rules/`)
- Installation target: Determined by module type
  - **Single-skill**: `SKILL.md` → `.claude/skills/<mod>/`
  - **Multi-skill**: `skills/<name>/SKILL.md` → `.claude/skills/<name>/`
  - **Agent**: `AGENT.md` → `.claude/agents/<mod>.md`
  - **Doc**: `content/` → `docs/<mod>/`
  - **Rules**: `rules/*.md` → `.claude/rules/`

**`_internal/`**:
- Purpose: Central installer/updater machinery
- Contains: `vibeflow-update.sh` (sole entry point for Lab installations)
- Not installed to Labs; used by Labs to install other modules

**`reference/content/`**:
- Purpose: Complete, distributable methodology reference
- Installed to: `docs/reference/` in target Labs (doc-only module)
- Consumed by: Lab designers (self-service), skill-creator (methodology alignment), validator (consistency checks)

**`.planning/codebase/`**:
- Purpose: Auto-generated codebase documentation for vibeflow-os itself
- Contents: ARCHITECTURE.md, STRUCTURE.md (maps for CLI operators on this repo)
- Not installed to Labs; internal reference only

## Key File Locations

**Entry Points:**

- `_internal/vibeflow-update.sh` — Installer/updater (run from Lab)
- `consolidator/SKILL.md` — Memory consolidation skill (most frequently used)
- `validator/AGENT.md` — Master audit agent (invoked at `/checkpoint`)
- `skill-creator/AGENT.md` — Sole skill creation channel
- `software-architecture/SKILL.md` — Code architecture guardrails
- `audit-architecture/SKILL.md` — Audit structure designer
- `reference/content/methodology/VIBEFLOW_CORE.md` — Methodology bible (source of truth for all principles)

**Configuration:**

- `VERSION` (repo root and each module) — Semantic version (MAJOR.MINOR.PATCH)
- `CHANGELOG.md` (each module) — Detailed changes per version
- `README.md` (each module) — Module-specific overview
- `INSTALL.md` (repo root) — Multi-method installation guide

**Core Logic:**

- `consolidator/scripts/archive.sh` — Executes archiving pillar (hook SessionEnd)
- `consolidator/scripts/reindex.sh` — Executes indexing pillar
- `infrastructure-audit/scripts/audit-infra.sh` — Executes 4-axis audit
- `software-architecture/scripts/check-file-size.sh` — Gate: file size enforcement
- `software-architecture/scripts/detect-cycles.sh` — Circular dependency detection

**Testing:**

- `consolidator/scripts/tests/test-*.sh` — Test suite (consolidator module)
- `software-architecture/scripts/tests/test-*.sh` — Test suite (software-architecture)
- `skill-creator/skills/skill-creator/eval-viewer/` — Eval runner/viewer Python scripts
- `skill-creator/skills/skill-creator/scripts/` — Eval benchmarking utilities

**Documentation:**

- `consolidator/references/` — Indexation, archiving, fusion, promotion guides
- `infrastructure-audit/references/` — Runtime, hooks, scripts, drift audit docs
- `software-architecture/references/` — SOLID/SoC, anti-patterns, brownfield playbook
- `audit-architecture/references/` — Decomposition method, enforcement spectrum
- `skill-creator/skills/skill-creator/references/` — Skill creation workflow guides
- `reference/content/methodology/` — Complete methodology (11 patterns, 33 templates)

## Naming Conventions

**Files:**

- **Skill definitions**: `SKILL.md` (mandatory YAML frontmatter + markdown body)
- **Agent definitions**: `AGENT.md` (mandatory YAML frontmatter + markdown body)
- **Version tracking**: `VERSION` (plain text: `vX.Y.Z`)
- **Changelogs**: `CHANGELOG.md` (markdown, reverse chronological)
- **Executable scripts**: `*.sh` (bash), `*.py` (Python) — lowercase, hyphenated
- **Reference docs**: `*.md` (markdown) — descriptive names in bundled `references/`, `rules/`
- **Tests**: `test-*.sh` (bash test files in `scripts/tests/`)

**Directories:**

- **Module root**: Lowercase, hyphenated (`consolidator/`, `skill-creator/`, `software-architecture/`)
- **Type-specific subdirs**: Fixed names (`scripts/`, `references/`, `assets/`, `skills/`, `rules/`, `content/`)
- **Nested skills**: `skills/<skill-name>/` (multi-skill modules only)
- **Lab installation targets**: Fixed by installer (`.claude/skills/`, `.claude/agents/`, `.claude/rules/`, `docs/`)

## Where to Add New Code

**New Skill (within existing module):**
- **Implementation**: `<module>/SKILL.md` (single skill) or `<module>/skills/<name>/SKILL.md` (if multi-skill)
- **References**: `<module>/references/<name>.md` (bundled docs loaded on-demand)
- **Scripts**: `<module>/scripts/<name>.sh` (executable; no .md files here)
- **Tests**: `<module>/scripts/tests/test-<name>.sh`

**New Standalone Module:**
- Create directory `<new-module>/` at repo root (same level as `consolidator/`, `validator/`)
- Add `VERSION` (semver: `v1.0.0`), `CHANGELOG.md`, `README.md`
- Add type-specific content:
  - If skill: `SKILL.md` + `references/`, `scripts/`
  - If agent: `AGENT.md`
  - If doc: `content/` subdirectory
  - If rules: `rules/` subdirectory
- Register in `README.md` module table (add row with name, version, type, description)
- Test with `vibeflow-update.sh install <new-module>` from target Lab

**New Agent (specialized orchestrator):**
- Path: `<new-module>/AGENT.md`
- Frontmatter: `name`, `description`, `model: opus`, `memory: project`, `skills: [list]`
- Document delegation rules (each audit phase delegates to one skill, never re-implements)
- Follow vibeflow-validator pattern: 5 phases, each delegates, Phase 5 synthesizes

**New Rule (path-scoped constraint):**
- Path: `<module>/rules/<constraint-name>.md`
- Format: Markdown with YAML frontmatter declaring path scope
- Example: `software-architecture/rules/production-code-architecture.md` scopes to `production-code/`
- Auto-loaded by Claude Code (no explicit reference needed)

**New Reference/Template (supporting doc):**
- Path: `<module>/references/<topic>.md` (single-skill bundle) or `reference/content/methodology/templates/<type>/<name>/` (methodology-wide)
- Format: Markdown, unlimited length, clear table of contents if >300 lines
- Link from SKILL.md/AGENT.md with guidance on when to read

**Adding to vibeflow-update.sh installer:**
- Script already handles 5 module types (single-skill, multi-skill, agent, doc, rules)
- New type requires edit to `_internal/vibeflow-update.sh`: add type detection + copy logic (similar to existing handlers, lines 106-150)
- Test with `vibeflow-update.sh install|update|rollback` from dummy Lab before releasing

## Special Directories

**`.vibeflow-cache/`** (in target Labs, not in this repo):
- Purpose: Local git clone of vibeflow-os used as installer source
- Generated: By `vibeflow-update.sh` on first run (`git clone --depth 1`)
- Committed: No (added to Lab's `.gitignore`)
- Lifetime: Persistent (reused for all subsequent updates)

**`.claude/.backups/`** (in target Labs, not in this repo):
- Purpose: Pre-update snapshots of installed modules
- Generated: By `vibeflow-update.sh` before each install/update
- Format: Timestamped directories: `.claude/.backups/<module>-YYYY-MM-DD-HHmmss/`
- Cleanup: User-managed (no auto-cleanup)

**`.claude/scripts/.vibeflow-installed`** (in target Labs, not in this repo):
- Purpose: Version registry of installed modules
- Format: Plain text, one entry per line: `module=vX.Y.Z`
- Generated: By `vibeflow-update.sh` after successful install/update
- Used by: `vibeflow-update.sh status` (compare installed vs available)

---

*Structure analysis: 2026-06-04*
