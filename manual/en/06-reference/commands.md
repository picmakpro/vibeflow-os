# Commands

<!-- vf-manual:lang -->
[Français](../../fr/06-reference/commandes.md) · **English**
<!-- /vf-manual:lang -->

A command typed with a `/` isn't the product's front door. VibeFlow is built end-to-end so you can
just talk to it in plain language — "make this look better," "create a content lab," "check my
lab" — and whichever agent is listening routes itself to the right piece. The seven commands on
this page are **shortcuts**: they skip the step of phrasing a sentence when you already know
exactly which action you want to trigger. You can ignore this page entirely and never type a `/`
— nothing works worse for it.

This list was built by enumerating `plugin/commands/*.md` on disk, re-checked on 2026-08-16: seven
files, none anywhere else in the repo. That's the complete list by construction — there can't be
an eighth one missing from here.

## The seven commands

### `/vibeflow`

The generic entry point. Type `/vibeflow` followed by your request in plain language — "create an
acquisition lab," "check the lab," "update" — and it's passed as-is to the `vibeflow-conductor`
agent, which routes it to the right action. Useful when you don't yet know which of the six
commands below matches your need, or when your request touches several of them at once (say,
installing a module and then checking compliance). It never does the domain work itself — only lab
configuration.

*Example*: `/vibeflow create an acquisition lab` — the whole sentence after the command is passed
to `vibeflow-conductor` as-is, no intermediate rephrasing.

### `/vf-new-lab`

Creates a new lab, in any domain — not just software development. A short framing conversation
(domain, what you already know, constraints) precedes the build: agents, `.planning/` baseline,
memory registers and auditors tailored to the chosen domain, never a dev-shaped default. You use it
once per lab, at the very start.

*Example*: `/vf-new-lab acquisition` — the domain passed as an argument steers the framing
conversation directly, so you don't have to repeat it in the questions that follow.

### `/vf-planning`

Sets up or maintains the planning baseline for a **non-dev** lab — content, sales, growth, design,
casework, research. On a dev lab, it doesn't rewrite the project's own planning (that's the GSD
engine's job): it holds the "lab" altitude instead — the project index when a lab has several, and
the bridge to the right dev piece. It always starts by figuring out who already owns this lab's
planning, so two competing systems never end up stacked on top of each other.

*Example*: `/vf-planning what's drifting without a plan` — a plain-language argument, not a flag:
the command takes a full sentence rather than a syntax you'd have to memorize.

### `/vf-calibrate`

Checks whether VibeFlow's methodology has evolved since the lab was created, and proposes a
migration if it has — never applied without explicit human validation. Run it after updating the
plugin (see [`/vf-update`](#vf-update) below), or when a session-start signal flags a mismatch.

*Example*: `/vf-calibrate` on its own is enough in the general case; an optional argument lets you
specify what you want recalibrated if you already know.

### `/vf-audit`

Runs the full compliance audit of the lab: agent density, memory debt, technical infrastructure,
the audit structure of your process chains. Produces a dated report with a score and
recommendations — it **detects and proposes, it never fixes anything itself** without human
validation. This is the command to type when you want a status snapshot rather than an action.

*Example*: `/vf-audit` on its own covers all five audits; an optional argument narrows the focus to
just one of them if you don't need all five.

### `/vf-update`

Updates VibeFlow: first the plugin itself (Claude Code's marketplace cache), then the modules
already installed in this lab. Shows the changelog before acting and asks for confirmation.
Distinct from `/vf-calibrate`: this one pulls the new versions, the other one then adapts the lab's
structure if the doctrine has changed in the meantime — the two follow each other, in that order,
rather than replacing one another.

*Example*: `/vf-update --check` shows the version gap and the changelog without changing anything;
`/vf-update --modules-only` updates the modules without touching the plugin itself.

### `/vf-cockpit`

Launches the local, strictly read-only cockpit: a web page showing the current lab's `.planning/`
live — milestone phases, the active phase's plans, and the mission team's DAG with its driver
lock. Listens only on `127.0.0.1`, never writes to disk. Unlike the other six, it isn't lab
configuration — it's a viewer, and it delegates straight to the `vf-cockpit` skill rather than to
`vibeflow-conductor`.

*Example*: `/vf-cockpit` on its own starts the server on the default port; an optional argument
lets you pass a port or an explicit `.planning/` path.

## The boundary with skills

A command and a skill are not the same thing, even though nearly every command on this page does
delegate to a same-named skill once invoked. The difference is in how you trigger them: a command
is typed explicitly with a `/`, a skill fires on its own when your plain-language sentence matches
its description — you never need to know its name. [skills.md](./skills.md) covers that second,
much larger family, and it's deliberate that none of the entries listed here reappear there as a
command — `/vf-design` and `/vf-sketch`, in particular, are skills and have no file under
`plugin/commands/`, a distinction worth making explicit since the two look alike on the surface.

## Where this list comes from

Every command above corresponds to a real file under `plugin/commands/`, enumerated at the time
this page was written (2026-08-01, re-checked 2026-08-16) rather than copied from an existing
document — that's the rule that applies across this whole reference theme. If you want to check
for yourself, the command is `ls plugin/commands/*.md` from the repo root: the count should stay
at seven unless one has been added or removed since.

<!-- vf-manual:nav -->
[← Previous](../05-agent-team/specialized-teams.md) · [↑ Contents](../README.md) · [Next →](../06-reference/skills.md)
<!-- /vf-manual:nav -->
