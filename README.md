<div align="center">

# VibeFlow OS

**English** · [Français](./README.fr.md)

**Turn Claude Code into a dev & design orchestrator driven by plain language.**

Say _"help me build this feature"_ — and the whole pipeline kicks off: scoping → plan → execution → tests → delivery. Without ever typing a technical command or knowing what runs under the hood. Other domains get their own tailor-made lab via the Lab Factory (`vf-new-lab`).

[![Version](https://img.shields.io/badge/version-2.34.0-2563eb)](./VERSION)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-plugin-d97757)](https://docs.claude.com/en/docs/claude-code)
[![Modules](https://img.shields.io/badge/modules-17-16a34a)](#-modules)
[![License](https://img.shields.io/badge/license-source--available-64748b)](./LICENSE)

[Install](#-install) · [Modules](#-modules) · [How it works](#-how-it-works) · [Author](#-author)

</div>

---

## ✨ What it is

**VibeFlow OS** is the distribution repo for **VibeFlow** — an AI-assisted development methodology, packaged as a **Claude Code plugin** with toggleable modules.

You don't learn a new CLI. You just talk. A **router agent** understands your intent and dispatches it to the right tool (GSD, Superpowers, audits…), rephrasing everything in a consistent VibeFlow vocabulary. The plumbing stays invisible.

```text
You  ›  help me add Google auth
        VibeFlow runs: scoping → roadmap → sprint → tests
        ↳ no /gsd-*, no /sp-* to learn

You  ›  where are we?
        VibeFlow: sprint report + next step

You  ›  debug this crash
        VibeFlow: systematic debugging, state persisted across resets
```

Today VibeFlow orchestrates **dev and design** through an **agentic model**: the `vibeflow-dev` agent detects intent and invokes the GSD toolchain directly, with a mission team for long runs. Other domains are built as **tailor-made labs** through the Lab Factory (`vf-new-lab` + `skill-creator`); the **content bundle is available** (a full team on the team-kernel); growth / business bundles are **in preparation**. Beyond orchestration, VibeFlow ships **governance** modules: software-architecture audits, infrastructure audits, memory consolidation, methodology-alignment validation — each enabled à la carte.

---

## 🚀 Install

VibeFlow installs as a **Claude Code plugin** in two commands — no clone, no script, no `settings.json` edits:

```bash
claude plugin marketplace add picmakpro/vibeflow-os
claude plugin install vibeflow
```

Then, **inside Claude Code**, launch the configuration UX whenever you want:

```
/vibeflow-install
```

The UX walks you through:

| Step | What happens |
|------|--------------|
| **Scope** | Choose where to install: account (`user`), project (`project`), or project without commit (`local`). |
| **Modules** | Pick which modules to enable — the list is populated from the catalog, each with its description. |
| **Dependencies** | The transitive closure of `requires` is computed and summarized **before** any install. |

> Launch is **100% manual**: VibeFlow never opens on its own at session start. Type `/vibeflow-install` to install or re-configure (change scope, add/remove a module — dependencies are re-resolved each time).

**Update:** `claude plugin update vibeflow@vibeflow-os` (or just `/vf-update` once installed) · **Details / troubleshooting:** [INSTALL.md](./INSTALL.md)

---

## 📦 Modules

17 modules total. Each has its own version, `CHANGELOG.md`, and `README.md`.

> **At install (since v2.13.0)**: `conductor` is the **mandatory baseline**, installed by default (with its safety net: planning-core, validator, consolidator, infrastructure-audit) — not a choice. Then **a single choice**: *development lab* (`dev-orchestrator`) or *new tailor-made domain lab* via `/vf-new-lab`. The **3 domain bundles** (business-pilot / content / growth) are **WIP and not offered at install** (`proposable:false`); they'll be re-offered once complete. Other modules remain available as advanced à-la-carte ("add &lt;module&gt;"). The **mobile-test** and **mobile-test-team** modules are advanced à-la-carte add-ons for mobile projects.

| Module | Ver. | Type | What it does |
|--------|:----:|------|--------------|
| **[conductor](./plugin/conductor/)** | `1.14.0` | agent + skills + scripts + references | 🧭 The front door. Meta agent `vibeflow-conductor` (guardian): create/configure a lab in **any domain** (`vf-new-lab`, bundle-aware), install/verify/update, migrate on doctrine change (`vf-calibrate`), receive coherence escalations. Not always-on — config/audit/migration only. |
| **[dev-orchestrator](./plugin/dev-orchestrator/)** | `2.1.0` | agent + skills + scripts | ⭐ The dev core, **agentic model** (v2, breaking): agent `vibeflow-dev` detects intent and invokes GSD bricks **directly** (single intent map, on-demand), proposes next steps, guards first-use. Mission team `vf-dev-manager` (DAG + driver lock + typed reports + mission digest) with sonnet workers `vf-coder`/`vf-reviewer`/`vf-auditer`, parallel review ∥ audit dispatch, autonomous-loop guardrails. Two surviving skills: `vf-auto` (autonomy gateway) and `vf-dev` (embody the agent). Installs `design-orchestrator` by default. |
| **[design-orchestrator](./plugin/design-orchestrator/)** | `1.2.0` | agent + skills | 🎨 The design companion. Router agent `vibeflow-design` + `/vf-design` (design entry point) and `/vf-sketch` (throwaway mockup) verbs: routes **plain language** design intent (define art direction, redesign UI, critique/audit, targeted craft) to the right workflow. **Stack-agnostic** (web / mobile / desktop) — outputs specs + tokens, not framework-locked code. Design toolchain (UX reference, creative direction, craft studio) piloted behind the scenes with graceful degradation. Installed by default with `dev-orchestrator`. |
| **[mobile-test](./plugin/mobile-test/)** | `1.0.1` | skill + script + config | 📱 Real mobile app testing (iOS simulator / Android emulator): target detection, build-if-absent, Maestro regression, timestamped report + artifacts, visual failure diagnosis via `mobile-mcp`. Config-driven, no project constants. **Experimental** until first real green run. |
| **[mobile-test-team](./plugin/mobile-test-team/)** | `1.4.0` | agents + rules | 🤖 Autonomous mobile test→fix loop: `vf-test-orchestrator` + tool-compartmentalized workers (`vf-test-runner` / `vf-app-fixer`, Pattern 12), so autonomous mode reaches "the app actually works", not just green unit tests. Path-scoped rule fires the real-verification doctrine while coding. Requires `mobile-test`. **Experimental**. |
| **[software-architecture](./plugin/software-architecture/)** | `1.5.2` | skill + rules + scripts | AI-Safe software architecture doctrine + **dev philosophies home**: SOLID, DRY, KISS, YAGNI, Clean Architecture, Clean Code, TDD card; anti-god-files (≤300 LoC), machine-enforced gates (**Nyquist + Decision Coverage** absorbed), brownfield playbook. |
| **[audit-architecture](./plugin/audit-architecture/)** | `1.0.1` | skill + references | Designer of **audit architectures**: derives, from a brief, the multi-layer audit structure of a process (content / folder / code / sales). |
| **[infrastructure-audit](./plugin/infrastructure-audit/)** | `1.2.1` | skill + scripts | Automatic audit of the Claude Code infra (hooks, scripts, Anthropic drift) — catches regressions after an update. |
| **[validator](./plugin/validator/)** | `1.3.0` | agent-only | Agent `vibeflow-validator`: guardian of technical alignment between methodology and projects, in 5 phases (incl. process-architecture audit). |
| **[consolidator](./plugin/consolidator/)** | `1.7.0` | skill + scripts | Structured-memory consolidation across 4 pillars (indexing / archiving / merging / promotion) + living-memory layer (per-entry `knowledge/`, category half-life decay, non-destructive supersession) + fork-config registries. |
| **[skill-creator](./plugin/skill-creator/)** | `1.0.2` | agent + skills | The "minimal agent + 2 composable skills" pattern for creating new skills (Anthropic base + workflow). |
| **[reference](./plugin/reference/)** | `2.5.1` | doc-only | Full methodology documentation: VibeFlow Core (9 principles) + 12 patterns (incl. tool-compartmentalization) + 33 templates + 1 end-to-end example. |
| **[planning-core](./plugin/planning-core/)** | `2.5.0` | skill + references + scripts | Lab planning & documentation backbone: lays down the common `.planning/` trunk of a **non-dev** lab (PROJECT/STATE/ROADMAP/REQUIREMENTS/MILESTONES/phases), adapted to its domain — never imposed — and holds **lab-level altitude** everywhere: project index, typed compartments, planning-debt detection, memory bridge, hook-enforced freshness. On a code project, the project planning belongs to the development engine: this module redirects instead of producing a competing format (ADR-055). |
| **[kpi-analyst](./plugin/kpi-analyst/)** | `1.0.2` | agent + skill + scripts + references | 📈 Deduces a lab's **real business KPIs**: a stable schema validated once + values extracted deterministically, published to the `KPIS.md` registry for the Hub dashboard. Never an invented number. |
| 📦 **[business-pilot-bundle](./plugin/business-pilot-bundle/)** | `1.2.0` | doc-only (bundle) | Métier bundle: ready chassis to pilot a business (3 agent blueprints commercial/delivery/finance + `business/` extension + canon registries). Instantiated by `vf-new-lab`. |
| 📦 **[content-bundle](./plugin/content-bundle/)** | `1.1.0` | doc-only (bundle) | Métier bundle: editorial chain brief→deliverable→distribution (3 blueprints strategist/scriptwriter/repurposer + `editorial/` extension + blocking clarity gate). Instantiated by `vf-new-lab`. |
| 📦 **[growth-bundle](./plugin/growth-bundle/)** | `1.1.0` | doc-only (bundle) | Métier bundle: growth/acquisition **organized per channel** (3 blueprints channel-strategist/copywriter/analyst + `growth/channels/` extension + GDPR guardrails). Instantiated by `vf-new-lab`. |

---

## ⌨️ Commands

Native slash commands shipped by the plugin (available as soon as it's enabled — `commands/` is auto-discovered):

| Command | Does |
|---------|------|
| `/vibeflow [request]` | Front door — delegates to the **vibeflow-conductor** agent (create/configure/verify/update/migrate the lab). |
| `/vf-new-lab [domain]` | Create a lab in any domain (instantiates a métier bundle if present). |
| `/vf-planning` | Lay down or refresh the `.planning/` backbone of a non-dev lab, and hold lab-level altitude everywhere (project index, compartments, memory bridge). On a code project, it redirects to the development verb. |
| `/vf-calibrate` | Check framework drift and migrate the lab (human-validated). |
| `/vf-audit` | Full conformance audit via the **vibeflow-validator** agent. |
| `/vibeflow-install` | Install/toggle modules (scope-aware installer skill). |
| `/vf-update` | Update VibeFlow — plugin (marketplace cache) + installed modules — to the latest published version, with changelog and confirmation. A SessionStart banner flags a new version when one exists. |

> Agents (`vibeflow-conductor`, `vibeflow-validator`) are not directly typeable — these commands are their explicit entry points. A command guides you to `/vibeflow-install` first if the underlying module isn't installed yet.

---

## 🛠 How it works

### One UX, multiple scopes

The installer places each module exactly where Claude Code expects it, based on its type:

| Module type | Structure | Install target |
|-------------|-----------|----------------|
| **single-skill** | `<mod>/SKILL.md` (+ `references/`, `scripts/`) | `.claude/skills/<mod>/` |
| **multi-skills** | `<mod>/skills/<name>/SKILL.md` | `.claude/skills/<name>/` (each) |
| **agent-only** | `<mod>/AGENT.md` | `.claude/agents/<mod>.md` |
| **doc-only** | `<mod>/content/` | `docs/<mod>/` |
| **rules** | `<mod>/rules/*.md` | `.claude/rules/` (path-scoped, auto-loaded) |

Types are **composable**: `dev-orchestrator` = agent + skills + scripts; `software-architecture` = skill + rules + scripts.

### Anti-hallucination by design

Routing relies on a **factual index auto-generated** from the frontmatter of the skills present on disk — never written by hand. The agent cannot invent a command name that doesn't exist.

---

## 🔒 Security

- **Source-available**: code and history are public, proprietary license — private reuse granted to formation students, see [LICENSE](./LICENSE).
- **Shell + Python scripts, plus the standard `jq` tool** (JSON manifest parsing) — auditable line by line. System prerequisites are listed in [INSTALL.md](./INSTALL.md) (Windows/Git Bash notes included).
- **Idempotent**: every install script can be re-run without breaking the install, with an automatic backup before overwrite.
- **Zero hooks**: the plugin registers nothing at session start. Everything starts from your manual invocation.
- **Tests**: every script is covered (`scripts/tests/test-*.sh`).

---

## 🧭 Versioning & governance

**Semver** per module (`vMAJOR.MINOR.PATCH`) — MAJOR = breaking change, MINOR = new module/capability, PATCH = bugfix or docs. The global repo is tagged to the version of the last major change. Each GitHub release = the official changelog.

Full version history: **[CHANGELOG.md](./CHANGELOG.md)** — the README only keeps the 3 latest entries.

| Version | Date | Change |
|---------|------|--------|
| `v2.31.1` | 2026-07-25 | Version-file alignment: the `VERSION` files of `software-architecture` (v1.5.1) and `kpi-analyst` (v1.0.1) caught up with their v2.29.0 changelogs — the version registry now tells the truth. |
| `v2.31.0` | 2026-07-25 | Fine-grained intent routing: three routing levels (trigger-dense descriptions, global verb-precedence rule, on-demand routing doctrine). 19 new `/vf-*` verbs — dev-orchestrator goes from 14 to 31, design-orchestrator gains `/vf-sketch` (dev-orchestrator v1.8.1, design-orchestrator v1.1.0, conductor v1.12.2). |
| `v2.30.0` | 2026-07-25 | Altitude boundary between VibeFlow planning and the development planning engine (ADR-055): `vf-planning` holds lab-level altitude and redirects code-project planning to the dev verb (planning-core v2.4.0). |

<details>
<summary><strong>Methodology references (ADR / LRN)</strong></summary>

- **ADR-032** — 4-pillar memory consolidation system
- **ADR-033** — Creation of the vibeflow-os repo
- **ADR-035** — AI-Safe software architecture doctrine (software-architecture module + Core P9)
- **ADR-036** — Audit architecture doctrine (audit-architecture module + validator Phase 4)
- **LRN-101** — "Minimal agent + 2 composable skills" pattern
- **LRN-106** — Audit before fix
- **LRN-107** — Central versioned repo > ad-hoc zip

Main lab (private): [vibeflow-lab](https://github.com/picmakpro/vibeflow-lab) — structural changes are tested there before release.

</details>

---

## 👤 Authors

- **[@picmakpro](https://github.com/picmakpro)** — creator and maintainer of the VibeFlow methodology and most modules (governance, audits, `skill-creator`, `consolidator`, `reference`…). Repo owner.
- **Samuel Neveu — [@Samuel-Learnity](https://github.com/Samuel-Learnity)** — development-workflow side: the `dev-orchestrator` module and the plain-language → pipeline experience.

---

## 📄 License

Source-available under a proprietary license — see [LICENSE](./LICENSE). The code and history are public; formation students get a private-reuse grant (adapt module elements in their own private repos); redistribution and resale remain prohibited.

> The `skill-creator` module reuses original Anthropic content under the MIT license.
