<div align="center">

# VibeFlow OS

**English** · [Français](./README.fr.md)

**Turn Claude Code into a development orchestrator driven by plain language.**

Say _"help me build this feature"_ — and the whole pipeline kicks off: scoping → plan → execution → tests → delivery. Without ever typing a technical command or knowing what runs under the hood.

[![Version](https://img.shields.io/badge/version-2.5.0-2563eb)](./VERSION)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-plugin-d97757)](https://docs.claude.com/en/docs/claude-code)
[![Modules](https://img.shields.io/badge/modules-9-16a34a)](#-modules)
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

Beyond dev orchestration, VibeFlow ships **governance** modules: software-architecture audits, infrastructure audits, memory consolidation, methodology-alignment validation — each enabled à la carte.

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

**Update:** `claude plugin update vibeflow` · **Details / troubleshooting:** [INSTALL.md](./INSTALL.md)

---

## 📦 Modules

9 independently toggleable modules. Each has its own version, `CHANGELOG.md`, and `README.md`.

| Module | Ver. | Type | What it does |
|--------|:----:|------|--------------|
| **[dev-orchestrator](./plugin/dev-orchestrator/)** | `1.1.0` | agent + skills + scripts | ⭐ The core. Router agent `vibeflow-dev` + 13 `/vf-*` verbs + auto-generated GSD index. Routes **plain language** to GSD/Superpowers skills (scoping → delivery), without exposing the plumbing. |
| **[software-architecture](./plugin/software-architecture/)** | `1.0.0` | skill + rules + scripts | AI-Safe software architecture doctrine: SOLID/SoC, anti-god-files (≤300 LoC), machine-enforced gates, brownfield restructuring playbook. |
| **[audit-architecture](./plugin/audit-architecture/)** | `1.0.0` | skill + references | Designer of **audit architectures**: derives, from a brief, the multi-layer audit structure of a process (content / folder / code / sales). |
| **[infrastructure-audit](./plugin/infrastructure-audit/)** | `1.0.0` | skill + scripts | Automatic audit of the Claude Code infra (hooks, scripts, Anthropic drift) — catches regressions after an update. |
| **[validator](./plugin/validator/)** | `1.1.0` | agent-only | Agent `vibeflow-validator`: guardian of technical alignment between methodology and projects, in 5 phases (incl. process-architecture audit). |
| **[consolidator](./plugin/consolidator/)** | `1.0.0` | skill + scripts | Structured-memory consolidation across 4 pillars: indexing / archiving / merging / promotion. |
| **[skill-creator](./plugin/skill-creator/)** | `1.0.0` | agent + skills | The "minimal agent + 2 composable skills" pattern for creating new skills (Anthropic base + workflow). |
| **[reference](./plugin/reference/)** | `2.1.1` | doc-only | Full methodology documentation: VibeFlow Core (9 principles) + 11 patterns + 33 templates + 1 end-to-end example. |
| **[planning-core](./plugin/planning-core/)** | `1.0.0` | skill + references | Universal planning & documentation backbone: lays down the common `.planning/` trunk (PROJECT/STATE/ROADMAP/REQUIREMENTS/MILESTONES/phases), **adapted to each lab's domain** — never imposed. The forward/present layer, complementary to the memory registries. |

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

- **Source-available**: code and history are public, proprietary license ("All rights reserved", no reuse rights granted).
- **Shell + Python scripts only** — auditable line by line, no unverified third-party dependencies.
- **Idempotent**: every install script can be re-run without breaking the install, with an automatic backup before overwrite.
- **Zero hooks**: the plugin registers nothing at session start. Everything starts from your manual invocation.
- **Tests**: every script is covered (`scripts/tests/test-*.sh`).

---

## 🧭 Versioning & governance

**Semver** per module (`vMAJOR.MINOR.PATCH`) — MAJOR = breaking change, MINOR = new module/capability, PATCH = bugfix or docs. The global repo is tagged to the version of the last major change. Each GitHub release = the official changelog.

<details>
<summary><strong>Repo version history</strong></summary>

| Version | Date | Change |
|---------|------|--------|
| `v1.0.0` | 2026-05-23 | Initial release: consolidator |
| `v1.1.0` | 2026-05-24 | + infrastructure-audit |
| `v1.2.0` | 2026-05-24 | + validator (agent-only) |
| `v1.2.1` | 2026-05-24 | Fix `vibeflow-update.sh` (handle `AGENT.md`) |
| `v2.0.0` | 2026-05-24 | + skill-creator (multi-skills), + reference (doc-only), new module type |
| `v2.1.0` | 2026-05-28 | + software-architecture, `rules/` type in the installer, Core v4.2 (P9) |
| `v2.2.0` | 2026-06-03 | + audit-architecture, validator v1.1.0 (Phase 4 process scan) |
| `v2.3.0` | 2026-06-04 | + dev-orchestrator (NL router → GSD + Superpowers, 13 `/vf-*` verbs) |
| `v2.4.0` | 2026-06-05 | Two-command install: Claude Code plugin + `/vibeflow-install` with toggles |
| `v2.4.1` | 2026-06-06 | `/vibeflow-install` fully manual, distributable isolated under `plugin/`, cleanup |
| `v2.4.2` | 2026-06-06 | `uninstall --all` engine command + uninstall flow in `/vibeflow-install` + two-layer uninstall docs |
| `v2.5.0` | 2026-06-10 | + planning-core (universal `.planning/` backbone, domain-adaptive, 3 rigor profiles) — ADR-038 |

</details>

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

Source-available under a proprietary license — see [LICENSE](./LICENSE). The code and history are public, but no reuse, modification, or distribution rights are granted.

> The `skill-creator` module reuses original Anthropic content under the MIT license.
