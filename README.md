<div align="center">

# VibeFlow OS

**English** · [Français](./README.fr.md)

**Turn Claude Code into a development orchestrator driven by plain language.**

Say _"help me build this feature"_ — and the whole pipeline kicks off: scoping → plan → execution → tests → delivery. Without ever typing a technical command or knowing what runs under the hood.

[![Version](https://img.shields.io/badge/version-2.28.0-2563eb)](./VERSION)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-plugin-d97757)](https://docs.claude.com/en/docs/claude-code)
[![Modules](https://img.shields.io/badge/modules-16-16a34a)](#-modules)
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

**Update:** `claude plugin update vibeflow@vibeflow-os` (or just `/vf-update` once installed) · **Details / troubleshooting:** [INSTALL.md](./INSTALL.md)

---

## 📦 Modules

16 modules total. Each has its own version, `CHANGELOG.md`, and `README.md`.

> **At install (since v2.13.0)**: `conductor` is the **mandatory baseline**, installed by default (with its safety net: planning-core, validator, consolidator, infrastructure-audit) — not a choice. Then **a single choice**: *development lab* (`dev-orchestrator`) or *new tailor-made domain lab* via `/vf-new-lab`. The **3 domain bundles** (business-pilot / content / growth) are **WIP and not offered at install** (`proposable:false`); they'll be re-offered once complete. Other modules remain available as advanced à-la-carte ("add &lt;module&gt;"). The **mobile-test** and **mobile-test-team** modules are advanced à-la-carte add-ons for mobile projects.

| Module | Ver. | Type | What it does |
|--------|:----:|------|--------------|
| **[conductor](./plugin/conductor/)** | `1.8.2` | agent + skills + scripts + references | 🧭 The front door. Meta agent `vibeflow-conductor` (guardian): create/configure a lab in **any domain** (`vf-new-lab`, bundle-aware), install/verify/update, migrate on doctrine change (`vf-calibrate`), receive coherence escalations. Not always-on — config/audit/migration only. |
| **[dev-orchestrator](./plugin/dev-orchestrator/)** | `1.3.0` | agent + skills + scripts | ⭐ The dev core. Router agent `vibeflow-dev` + 14 `/vf-*` verbs (incl. `vf-decide` decision panel) + design-phase routing to `/vf-design` + auto-generated GSD index + autonomous-loop guardrails doctrine. Routes **plain language** to GSD/Superpowers skills (scoping → delivery), without exposing the plumbing. Installs `design-orchestrator` by default. |
| **[design-orchestrator](./plugin/design-orchestrator/)** | `1.0.0` | agent + skills | 🎨 The design companion. Router agent `vibeflow-design` + `/vf-design` verb: routes **plain language** design intent (define art direction, redesign UI, critique/audit, targeted craft) to the right workflow. **Stack-agnostic** (web / mobile / desktop) — outputs specs + tokens, not framework-locked code. Design toolchain (UX reference, creative direction, craft studio) piloted behind the scenes with graceful degradation. Installed by default with `dev-orchestrator`. |
| **[mobile-test](./plugin/mobile-test/)** | `1.0.0` | skill + script + config | 📱 Real mobile app testing (iOS simulator / Android emulator): target detection, build-if-absent, Maestro regression, timestamped report + artifacts, visual failure diagnosis via `mobile-mcp`. Config-driven, no project constants. **Experimental** until first real green run. |
| **[mobile-test-team](./plugin/mobile-test-team/)** | `1.0.1` | agents + rules | 🤖 Autonomous mobile test→fix loop: `vf-test-orchestrator` + tool-compartmentalized workers (`vf-test-runner` / `vf-app-fixer`, Pattern 12), so autonomous mode reaches "the app actually works", not just green unit tests. Path-scoped rule fires the real-verification doctrine while coding. Requires `mobile-test`. **Experimental**. |
| **[software-architecture](./plugin/software-architecture/)** | `1.3.0` | skill + rules + scripts | AI-Safe software architecture doctrine + **dev philosophies home**: SOLID, DRY, KISS, YAGNI, Clean Architecture, Clean Code, TDD card; anti-god-files (≤300 LoC), machine-enforced gates (**Nyquist + Decision Coverage** absorbed), brownfield playbook. |
| **[audit-architecture](./plugin/audit-architecture/)** | `1.0.1` | skill + references | Designer of **audit architectures**: derives, from a brief, the multi-layer audit structure of a process (content / folder / code / sales). |
| **[infrastructure-audit](./plugin/infrastructure-audit/)** | `1.0.0` | skill + scripts | Automatic audit of the Claude Code infra (hooks, scripts, Anthropic drift) — catches regressions after an update. |
| **[validator](./plugin/validator/)** | `1.1.0` | agent-only | Agent `vibeflow-validator`: guardian of technical alignment between methodology and projects, in 5 phases (incl. process-architecture audit). |
| **[consolidator](./plugin/consolidator/)** | `1.0.0` | skill + scripts | Structured-memory consolidation across 4 pillars: indexing / archiving / merging / promotion. |
| **[skill-creator](./plugin/skill-creator/)** | `1.0.0` | agent + skills | The "minimal agent + 2 composable skills" pattern for creating new skills (Anthropic base + workflow). |
| **[reference](./plugin/reference/)** | `2.3.1` | doc-only | Full methodology documentation: VibeFlow Core (9 principles) + 12 patterns (incl. tool-compartmentalization) + 33 templates + 1 end-to-end example. |
| **[planning-core](./plugin/planning-core/)** | `1.1.0` | skill + references + scripts | Universal planning & documentation backbone: lays down the common `.planning/` trunk (PROJECT/STATE/ROADMAP/REQUIREMENTS/MILESTONES/phases), **adapted to each lab's domain** — never imposed. Forward/present layer, complementary to memory registries. Freshness guard + domain detection + non-dev example. |
| 📦 **[business-pilot-bundle](./plugin/business-pilot-bundle/)** | `1.0.0` | doc-only (bundle) | Métier bundle: ready chassis to pilot a business (3 agent blueprints commercial/delivery/finance + `business/` extension + canon registries). Instantiated by `vf-new-lab`. |
| 📦 **[content-bundle](./plugin/content-bundle/)** | `1.0.0` | doc-only (bundle) | Métier bundle: editorial chain brief→deliverable→distribution (3 blueprints strategist/scriptwriter/repurposer + `editorial/` extension + blocking clarity gate). Instantiated by `vf-new-lab`. |
| 📦 **[growth-bundle](./plugin/growth-bundle/)** | `1.0.0` | doc-only (bundle) | Métier bundle: growth/acquisition **organized per channel** (3 blueprints channel-strategist/copywriter/analyst + `growth/channels/` extension + GDPR guardrails). Instantiated by `vf-new-lab`. |

---

## ⌨️ Commands

Native slash commands shipped by the plugin (available as soon as it's enabled — `commands/` is auto-discovered):

| Command | Does |
|---------|------|
| `/vibeflow [request]` | Front door — delegates to the **vibeflow-conductor** agent (create/configure/verify/update/migrate the lab). |
| `/vf-new-lab [domain]` | Create a lab in any domain (instantiates a métier bundle if present). |
| `/vf-planning` | Lay down or refresh the `.planning/` backbone; answers "where are we?". |
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
| `v2.6.0` | 2026-06-11 | planning-core v1.1.0: freshness guard (`check-planning-state.sh`) + domain detection + opt-in bootstrap + non-dev worked example |
| `v2.7.0` | 2026-06-11 | + conductor (meta orchestrator/guardian): universal lab bootstrap (any domain), update propagation + migration, sub-agent escalation protocol |
| `v2.8.0` | 2026-06-11 | + 3 domain bundles (business-pilot / content / growth-per-channel) + conductor v1.1.0 (bundle-aware `vf-new-lab`, broken-pointer fix) |
| `v2.9.0` | 2026-06-11 | + native slash commands (`/vibeflow`, `/vf-new-lab`, `/vf-planning`, `/vf-calibrate`, `/vf-audit`) — explicit entry points for the methodology agents/skills |
| `v2.10.0` | 2026-06-17 | + kpi-analyst (business KPIs: deduced, deterministic, sourced) |
| `v2.11.0` | 2026-06-23 | planning-core v2.0.0: compartment topology + main-branch harmonization |
| `v2.12.0` | 2026-06-24 | vf-new-lab v1.3.0: Lab Factory, clarification-first |
| `v2.13.0` | 2026-06-29 | Init: contextual-doc externalization + native incarnation commands (ADR-042) |
| `v2.14.0` | 2026-07-04 | Scriptural governance: auto-wired hooks + DECISIONS canon + registry guards (ADR-043) |
| `v2.15.0` | 2026-07-05 | Bash registry guard: shell-bypass closure (BLK-006) |
| `v2.15.1` | 2026-07-05 | Read guard: window bounded by VALUE, not presence (BLK-007) |
| `v2.16.0` | 2026-07-05 | Machine-enforced native agents + context-loading doctrine (ADR-044) |
| `v2.17.0` | 2026-07-07 | + mobile-test + mobile-test-team (autonomous mobile test→fix loop), dev-orchestrator v1.2.0 (vf-decide + autonomous guardrails), reference v2.3.0 (Pattern 12), multi-agent engine support |
| `v2.18.0` | 2026-07-07 | Release discipline (`vf-internal` convention: internal workers get no incarnation command; conductor v1.7.0) + repo tagging rule & guard (`scripts/check-release-tag.sh`, path-scoped rule) |
| `v2.19.0` | 2026-07-07 | `/vf-update` command + SessionStart update banner: one-shot two-layer update (plugin marketplace cache + installed modules), latest detected from GitHub tags (conductor v1.8.0) |
| `v2.19.1` | 2026-07-07 | Fix: `vf-update` + docs use the fully-qualified `vibeflow@vibeflow-os` id for `claude plugin update` (bare name can fail "Plugin not found" on a stale catalog cache), with troubleshooting note (conductor v1.8.1) |
| `v2.19.2` | 2026-07-07 | Fix: `/vf-update` now enforces the mandatory baseline — a `mandatory` module published after a lab's setup (e.g. `conductor` on a pre-v2.13.0 lab) was skipped forever, so its scripts & hooks (the SessionStart update banner) were never wired; `update` also re-syncs governance for up-to-date modules (idempotent) (conductor v1.8.2) |
| `v2.20.0` | 2026-07-07 | Dev doctrine milestone: `software-architecture` **v1.3.0** = the dev-philosophies home (DRY/KISS/YAGNI added, Clean Architecture/Clean Code named, TDD card, **Nyquist + Decision Coverage gates absorbed**); module `feature-dev-gates` **removed** + engine cleanup of retired modules (orphan rule cleaned on `update --all`, test T7); `audit-architecture` **v1.0.1** (Instance C de-duplicated, legacy description fixed); `reference` single source for the 3 enforcement axioms |
| `v2.21.0` | 2026-07-08 | + **design-orchestrator** v1.0.0: router agent `vibeflow-design` + `/vf-design` verb (plain-language design intent → workflow), **stack-agnostic** (web/mobile/desktop), design toolchain piloted behind the scenes with graceful degradation; `dev-orchestrator` **v1.3.0** routes design phases to `/vf-design` and installs `design-orchestrator` by default (`requires`) |
| `v2.22.0` | 2026-07-08 | **Doc-research-before-debug (ADR-045)**: mandatory documentary-research phase (context7 + GitHub issues / release notes) **before** intensive empirical debug, whenever a bug touches a lib/framework/native/OS-SDK version or a fix already failed. New canonical path-scoped rule `doc-research-before-debug` (`software-architecture` **v1.4.0**), referenced — not duplicated — by `vf-debug` (pre-step) + `vibeflow-dev` routing + 6th autonomous guardrail with `maxResearchRoundsPerFlow` (`dev-orchestrator` **v1.4.0**), the mobile test loop (`vf-test-orchestrator` gate + `vf-app-fixer` `doc-research-required` escalation, `mobile-test-team` **v1.1.0**), and the `debugger` template Phase 0 (`reference` **v2.4.0**); new machine check `check-debug-research.sh` wired into validator Phase 2 (`conductor` **v1.9.0**, `validator` **v1.2.0**) |
| `v2.23.0` | 2026-07-09 | Mission manager team (ADR-046): vf-dev-manager + specialized workers (minimal-context tree), mission detection in the router, size-based vf-auto dispatch (dev-orchestrator v1.5.0) |
| `v2.24.0` | 2026-07-11 | skill-creator added to the conductor install baseline (ADR-047): the sole authorized skill-creation channel is now installed by default via the conductor's transitive closure — fixes `vf-new-lab`'s fan-out to a never-installed subagent (conductor v1.10.0) |
| `v2.25.0` | 2026-07-16 | Systematic domain orchestrator + governance hardening (ADR-048/049/050): `vf-new-lab` lays down a domain orchestrator from ≥2 domain agents + mission-loop skill; isolated memory backups with integrated rotation; planning hooks (index-first read at start, blocking update at end) (conductor v1.11.0) |
| `v2.26.0` | 2026-07-19 | Lab-derived MCP allowlist for executing agents (ADR-051): subagents now see the project's MCP servers (XcodeBuildMCP, mobile-mcp, business DB…) via the `vf-mcp-consumer` flag + idempotent install-time injection from `.mcp.json`; `gsd-executor` patched post-GSD-install (dev-orchestrator v1.6.0, mobile-test-team v1.2.0, conductor v1.11.1) |
| `v2.27.0` | 2026-07-20 | Session-attributed planning guard (ADR-050 amended) + global hardening of the harness hooks (29 findings fixed, 282 checks green) (planning-core, software-architecture, conductor) |
| `v2.27.1` | 2026-07-20 | Hardened agent gate (2nd wave of the conductor hooks audit: YAML parser, fail-closed anti-bypass, lab scope, debug-research safety net) (conductor v1.11.3) |
| `v2.28.0` | 2026-07-22 | Memory-swarm R&D shipped (ADR-052/053): consolidator **v1.6.0** living-memory pillar (per-entry `knowledge/` layer, category half-life decay + non-destructive supersession, `decay-pass.sh`); dev-orchestrator **v1.7.0** swarm control-flow (single-driver lock + ready/blocked DAG with `tree` render + typed worker reports, scope-robust script resolution); conductor **v1.12.0** scope-aware legacy detection + SessionStart nudge; mobile-test-team **v1.3.0** typed reports; engine uninstall fix (nested skills + tests) |

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
