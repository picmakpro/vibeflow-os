# The agents that ship

<!-- vf-manual:lang -->
[Français](../../fr/05-equipe-agents/les-agents-livres.md) · **English**
<!-- /vf-manual:lang -->

This page is the inventory of agents VibeFlow can lay down in your lab. It was built by listing the
agent files present on disk, module by module — not by copying a list written elsewhere. You'll
only have the ones whose module you installed; the [catalog](../03-modules/catalog.md) says which
one brings what.

Three families, and the difference between them matters more than the names. As of when this page
was written, this repository's disk carries thirty-one in total, spread across those three
families — a number that shifts with every module added, never fixed here as a promise.

## The agents you invoke

These are VibeFlow's "faces". Each sits at the top of a module, and you can talk to it directly —
either by naming it, or simply by phrasing a request that falls in its domain.

- **`vibeflow-conductor`** — the lab's guardian. Creating a lab, installing or removing a module,
  checking conformity, realigning after an update. Everything touching the lab's own configuration
  goes through it.
- **`vibeflow-dev`** — the development router. It detects what your sentence calls for and invokes
  the matching brick. It's the default interlocutor for the whole
  [dev cycle](../04-development-cycle/the-cycle-at-a-glance.md).
- **`vibeflow-design`** — the same role for design and UI, from art direction down to a spacing
  detail.
- **`vibeflow-validator`** — the auditor. It orchestrates several complementary audits and proposes
  remediations, never applying them on its own.
- **`vibeflow-kpi-analyst`** — the lab's real indicators, extracted deterministically.
- **`skill-creator`** — the skill workshop, for when a gesture deserves to become a capability.

You don't have to memorize these names. They're here so you know who you're talking to when reading
a report, and for the rare times you want to bypass routing and address one of them directly.

## The mission managers

A category of their own: they steer a long mission but aren't summoned like the previous ones. It's
autonomous mode, or the domain's router, that decides to deploy them when the size of the work
warrants it.

There's one per tooled domain: **`vf-dev-manager`** for development, **`vf-design-manager`** for
design, **`vf-content-manager`**, **`vf-business-manager`**, and **`vf-growth-manager`** for the
three lines of business, and **`vf-test-orchestrator`** for the mobile testing loop.

What they all have in common: they **produce nothing themselves**. They plan, distribute, read the
reports, and account for the result. If you see a manager writing code, that's a bug, not an
optimization.

Each of these six managers instantiates the same orchestration core — driver lock, mission graph,
typed reports — rather than reinventing its own team coordination. That's why a design mission
report reads like a dev mission report once you know the shared vocabulary, detailed in the
[glossary](../02-concepts/glossary.md).

## The internal workers, and why you can't call them

This is the largest family — a good twenty agents — and the only one you can't invoke. These are
the producers and the judges: the one writing a step's code, the one reviewing it, the one auditing
security, the one drafting a piece of content, the one scoring it, the one running tests on a
simulator, the one fixing the app to make them pass.

Each of these agents declares in its own file that it is **internal**. The consequence is
mechanical: no invocation command is generated for it. You won't find a `/vf-coder` in your lab,
and that's not an oversight.

The reason is simple. An internal worker receives its mandate from a manager: a precise scope, a
context summary cut to fit, and a reporting contract. Invoked directly, it would have none of that
— it would set off without knowing where it sits in the overall plan, without knowing what it must
not touch, and its report would go to nobody. The result would be worse than a plain conversation,
while looking more serious.

Two categories among them deserve naming, because you'll see them in reports:

**The quality judges.** Every business team carries one — for content, for client deliverables, for
campaigns — joined by the design judge and, on the dev side, the code reviewer and the security
auditor. All of them discover the finished work without having seen it made, and the quality judges
have no writing tools: they cannot fix what they criticize.

**The cloistered workers.** In the mobile testing loop, for instance, the one writing the tests
never touches the application code, and the one fixing the application never touches the tests.
That partition prevents the most tempting cheat there is: making a test pass by weakening it.

If you want to know exactly what an agent is allowed to do, open its file in its module's `agents/`
folder. It's readable prose, and it states in plain terms what it's forbidden from doing.

This list is never copied from a README or marketing copy: it comes from disk, every time it's
checked. That's deliberate — removing a module makes its agents disappear from your lab
immediately, and nothing in this manual should claim otherwise longer than it has to.

That's also why this page names no version numbers next to any agent: an agent's behavior is
whatever its file on disk currently says, not whatever a changelog entry once described.

The next page picks up where this one stops: it shows how these three families actually get to
work on a long mission — and what that means for you while it runs.

Keep the inventory in mind as you read it: the names above are what a mission report will name.

<!-- vf-manual:nav -->
[← Previous](../05-agent-team/why-a-team.md) · [↑ Contents](../README.md) · [Next →](../05-agent-team/a-long-mission.md)
<!-- /vf-manual:nav -->
