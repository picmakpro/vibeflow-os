# Agents, skills, and commands

<!-- vf-manual:lang -->
[Français](../../fr/02-concepts/agents-skills-commandes.md) · **English**
<!-- /vf-manual:lang -->

Open `plugin/*/agents/` and you'll find dozens of `.md` files — but very few of them have a
matching command. That's not an oversight: it's a deliberate distinction between what you
**invoke** and what **works for you behind the scenes**. This page lays down the vocabulary; the
exhaustive lists (exactly which command, which skill, which agent exists) live in
`06-reference/`, not here.

Keep the order of magnitude in mind: seven commands against more than fifteen shipped skills and
twenty-two agents. That deliberate imbalance is the key to reading this whole page — most of what
VibeFlow does for you is **never** typed, it triggers.

## Three entry points: command, skill, agent

### A command, you type it

A **command** (`/vibeflow`, `/vf-new-lab`, `/vf-audit`…) is an explicit entry point: you type it,
it starts a precise action. VibeFlow ships six of them, each a gesture you deliberately choose —
create a lab, audit a lab, update, and so on.

### A skill, it triggers

A **skill** is a knowledge base that Claude Code loads when your intent, **expressed in natural
language**, matches its description — you don't need to know its name. Saying "help me build this
feature" is enough to trigger the `vf-dev` skill, without ever typing `/vf-dev`. That's why
VibeFlow ships far more skills than commands: the command is the deliberate gesture, the skill is
the answer to an intent. The rule governing this trigger is deliberately permissive: if a
situation matches a skill's description even 1% of the time, it should fire — a skill invoked
unnecessarily beats a relevant skill that never fires.

### An agent is a session with its own context

An **agent** is a separate Claude Code session, with its own mandate, its own allowed tools, and
its own context — split off from your main conversation. When a skill or command needs
specialized work done (writing code, judging a deliverable, auditing an architecture), it
**dispatches** an agent instead of doing everything in the same session: that keeps every context
small and focused on a single responsibility — that's the Core's P9 principle, covered further
into this theme.

## Orchestrator, worker, judge

Three roles recur across almost every VibeFlow team:

- **The orchestrator** plans and delegates, but **never produces** a final deliverable itself —
  it's a team lead, not a doer.
- **The worker** executes one precise task within a defined perimeter (writing, fixing, testing).
- **The judge** evaluates a deliverable a worker produced, against an explicit rubric, and **has
  no write tool at all** — it's technically incapable of fixing what it's grading, so it stays
  impartial (the detail lives in this theme's page on gates and human validation).

### A concrete example of the chain

On a dev team, `vf-dev-manager` (the orchestrator) receives a step to build, breaks it down, and
dispatches `vf-coder` (the worker) to write it. Once the code is produced, `vf-reviewer` (a judge)
reads it against explicit criteria and returns a verdict — never modifying a single line itself,
for lack of a write tool. If the verdict is a return, the manager re-dispatches `vf-coder` with a
targeted correction mandate. The manager itself never writes code: its job is to plan, distribute,
and reconcile the reports that come back.

## Why some agents have no invocation command

That's the question anyone asks the moment they open `plugin/*/agents/` and don't find their
commands: out of the twenty-two shipped agents, the large majority has **no** `/<agent-name>`
command tied to it. That's intentional, not a gap. An **internal worker** — for instance
`vf-coder`, which writes the code for a dev step, or `quality-gate-client`, the judge of business
deliverables — only gets dispatched by its orchestrator (`vf-dev-manager`, `vf-business-manager`…),
never directly by you. These agents carry `vf-internal: true` in their frontmatter, precisely so
no public command gets generated for them: they only make sense within the mandate their
orchestrator gives them, not used in isolation. You lose nothing by never invoking them yourself —
that's exactly how they're meant to work.

That reserve isn't just a naming convention: an orchestrator can only dispatch the exact list of
agents it declares in its own frontmatter — never an arbitrary agent of your choosing. `vf-internal:
true` and that closed list are two faces of the same guarantee: an internal worker stays in its
team's lane, never a standalone entry point you could call on its own and pull out of its intended
context.

### An acknowledged limit, not a hidden one

As of today, Claude Code has no native field that makes an agent strictly callable "only by
another agent, never by you." The guarantee described above (orchestrator-side allowlist +
`vf-internal` + a discouraging description) is a robust heuristic, not an absolute technical
barrier — a user who knows an internal worker's exact name could in theory force its invocation.
VibeFlow chooses to document that limit rather than claim a watertightness no current tool
actually guarantees.

In practice, you never need to know that name: the commands and skills documented in
`06-reference/` cover everything you're meant to trigger yourself. If an agent isn't listed there,
it's working for an orchestrator, not for you directly.

Keep the simple rule that sums up this whole page: type a command for a gesture you choose, let a
skill trigger on what you say naturally, and never try to invoke an agent listed nowhere — it has
a job to do, elsewhere.

<!-- vf-manual:nav -->
[← Previous](../02-concepts/modules-and-bundles.md) · [↑ Contents](../README.md) · [Next →](../02-concepts/vibeflow-gsd-and-superpowers.md)
<!-- /vf-manual:nav -->
