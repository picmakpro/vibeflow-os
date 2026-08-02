# Module catalog

<!-- vf-manual:lang -->
[Français](../../fr/03-modules/catalogue.md) · **English**
<!-- /vf-manual:lang -->

This page lists the modules VibeFlow ships, each with **what it gives you** — not what it contains.
It was written by reading the `module.json` files present on disk, one per module: that's the only
source that never goes stale. You can redo that same reading yourself at any time, and you probably
should if you're reading these lines long after they were written.

What you will **not** find here: version numbers. Not one. This manual never quotes them, by
design — the reason is spelled out in [where-a-module-lives.md](./where-a-module-lives.md), which also
tells you where to read a module's real version in three seconds.

If the vocabulary (module, baseline, bundle, scope) isn't clear yet, start with
[modules-and-bundles.md](../02-concepts/modules-and-bundles.md) — this page assumes those words are
already yours.

## The governance baseline and its auditors

These seven modules form the baseline: `conductor` is the only one declared mandatory, the other
six arrive with it through the dependency chain. They produce nothing for your line of work — they
give the lab what it needs to create, check, and repair itself. Who pulls in whom is detailed in
[baseline-and-dependencies.md](./baseline-and-dependencies.md).

- **`conductor`** — the front door. This is what you call to create a lab, add or remove a module,
  check that everything holds together, or realign a lab after VibeFlow evolves. It doesn't do your
  actual work: it keeps the house standing.
- **`planning-core`** — the tracking baseline. It lays down the `.planning/` structure that lets a
  session pick up where the previous one stopped: project charter, requirements, trajectory, state,
  steps. It adapts to the lab's line of work instead of forcing a dev-shaped template on it.
- **`validator`** — the chief auditor. You call it when you want to know whether your lab is still
  aligned with the method: it orchestrates five complementary audits and proposes fixes, never
  applying them on its own.
- **`skill-creator`** — the capability workshop. When a gesture keeps coming back in your work,
  this module helps you turn it into a clean, tested, reusable skill.
- **`consolidator`** — the lab's memory. It keeps the decision, learning, and blocker registries
  tidy so they stay readable and searchable instead of swelling until nobody opens them.
- **`infrastructure-audit`** — the technical guardrail. It catches silent regressions: a hook
  broken by a Claude Code update, a script gone missing, an Anthropic convention that moved under
  your feet.
- **`audit-architecture`** — the audit-structure designer. Whenever a process turns a brief into a
  deliverable, this module derives the right control structure for it, whatever the line of work.

## Orchestrators and business teams

This is where production starts. These five modules are the ones that actually do the work — you
install one, two, or none depending on what you do.

- **`dev-orchestrator`** — the full development cycle. You speak plain language ("build this",
  "where are we", "run it autonomously") and the orchestrator routes to the right gesture. It also
  ships the dev mission team, able to carry a long mission on its own. A whole theme of this
  manual is devoted to it, further on.
- **`design-orchestrator`** — the same idea for design and UI. Defining an art direction, redoing a
  screen, critiquing a page, or fixing a typography detail. It produces generic specs rather than
  code welded to one framework. `dev-orchestrator` depends on it: installing dev pulls in design.
- **`content-bundle`** — the editorial team: framing, writing, repurposing, with a clarity judge
  that rejects a weak piece. Nothing is ever published without your say-so.
- **`business-pilot-bundle`** — the business team: sales pipeline, delivery, invoicing, with a
  quality gate on client deliverables. Nothing is ever sent without your say-so, and no financial
  figure is ever invented.
- **`growth-bundle`** — the acquisition team: channel choice, sequences, creatives, measurement.
  Every real send stays behind your gesture, and a campaign carrying an unsourced number fails the
  judge.

The three bundles have their own page: [business-bundles.md](./business-bundles.md). Which one to pick,
and whether to pick one at all, is the subject of
[choosing-your-modules.md](./choosing-your-modules.md).

## Specialized capabilities and documentation

These five get added case by case. Two of them carry an **experimental status** declared in their
own `module.json` — it's said here because it changes what you can expect from them.

- **`software-architecture`** — the architecture doctrine. It kicks in when you create or change
  code, when a file grows too big, or when you sense structural debt. It ships mechanical
  guardrails, not just advice.
- **`kpi-analyst`** — a lab's real indicators. It derives an indicator schema, validates that
  schema with you once, then extracts the values deterministically. No figure is invented: a value
  it can't find stays marked as not found.
- **`mobile-test`** *(experimental)* — actually running a mobile app on a simulator or emulator,
  playing a regression suite, and returning a report with screenshots. "Experimental" here means
  the module is waiting for its first genuinely green run to drop that label.
- **`mobile-test-team`** *(experimental)* — the autonomous loop on top of the previous one: test,
  fix, re-test until green or until the budget runs out. It depends on `mobile-test`.
- **`reference`** — the documentation module. It lays down neither agent nor script: it brings the
  VibeFlow methodology and its architecture patterns, to read when you want to understand *why* the
  framework is shaped the way it is.

One thing worth knowing as you read: these modules **do not all share the same documentation
structure**. Most carry a `README.md`, a `CHANGELOG.md`, and a `VERSION` in the same place, but a
few depart from it — including, ironically, two of the most structural ones. So don't assume a file
you found in one module necessarily exists in another; look at the module's folder, it will tell
you what it carries. It's the folder, not this page, that
has the final word.

<!-- vf-manual:nav -->
[← Previous](../02-concepts/glossary.md) · [↑ Contents](../README.md) · [Next →](../03-modules/baseline-and-dependencies.md)
<!-- /vf-manual:nav -->
