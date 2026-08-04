<div align="center">

# VibeFlow OS

**English** · [Français](./README.fr.md)

**Claude Code is powerful. VibeFlow makes it reliable, frugal and governed.**

**Spec-driven** agentic orchestration for Claude Code: you speak plainly, an agent detects the
intent, runs the pipeline (scoping → plan → execution → proof), and **machine gates** verify —
not promises.

[![Version](https://img.shields.io/badge/version-2.47.1-2563eb)](./VERSION)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-plugin-d97757)](https://docs.claude.com/en/docs/claude-code)
[![Modules](https://img.shields.io/badge/modules-17-16a34a)](#-modules)
[![License](https://img.shields.io/badge/license-source--available-64748b)](./LICENSE)

[The dev cycle](#-the-dev-cycle--spec-driven) · [Missions](#-long-missions--the-team) · [Labs & design](#-beyond-dev--a-lab-for-any-domain) · [Memory](#-memory-that-holds) · [Install](#-install) · [Modules](#-modules)

</div>

---

📖 **New here?** The [User Manual](./manual/README.md) walks a human through installing,
understanding and running VibeFlow — no `.planning/` or `docs/` required.

---

## The problem

AI coding setups fail at scale for three reasons: **context rot** (quality degrades as the
context window fills), **improvisation** (the agent codes without a spec, verifies from
memory, validates itself), and **burned tokens** (everything in context, everything re-read,
everything on the premium model).

VibeFlow attacks all three: **disk is the source of truth** (specs, plans, state — not the
context window), **nothing is "done" without machine proof** (tests, gates, fresh judges),
and **every token has a job** (sonnet workers, digests, on-demand loading, parallel dispatch).

---

## 🔁 The dev cycle — spec-driven

Say _"add Google auth"_: the `vibeflow-dev` agent detects the intent and runs the GSD pipeline —
scoping, verified plan, atomic execution, read-only judges — leaving an artifact on disk at
every step, so the context can die without the project losing ground.

→ [The cycle, step by step](./manual/en/04-development-cycle/the-cycle-at-a-glance.md)

---

## 🤖 Long missions — the team

"Do steps 3 to 5, I'm back tomorrow morning." Past a threshold, a **mission manager** takes
over on the **team-kernel**: sonnet workers run in parallel, typed reports replace prose, and
anything that challenges intent or security **freezes the node** for a human — even at 3 AM.

→ [How a long mission holds together](./manual/en/05-agent-team/a-long-mission.md)

---

## 🧪 Beyond dev — a lab for any domain

VibeFlow is not a dev-only tool: it **manufactures labs** — governed workspaces for content,
growth, business or any other domain — on the same kernel, the same gates, and skills built
by `skill-creator` with an eval loop.

→ [What is a lab?](./manual/en/02-concepts/what-is-a-lab.md)

---

## 🧠 Memory that holds

A VibeFlow lab doesn't forget between sessions: indexed registries, agent memory that
capitalizes across sessions, and disk-first artifacts (`PROJECT.md`, `ROADMAP.md`,
`STATE.md`) mean any session restarts from a fresh disk, never a compacted context.

→ [Anatomy of an installed lab](./manual/en/07-under-the-hood/anatomy-of-an-installed-lab.md)

---

## 🏗 Architecture

A mandatory `conductor` baseline (team-kernel + machine gates) carries the domain
orchestrators — dev, design, mobile, three business bundles — plus governance modules
(`validator`, `consolidator`, `infrastructure-audit`). CI runs a "**fresh lab**" job: the
baseline installs into a blank lab and must pass its own gates with zero intervention.

→ [The machine gates](./manual/en/07-under-the-hood/the-machine-gates.md)

---

## 🚀 Install

Two commands, no clone, no config editing:

```bash
claude plugin marketplace add picmakpro/vibeflow-os
claude plugin install vibeflow
```

Then inside Claude Code: `/vibeflow-install` — pre-detected scope (one-tap confirmation),
module picker, dependencies resolved and recapped before anything is written. Update:
`/vf-update`. Details: [INSTALL.md](./INSTALL.md).

---

## 📦 Modules

17 modules, each versioned with its own `CHANGELOG.md`. At install: `conductor` is the
**mandatory baseline**, then one choice — *dev lab* or *tailor-made domain lab*. Each
module's README is its full documentation — same structure everywhere.

→ [Module catalog](./manual/en/03-modules/catalog.md) ·
[commands](./manual/en/06-reference/commands.md) ·
[skills](./manual/en/06-reference/skills.md) ·
[agents](./manual/en/06-reference/agents.md)

---

## 🔒 Trust

- **Source-available**: public code and history — see [LICENSE](./LICENSE).
- **Auditable**: bash + `jq`, every script covered by its suite (51 suites in CI),
  **idempotent** install with backup before overwrite.
- **The repo applies its own doctrine**: CI on push/PR (tests + strict gates) + a
  "**fresh lab**" job — the baseline is installed into a blank lab and must pass its own
  gates with zero intervention.
- **Zero plugin-level hooks**: nothing runs until you invoke it. Module governance hooks are
  written by `/vibeflow-install`, in plain sight.
- **Anti-hallucination by design**: routing relies on a factual index auto-generated from
  disk; incomplete modules are flagged `proposable:false`, never sold.

---

## 🧭 Versioning

**Semver per module** + tagged root version on every release (`check-release-tag` as a gate).
Full history: **[CHANGELOG.md](./CHANGELOG.md)** — the README keeps the last 3 entries:

| Version | Date | Change |
|---------|------|--------|
| `v2.47.1` | 2026-08-04 | **The skills index stops lying about its own provenance, and the history gets the entry a release had skipped.** Origin: the `@opengsd/gsd-core` engine update from 1.9.0 to **1.9.1**, and the question of whether the coupling still held. **It holds across its whole surface, verified rather than assumed**: the `^1` ceiling in `ensure-deps.sh` covers 1.9.1, the `--claude`/`--global`/`--local` flags all exist in the 1.9.1 installer, the commands actually called (`loop render-hooks`, `state`, `state record-session`, `roadmap analyze`) all exit 0, and the **declared capabilities are identical** across both versions — index regenerated from each tarball's own registry, 12 hook points, 35 stages, byte-identical output. The upstream delta lands on non-Claude runtimes and a third discoverability registry, not on the contract consumed here. **The one active defect**, found by checking: the `gsd-skills-index.md` header announced `@opengsd/gsd-core@1.9.0` — a **hardcoded literal** in `build-gsd-index.sh`, i.e. an auto-generated AND version-controlled file asserting a false provenance, in head-on contradiction with the doctrine its sibling script states in its own header ("no engine version is ever frozen into the logic"). The version is now **read** off the resolved engine under a single rule — the engine is the parent directory of the workflows source the dual-layout cascade already resolved — so it always describes the tree the index entries actually come from, with no second cascade to maintain. Three edge behaviours, each held by a test: VERSION missing or unreadable → the header **says** "(version inconnue)" instead of asserting a number; VERSION untrusted → bounded 200-byte read then restricted character class (a port of `check-gsd-engine.sh`'s guard), command substitution neutralised and never evaluated; **legacy** layout → the index names `get-shit-done-cc` rather than dressing a legacy engine up as `@opengsd/gsd-core`. `T1e` is **DISCRIMINATING by construction** (fixture `9.9.9-fixture`), discrimination proven both ways: 4 KO with the frozen literal restored, 165 OK / 0 KO after. Module suite 161 → **165 cases**. **History debt settled**: v2.47.0 had been tagged and published without ever receiving its root CHANGELOG entry — the same defect class as the Releases page stuck from v2.29.0 to v2.39.0. Module `dev-orchestrator` v2.11.1. **47 suites** green. |
| `v2.47.0` | 2026-08-04 | **The dev engine is explicitly coupled to GSD, and the driver lock stops opening while it recovers.** Two strands. (1) **Phase 23 — explicit coupling** (10 requirements `GSDC-01..10`, 9 done): the module reasoned as if GSD were a list of skills to call, whereas 1.9 is a **capability engine** that inserts its own stages — `grep -r "capabilit\|render-hooks"` on `dev-orchestrator/` returned **zero**. Shipped: a **single invocation path** (the bare-agent route silently disabled research, pattern-mapper, plan-checker, gap-analysis, waves, verifier, code-review, nyquist and secure-phase, and still reported `passed`), a **strict-allowlist flag doctrine**, a capabilities/hooks table that is **generated from the installed engine** rather than hand-written — so it can no longer drift in silence —, a **checkpoint contract relayed and never recomputed**, and **one turn budget per step** instead of two loops adding theirs up. `GSDC-08` ships as `[~]`: the `D-22` discrepancy (`gsd-debugger` present against an "no exception" decision **and** required by gate `T19`) is arbitration, not code. **Two RCEs closed**, one reintroduced by a new script through a security premise never propagated between plans, proven shut by replaying the full install from a booby-trapped repo — the trap is proven **read**, not silently avoided. Suite 102 → **161 cases**. (2) **A recovery race in `driver-lock.sh`** (`conductor` v1.19.1): recovering a stale claim **moved** the lock directory before recreating it, and the normal `mkdir` path — unable to tell "free" from "being recovered" — walked in. Up to **5 simultaneous winners** measured on 24 concurrent acquisitions, on macOS as well as Linux; two window-narrowing fixes measured **worse** than the original (8 and 6). The lock becomes a **symlink** replaced by `rename(2)`: never absent, so never apparently free. Recovery is serialised by a generation-named mutex and the staleness verdict is re-read after it. Old directory-form locks stay readable and recoverable. `T13` goes from 6 concurrents in one draw to **24 × 5 rounds**, both bounds guarded. Modules `dev-orchestrator` v2.11.0, `conductor` v1.19.1. **47 suites** green. |
| `v2.46.0` | 2026-08-01 | **Tracking stops lying, and two sessions can no longer walk over each other unknowingly.** Three strands. (1) **Documentation hygiene** (Phase 22): the doctrine had an *inbound* path (`ingestion-flow.md`) but no *outbound* one — `docs-flow.md` separates the 4 families GSD maintains independently and that we had collapsed into a single line, surfaces the meaning-bearing flags (`--verify-only` audit without writing *vs* `--force` regenerate), and `vf-design-manager` gains the same `docs` node as its dev counterpart, **by reference never by copy**. (2) **The ROADMAP gets the checklist the engine actually reads**: billed as "20 missing SUMMARYs", the real defect was that the ROADMAP had **never** carried the phase checklist — the only form `@opengsd/gsd-core` reads — so the engine saw **zero** completed phases out of 24 and produced false counters. The checklist covers the 20 summary-less plans of Phases 11-14 **without fabricating a single file**: `roadmap.cjs` lets the ticked box override the disk, "for phases completed before GSD tracking". Phases 23-25 regularised under the `gsd-alignement` milestone. **2 upstream issues filed** ([#2956](https://github.com/open-gsd/gsd-core/issues/2956), [#2957](https://github.com/open-gsd/gsd-core/issues/2957)). (3) **One writer = one worktree** (**ADR-064**): two sessions wrote to the same branch unknowingly on 2026-07-31. The finding "the lock guards the step, not the branch" was incomplete — `driver-lock.sh` is consulted **only by managers**, and the offending session wasn't one. ADR-064 settles what ADR-059 left open: isolation becomes **physical**, and `check-branch-claim.sh` (4 exit codes, advisory, `SessionStart`) carries the claim to ordinary sessions at last. A symlink false positive found inside the gate while building it, mutant killed. Modules `conductor` v1.19.0, `dev-orchestrator` v2.10.0, `design-orchestrator` v1.4.0. **46 suites** green. |
| `v2.45.0` | 2026-07-31 | **VibeFlow aligned on `@opengsd/gsd-core` 1.9.0** — origin: the engine update from 1.8.0 on 2026-07-31, delta established on the evidence (`npm pack` diff of both tarballs + live install check). The one active defect: `inject-mcp-tools.sh` discovered MCP servers from `./.mcp.json` only — a server declared solely at **global scope** (`~/.claude.json`, e.g. XcodeBuildMCP) was invisible, `--verify` returned `3` INDETERMINATE instead of flagging the gap. Fixed with a **union of two scopes** (project ∪ global, `--claude-json`/`VF_CLAUDE_JSON`), independent degradation per source, project-over-global precedence on collision. Also shipped: the upstream `estimate:`/`actuals:` contract relayed verbatim by `vf-coder`/`vf-dev-manager` (never a self-graded statistic); **ADR-061**, a written arbitration of the overlap between upstream cross-AI review lanes and the code-review stage shipped in 20-06 (two distinct objects, kept separate); the dated `named-dispatch` assumption recorded in `team-kernel.md`, cross-checked against `gsd-worktree-path-guard.js` (#1995, #2608 — verified conformant); the version debt purge 1.8.0 → 1.9.0 across 6 files, moving the string-literal test case (case 8) with the text it checks, never neutralising it; **ADR-062**, arbitrating the 2 uncabled 1.9.0 hooks (correctly absent in both cases); and **`check-state-integrity.sh`** (**ADR-063**) — a new anti-regression gate for `.planning/STATE.md`'s frontmatter, now wired into the CI `gates` job, closing the exact silent-regression class (`completed_phases`/`total_plans`/`completed_plans` decreasing within the same milestone) discovered after Phase 20's closure. Modules `dev-orchestrator` v2.9.0, `planning-core` v2.5.3, `conductor` v1.18.0 (unchanged, verified consistent). **46 suites** green, `check-agents --strict` green on the 6 agent directories. |
| `v2.44.0` | 2026-07-31 | **Review becomes a first-class stage, driven by the manager** (**ADR-060**): it leaves `vf-coder`'s internal cycle, which stops being judge of its own work — the manager dispatches `vf-reviewer` and owns the fix → re-review loop itself. Origin: the **second external audit report** of 2026-07-28 (third-party lab, iOS slice in 5 batches of which 2 parallelised by worktrees, ~90 commits, suite 177 → 331 tests), whose 4 findings were **verified against the evidence before opening** — 3 confirmed, 2 of them **more firmly than the report claimed**, 1 partly outdated. **ADR-051 revised on its single contested point**: the premise "review agents never compile" conflated **producing** a compilation verdict with **verifying** one. `vf-reviewer` gets a **named** MCP allowlist (`vf-mcp-tools`, grammar `<server>:<tool…>`) — never the server wildcard, least privilege preserved — and the revision carries **its price in writing** (~90 s more per review, one simulator slot). **The 4 judges' write barrier stops being a fiction**: the absence of `Write`/`Edit` from `tools:` was **silently reopened at runtime** by `memory: project` (proven by probe) — they now carry `disallowedTools: Write, Edit`, a real constraint, without a single line of the gate moving. `vf-design-judge`, the only one keeping `Bash`, **stops claiming a barrier it does not have** and names its blind spot: shell channel open, restraint that remains a prompt commitment. Three non-negotiable guardrails bound every relaxation, drawn from the audit's own numbers: **never reduce the number of tests** (measured: out of 90 s of build, tests weigh ~1 s — no leverage), **never lighten review on the product critical path** (5 blockers found in one day), and **no relaxation ever applies to a remediation diff** (9 then 5 then 4 defects born from the review fixes themselves). Also shipped: `--scope` and `review_regime` (frozen perimeters), `check-mission-invariants.sh` + `.planning/MISSION-INVARIANTS.md` (dead-zone gate), and explicit third-party hook scoping (`--third-party-prefix`). Modules `conductor` v1.17.0, `dev-orchestrator` v2.8.0, `design-orchestrator` v1.3.2, the 3 bundles v2.0.3. **46 suites** green, `check-agents --strict` green on the 6 agent directories. |
| `v2.43.1` | 2026-07-28 | **A team mission works on its own branch, never on the default branch** (**ADR-059**). As soon as a manager is dispatched (`vf-dev-manager`, `vf-design-manager`), it creates its branch **before its first commit**, keeps every commit there, and ends with a **PR left open** — it never merges, merging belongs to the user (ADR-031 applied to integration). Origin: on this very repo, an autonomous mission landed **32 commits straight on `main`**, pushed then tagged; the recourse for a bad mission was a mass `revert` of already-public history. On a branch, the recourse is **not merging**, and the PR provides the grouped review point that an end-of-mission report — written **by** the agent that did the work, and read too late — does not replace. The trigger is **dispatching a manager**, not the nature of the work: direct conversational work stays outside the rule. Five fallbacks guarantee a mission **never** fails for want of applying it (no git repo · no remote · no `gh` · **dirty tree = halt condition**, never a self-decided `stash` · target project's `CLAUDE.md` wins). Does not cover isolating parallel waves **within** a mission — only `isolation: worktree` would, a decision left open. Modules `dev-orchestrator` v2.7.1, `design-orchestrator` v1.3.1. |
| `v2.43.0` | 2026-07-28 | The GSD engine enters `/vf-update`'s scope (**ADR-058**): the `get-shit-done-cc` → `@opengsd/gsd-core` migration shipped in v2.39.0 reached **no already-equipped machine** — only fresh installs. Observed on a third-party machine: plugin current at 2.42.0, engine still at 1.42.3 laid down **12 days** earlier, with nothing in the interface saying so. Three chained causes, all closed. `detect_gsd()` returned true on the legacy layout through an `||` written for dual-layout tolerance, and turned that into a `skip`: it becomes a **three-valued** state (`absent`/`legacy`/`gsd-core`) where "legacy" is **actionable**. No update path ever called the install script: `check-gsd-engine.sh` (new gate, F13 contract) is now probed by `/vf-update` — and **before** its "VibeFlow is up to date" stop, without which a machine with a current plugin never saw the offer. The legacy cleanup message, previously reachable through `/vf-init` alone, becomes reachable and **accurate**: `npm uninstall -g` is offered only when the package is genuinely global, the empty tree left behind by the installer is included, and the state is captured **before** the install — since the upstream installer deletes the legacy `VERSION` itself, the message could otherwise never fire again. Trap recorded in plain words: the fork **restarts from zero**, so **1.8.0 < 1.42.3 in semver** — migration is decided on the **package name and the directory layout**, never on comparing numbers, and a test pins that exact pair. ADR-031 upheld throughout: detect and **offer**, never install or clean without consent. `ensure-deps.sh --migrate-engine` chains into MCP re-injection (the upstream installer files the ADR-051 injection as a "local patch" and erases `mcp__XcodeBuildMCP__*` from `gsd-executor`'s `tools:`), and `inject-mcp-tools.sh --verify` compares the final `tools:` against the servers in `.mcp.json`. That last one first shipped **inert** — called without `--force`, it excluded its own target and always exited 3 — a defect cleared by code review, the portability gate **and** the security audit, caught only by mutating the shipped block. |
| `v2.42.0` | 2026-07-28 | Startup signals for the dev engine: `dev-orchestrator` — the only structuring module with **no hook at all** — gains its first `hooks/hooks.json` fragment. Three read-only, advisory `SessionStart` scripts state FACTS and inject short self-carrying lines. `check-dev-bootstrap.sh` covers the whole start continuum in one script (silence · `onboard` when code has no `.planning/` · `bootstrap` listing what is missing · `gsd-engine` orientation when complete), the signals proven mutually exclusive by test. `discover-unintegrated-docs.sh --hook` aggregates the count **additively**, leaving its historical `grain<TAB>path` contract untouched; `check-doc-drift.sh` flags code commits outstripping doc updates past a tunable threshold (default 20). The `gsd-engine` signal closes the routing hole observed on 2026-07-27 — `planning-core` steps aside when GSD holds a project and nothing took over. Portability **proven by execution**: identical counters on macOS bash 3.2.57, Debian 12 and Ubuntu 24.04, which rules out the silently skipped test. Two tautological test cases found and killed by mutation. |
| `v2.41.0` | 2026-07-27 | Agent dispatch fully fenced: `check-agents.sh` now lints the **contents** of `tools:` — allowlist syntax and name existence, on `tools:` and `disallowedTools:` alike (invented agent names, unclosed parens and non-existent tools all passed `--strict` green until now; suite 38 → 58 axes). Severity is graded by what is verifiable regardless of the installed scope, so native types (`general-purpose`) and external `gsd-*` agents never turn a correct allowlist red — closed-world checking is an opt-in CI mode. Allowlists posted on the 3 dev workers after a double independent census. Doctrinal correction: in a subagent definition the runtime **ignores** the names in parentheses — an allowlist is a documented contract enforced by this lint alone, not a runtime sandbox. |
| `v2.40.0` | 2026-07-27 | Cross-team dev ↔ design collaboration under a single manager: `vf-dev-manager` inserts `craft:`/`critique:` nodes into a dev mission (design stage skipped and reported when no art direction exists), `vf-design-manager` gains an opt-in implementation stage with dual judge (art-direction re-score ∥ code review) and separate 3 + 3 anti-thrash budgets, `vf-auto` finally routes design-only missions to the design manager, and both managers carry `Agent(...)` allowlists (18 / 6 names) forbidding manager→manager nesting (a documented contract — see the v2.41.0 correction on what an allowlist actually enforces). Kernel untouched. |

<details>
<summary><strong>Methodology references (ADR / LRN)</strong></summary>

- **ADR-032** — 4-pillar memory consolidation system
- **ADR-035** — AI-Safe software architecture doctrine
- **ADR-053** — Swarm layer: driver lock + DAG + typed reports
- **ADR-055** — Altitude boundary lab planning ↔ dev engine
- **ADR-056** — Runtime support vigilance
- **ADR-057** — Tooled boundaries with third-party bricks
- **LRN-101** — "Minimal agent + composable skills" pattern
- **LRN-106** — Audit before fix

Main lab (private): [vibeflow-lab](https://github.com/picmakpro/vibeflow-lab) — structural changes are tested there before release.

</details>

---

## 👤 Authors

- **[@picmakpro](https://github.com/picmakpro)** — creator of the VibeFlow methodology and repo owner. Laid the project's foundations and remains the guardian of its doctrine: the governance backbone (`conductor`, `planning-core`, `consolidator`), the scriptural hooks and guards that keep every lab honest. VibeFlow's identity — governance enforced by tools, not by prose — is his.
- **Samuel Neveu — [@samuel-neveugall](https://github.com/samuel-neveugall)** — the project's driving force day to day: main contributor and release driver. Built the entire development side (`dev-orchestrator`, `design-orchestrator`, `mobile-test-team`), led the agentic pivot and the team-kernel, and steers the framework's evolution — including its migration onto the `@opengsd/gsd-core` engine.

## 📄 License

Source-available under a proprietary license — see [LICENSE](./LICENSE). Public code and
history; training students get a private-reuse right; redistribution and resale prohibited.
The `skill-creator` module reuses original Anthropic content under the MIT license.
