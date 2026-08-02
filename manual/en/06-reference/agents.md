# Agents

<!-- vf-manual:lang -->
[Français](../../fr/06-reference/agents.md) · **English**
<!-- /vf-manual:lang -->

This page is a **lookup table**: you come here to find an agent by name, check its originating
module, or see whether it runs on opus or sonnet. It doesn't explain how a team actually works —
for that, go to [the-agents-that-ship.md](../05-agent-team/the-agents-that-ship.md), which walks
through the three families (agents you invoke, mission managers, internal workers) in depth. This
page doesn't repeat that explanation; it's just the full table, one row per agent.

An agent is never the entry point through which you phrase a request — that's the
[skill's](./skills.md) job, catching your plain-language sentence. The agent is what the skill
invokes afterward to do the work. If you're looking for "how do I trigger X" rather than "who is
X," you want the skills page, not this one.

## How to read the table

**Family** says how the agent enters the picture: *face* means you can invoke it directly, by name
or with a sentence that falls in its domain. *Manager* means it's never invoked directly — it's
autonomous mode or a domain router that deploys it once the size of the work justifies it.
*Worker* means it's never invocable at all, dispatched only by a manager with a precise mandate.
Scanning the Family column top to bottom before reading any single row is usually the fastest way
to tell whether a given agent is one you could ever talk to directly.

**Model** says which Claude model runs the agent — what that actually changes, and how you control
your spend, lives on [cost-and-models.md](./cost-and-models.md). Neither column is a promise
about behavior beyond the model choice itself — it's a fact you can re-derive from the same
frontmatter yourself, any time.

This table has no "installed in your lab" column: you'll only actually have the agents whose
matching module is present in your lab. The [module catalog](../03-modules/catalog.md) makes the
reverse link — module by module, rather than agent by agent.

## The 31 agents

| Agent | Module | Family | Model | Role in one sentence |
|---|---|---|---|---|
| `campaign-analyst` | growth-bundle | worker | sonnet | Computes CAC/ROAS per channel, GO/ITERATE/KILL verdict on a launched campaign. |
| `channel-strategist` | growth-bundle | worker | sonnet | Turns a brief into a channel/ICP strategy sheet. |
| `content-clarity-judge` | content-bundle | worker | sonnet | Judges a content piece's clarity, /100 rubric, read-only. |
| `copywriter-sequences` | growth-bundle | worker | sonnet | Writes the sequences and creatives for a validated campaign. |
| `growth-quality-judge` | growth-bundle | worker | sonnet | Anti-slop quality judge for campaign deliverables. |
| `quality-gate-client` | business-pilot-bundle | worker | sonnet | Judges any client-facing deliverable against a /100 rubric. |
| `skill-creator` | skill-creator | face | opus | Fabricates new skills in 5 phases, with a research loop. |
| `vf-app-fixer` | mobile-test-team | worker | sonnet | Fixes application code to make a failing Maestro test pass. |
| `vf-auditer` | dev-orchestrator | worker | sonnet | Security and technical-debt audit of a dev step. |
| `vf-business-commercial` | business-pilot-bundle | worker | sonnet | Qualifies leads, drafts quotes and sales follow-ups. |
| `vf-business-delivery` | business-pilot-bundle | worker | sonnet | Tracks delivery of sold work, prepares deliverables. |
| `vf-business-finance` | business-pilot-bundle | worker | sonnet | Prepares invoices, payment follow-ups, forecasts. |
| `vf-business-manager` | business-pilot-bundle | manager | opus | Drives a business mission: plan, dispatch, flow control. |
| `vf-coder` | dev-orchestrator | worker | sonnet | Drives a dev step's cycle (framing → plan → execution). |
| `vf-content-manager` | content-bundle | manager | opus | Drives an editorial mission: plan, dispatch, flow control. |
| `vf-content-repurposer` | content-bundle | worker | sonnet | Adapts a validated piece into multi-platform variants. |
| `vf-content-strategist` | content-bundle | worker | sonnet | Turns a brief into an editorial framing sheet. |
| `vf-content-writer` | content-bundle | worker | sonnet | Produces the final content deliverable from a validated sheet. |
| `vf-crafter` | design-orchestrator | worker | sonnet | Produces design specs and tokens for one screen or component. |
| `vf-design-judge` | design-orchestrator | worker | sonnet | Critiques one screen against the art direction, /100 rubric. |
| `vf-design-manager` | design-orchestrator | manager | opus | Drives a design mission: plan, dispatch, flow control. |
| `vf-dev-manager` | dev-orchestrator | manager | opus | Drives a dev mission: plan, dispatch, flow control. |
| `vf-growth-manager` | growth-bundle | manager | opus | Drives a growth mission: plan, dispatch, flow control. |
| `vf-reviewer` | dev-orchestrator | worker | sonnet | Reviews the code diff produced by a dev mission. |
| `vf-test-orchestrator` | mobile-test-team | manager | sonnet | Drives the test → fix → re-test loop of a mobile regression. |
| `vf-test-runner` | mobile-test-team | worker | sonnet | Writes and runs the Maestro flows for a mobile regression. |
| `vibeflow-conductor` | conductor | face | opus | Lab guardian: create, install/remove a module, verify, migrate. |
| `vibeflow-design` | design-orchestrator | face | opus | Art director: drives the whole design cycle in plain language. |
| `vibeflow-dev` | dev-orchestrator | face | opus | Dev router: detects intent, invokes the matching piece. |
| `vibeflow-kpi-analyst` | kpi-analyst | face | sonnet | Deduces and publishes the lab's real business metrics. |
| `vibeflow-validator` | validator | face | opus | Orchestrates the lab's 5 methodology-compliance audits. |

One notable exception in the Model column: `vf-test-orchestrator` drives a mission like the other
five managers, but runs on sonnet rather than opus — its loop (test → fix → re-test until budget
runs out) stays a bounded scope, without the open-ended trade-offs of a multi-domain battle plan.
Keep this name in mind if you compare two "manager" agents and their models differ: it's never an
inconsistency, it's the mission's actual scope that varies from one domain to another.

A last useful marker: every "worker" agent in this table explicitly declares, in its own file,
that it's internal and dispatched only by a manager. That's never a naming convention guessed from
the outside — it's written in black and white in each of them, and it's exactly why no
incarnation command gets generated for them.

## Where this list comes from

Built by enumerating `plugin/*/agents/*.md` (25 files, one level deep, which excludes the
blueprints under `content/agents/`) plus the 6 `AGENT.md` files at each module's root, on
2026-08-01 — thirty-one agents in total. To check for yourself from the repo root:
`find plugin -path '*/agents/*.md'` then `find plugin -maxdepth 2 -name 'AGENT.md'`. Each file's
frontmatter (`model:`, `memory:`) is the source of the Model column above, not a paraphrase — the
required fields an agent must carry are enforced by
`plugin/conductor/scripts/check-agents.sh`.

Split by model, counted on the same table: ten agents on opus (the five invocable "face" agents,
plus the five mission managers), twenty-one on sonnet (every worker, plus the one "face" agent
that isn't on opus — `vibeflow-kpi-analyst`). This split is what feeds
[cost-and-models.md](./cost-and-models.md) — it isn't restated there, just used.

<!-- vf-manual:nav -->
[← Previous](../06-reference/skills.md) · [↑ Contents](../README.md) · [Next →](../06-reference/cost-and-models.md)
<!-- /vf-manual:nav -->
