# Skills

<!-- vf-manual:lang -->
[Français](../../fr/06-reference/skills.md) · **English**
<!-- /vf-manual:lang -->

You don't type a skill — it fires on its own when your plain-language sentence matches what it
knows how to do. This is VibeFlow's real front door, far more than the six [commands](./commands.md):
you never need to know a skill's name to invoke it, only to say what you want. What you actually
need, then, isn't the technical names below but **the phrasings that trigger them** — that's what
this page foregrounds for each one.

This list comes from enumerating every `SKILL.md` file in the repo on 2026-08-01, module by
module — explicitly excluding the skill templates under
`plugin/reference/content/methodology/templates/skills/`, which aren't shipped skills but
blueprints for building new ones. The disk holds twenty, grouped here by their originating module:
you only have the ones whose module is installed — the [module catalog](../03-modules/catalog.md)
says which one brings what.

## The twenty skills, by module

### `installer`
**`vibeflow-install`** — the very first thing you do after installing the plugin. Triggers on
"install VibeFlow," "configure the modules," "add a module," "change scope," "uninstall a
module." It's also this module's only action: it never installs anything on its own at session
start — launch always stays manual.

### `conductor`
**`vf-new-lab`** — "create an acquisition lab," "set up a content lab," "I want a VibeFlow space
for [domain]." Full bootstrap of a new lab, whatever the domain.
**`vf-calibrate`** — "update VibeFlow," "recalibrate my lab," "is my structure up to date?".
Detects the gap between the lab and the methodology, proposes a migration.
**`vf-update`** — "update vibeflow," typically in reaction to the update-available banner shown at
session start. Updates the plugin, then the installed modules, under confirmation.

### `dev-orchestrator`
**`vf-dev`** — "help me move forward," "drive this for me," "handle this project." The default
development router: detects intent and invokes the right piece directly, no need to rephrase.
**`vf-auto`** — "do it all," "on autopilot," "overnight," "figure it out," "I'll be back tomorrow
morning, keep going." Chains framing → planning → execution step by step without continuous
supervision, with autonomous-mode guardrails.

### `design-orchestrator`
**`vf-design`** — "make this look better," "this is ugly," "what style should we go with,"
"critique this screen." Design entry point: art direction, redesign, scored critique, or targeted
craft depending on what your sentence asks for.
**`vf-sketch`** — "mock this up for me," "show me what this would look like," "sketch two or three
variants." Throwaway mockups meant to settle a visual direction before committing to production —
never final code.

### `business-pilot-bundle`
**`vf-business`** — "qualify this lead," "prepare the quote for X," "where's the pipeline at,"
"handle the client files on autopilot." Entry point for the business domain: from sales to
finance, through delivery.

### `content-bundle`
**`vf-content`** — "write a post," "draft the newsletter," "adapt this article for LinkedIn,"
"produce this week's pieces." Entry point for the content domain, from editorial framing to
multi-platform adaptation.

### `growth-bundle`
**`vf-growth`** — "launch a cold email campaign," "prepare the LinkedIn sequences," "analyze the
campaign results." Entry point for the growth domain, channel by channel.

### `planning-core`
**`vf-planning`** — "structure this lab's docs," "we're losing track of things," "index my
projects." The planning baseline for non-dev labs, and the "multiple labs" altitude on any lab,
dev included.

### `audit-architecture`
**`audit-architecture`** — fires as soon as you build a process that turns a brief into an output
and it feels like that output ships "without a check." Designs the matching multi-layer audit
structure — not just for code.

### `infrastructure-audit`
**`infrastructure-audit`** — automatic audit of the lab's technical infrastructure (hooks,
scripts, drift in Claude Code conventions), typically after a Claude Code update itself or via
`/vf-audit`.

### `consolidator`
**`consolidator`** — maintains the lab's structured memory: indexing, archiving, deduplication,
promoting a learning into a rule. Fires when a register grows too large, or during periodic
maintenance.

### `kpi-analyst`
**`kpi-analyst`** — "what are my KPIs," "update the numbers," "configure the indicators."
Deduces the lab's real business metrics and publishes them to a register — never a hand-typed
figure.

### `mobile-test`
**`vf-mobile-test`** — "test the app on the simulator," "run a mobile regression before the
sprint," "reproduce this mobile bug." Real recipe on a simulator or emulator, experimental status
as of when this page was written.

### `software-architecture`
**`software-architecture`** — fires as soon as you create or edit code, a file grows too large, or
you're planning a refactor. Applies AI-safe architecture doctrine (short files, clean boundaries)
with machine-enforced guardrails.

### `skill-creator`
**`skill-creator`** — "create a skill for X," "improve this skill." Fabricates new capabilities
for the lab, with an evaluation loop before delivery.
**`skill-creator-workflow`** — an **internal support** skill, not an entry point you trigger
yourself: it documents the five phases the `skill-creator` agent follows behind the scenes. You'll
never name it in a sentence.

## Two clarifications that avoid a mix-up

First, two of the skills above (`vf-design` and `vf-sketch`) can look like commands at a
glance — they aren't: neither has a file under `plugin/commands/`. See [commands.md](./commands.md)
for the real list. Second, a skill is never
an agent: the skill describes **when** to step in, and the agent (or team of agents) then does the
work once invoked — the agent reference lives on a separate page in this same theme, dedicated
entirely to that.

## Where this list comes from

Every skill above corresponds to a real `SKILL.md` file, enumerated on 2026-08-01 rather than
copied from an existing doc. To check for yourself: from the repo root,
`find plugin -iname 'SKILL.md' | grep -v reference/content` — the count should stay at twenty
unless a skill has been added, removed, or a template has drifted out of its templates folder.

<!-- vf-manual:nav -->
[← Previous](../06-reference/commands.md) · [↑ Contents](../README.md) · [Next →](../06-reference/agents.md)
<!-- /vf-manual:nav -->
