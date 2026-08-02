# What is a lab?

<!-- vf-manual:lang -->
[Français](../../fr/02-concepts/qu-est-ce-qu-un-lab.md) · **English**
<!-- /vf-manual:lang -->

"Lab" is VibeFlow's single most-used word — "it builds labs", "your lab", "a fresh lab", "lab
altitude" — yet until now it was never actually defined anywhere in this repo. This page settles
it plainly, no dodging.

## A lab, materially

A **lab** is a folder on your disk, tied to a Claude Code **scope** (see
[choosing-your-scope.md](../01-get-started/choosing-your-scope.md)), in which VibeFlow has laid down
three things: a **constitution** (`CLAUDE.md`, what this folder is and how work happens in it),
one or more **agents** specialized in your line of work, and a **memory** that starts empty and
fills up with use. That's the whole definition — not an abstract idea, a real folder with real
files inside it.

A lab is **not necessarily a git repository**. Two examples of a different nature make that clear:

- **`vibeflow-os` itself** is a dev lab: a git repo, a root `CLAUDE.md`, agents under
  `plugin/*/agents/`, a working memory kept under `.planning/` by the GSD engine. The dev cycle
  runs on commits and branches.
- **Karim's lab**, the independent fitness coach from
  [your-first-lab.md](../01-get-started/your-first-lab.md), is a non-dev lab: a folder with a `CLAUDE.md`
  summarizing his line of work, one or two agents for client follow-up, a memory that capitalizes
  what works from one client to the next — **with no git repository at all**. Nothing to commit,
  nothing to deploy: just a living workspace.

What both share: opening that folder in Claude Code gives you agents that already know that
folder's business, without having to re-explain it every session.

### What you'll find in any lab

Whatever the line of work, the three material elements always show up, in a shape adapted to that
work:

- **The constitution** — a short `CLAUDE.md` answering three questions: why this lab exists, what
  it contains, how work happens in it. It's the one document every contributor, human or agent,
  is expected to read before starting.
- **The agents** — one or more specialists in the lab's line of work, each with a precise mandate.
  A dev lab often has several (coder, reviewer, auditor); a freshly created express lab may have
  only one or two.
- **The memory** — registers that capitalize what gets decided, learned, and blocked, so a new
  contributor can understand a past decision by reading the matching entry, instead of having to
  rebuild the context from memory. The precise vocabulary of these registers is covered in this
  theme's glossary.

## What turns a folder into a lab

Before `/vf-new-lab` or `/vibeflow-install` runs, a folder is just a folder — empty, or holding
whatever files happen to be there. What **turns it into** a lab is VibeFlow actually writing the
three elements above: the constitution, at least one agent, and the seed of a memory. A folder
with only a hand-written `CLAUDE.md` scribbled in isn't a lab in VibeFlow's sense yet — it's
missing the agents and the structured memory. It's a material test, not an intention: either the
files are there, or they aren't.

That construction is described in full, down to the exact inventory of files written to disk, in
this manual's `07-sous-le-capot` theme — this page does not duplicate it here.

## Dev lab, non-dev lab, and what a lab is not

**A dev lab** adds a layer that non-dev labs don't have: the GSD planning engine (`.planning/`), a
tooled scope → plan → execute cycle, and a convention where every step ends with a commit. You can
spot it by the presence of the `dev-orchestrator` module and its external dependencies, detailed
in this theme's next page, covering how VibeFlow, GSD, and Superpowers relate to each other.

**A non-dev lab** (content, business, growth, or any line of work with no dedicated module) relies
on the `planning-core` module for its own tracking baseline — no GSD-format `.planning/`, no
mandatory notion of a commit. Karim's lab is one example: its memory is very much alive, but
nothing in it resembles a software development cycle.

### A third example, to cut off any ambiguity

Karim's lab might suggest "non-dev lab" means "solo lab, no coordinated agents." That's not the
case: a content lab that installs the content bundle gets a complete team — a mission manager,
cloistered specialist agents (strategist, writer, repurposer), a read-only clarity judge — without
ever touching the GSD engine or a git repository. How complex a lab is (how many agents, how much
memory, how much coordination) is therefore independent from the dev/non-dev question: the two
axes cross freely.

**What a lab is not:**

- **A lab is not a generic Claude Code project.** Any folder opened in Claude Code is technically
  a "project" to the tool — that alone doesn't make it a lab. A lab is a project *in which
  VibeFlow has laid down its structure*.
- **A lab is not a module.** A module (see
  [modules-and-bundles.md](./modules-and-bundles.md)) is a capability VibeFlow knows how to
  install; a lab is the place where those capabilities get installed and actually act.
- **A lab is not fixed.** It grows: new capabilities get added, its memory thickens, its agents
  specialize. `/vf-new-lab`'s express mode lays down a deliberately minimal, incomplete first
  version, designed to grow later.

Keep the simplest test in mind: "were a CLAUDE.md, an agent, and a memory actually laid down in
this folder?" If yes, it's a lab. If not, it's a folder waiting to become one.

<!-- vf-manual:nav -->
[← Previous](../01-get-started/installation-troubleshooting.md) · [↑ Contents](../README.md) · [Next →](../02-concepts/modules-and-bundles.md)
<!-- /vf-manual:nav -->
