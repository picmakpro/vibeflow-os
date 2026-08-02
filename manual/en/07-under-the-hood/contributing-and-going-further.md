# Contributing and going further

<!-- vf-manual:lang -->
[Français](../../fr/07-sous-le-capot/contribuer-et-aller-plus-loin.md) · **English**
<!-- /vf-manual:lang -->

This page closes the manual. It doesn't teach you anything new about using VibeFlow — the previous
six themes covered that — it instead tells you how to read the repository itself if you want to
understand it more deeply, contribute, or simply report something that isn't working. Three
questions structure it: how to read this repository, what its internal folders contain, and where
to go once you're done with this manual.

## Reading this repository to understand or contribute

The VibeFlow repository is organized around two distinct audiences, and this manual belongs to the
first:

- **This manual, and the repository's `README`**, are written for you — a human installing and
  using VibeFlow. Everything here is written in complete sentences, with no undefined jargon.
- **`docs/` and `.planning/`**, by contrast, are the working memory of the repository's own agents
  and contributors — not yours, the ones evolving VibeFlow itself. You normally never need to open
  them to use the product; [where-to-find-what](../06-reference/where-to-find-what.md) already explains
  why in detail.

If you still want to read the source of a module, an agent, or a gate, nothing stops you: every
module lives under `plugin/<module-name>/`, with its own version history. That's exactly the
material the previous pages of this theme already showed you how to read — the install engine, the
gates, the doctrine — this page adds nothing new to that method, it just confirms how general it is:
everything that runs on your machine is readable before it runs.

### Contributing, concretely

Contributing to VibeFlow doesn't require knowing its internals in detail before you start — the same
doctrine that structures your own labs structures this repository: every module has its own version
history and its own boundary, the gates that protect your code protect this repository's own code
too, and a change follows the same cycle described in the
[Development cycle](../04-development-cycle/the-cycle-at-a-glance.md) theme — framing, planning, executing,
shipping. A good starting point, if you want to propose a change, is to start small: a doc fix, an
isolated skill, before a larger architectural change.

## What `docs/` and `.planning/` are

To be precise about what these two folders actually contain, without ever asking you to open them:

- **`docs/`** carries the repository's architecture decision registry — the full source behind the
  previous page of this theme — along with the methodology library and internal technical
  specifications. It's memory meant for whoever designs VibeFlow, not whoever uses it, though
  nothing in it is confidential.
- **`.planning/`** is the working memory of the planning engine that drives the repository's own
  development — roadmap, progress state, requirements, phases in flight. It's literally the same
  kind of folder a **dev lab** you create with VibeFlow gets for its own project (see
  [vibeflow-gsd-superpowers](../02-concepts/vibeflow-gsd-and-superpowers.md)) — except this one
  documents VibeFlow's own development, not yours.

Both folders stay readable if curiosity strikes — nothing is hidden — but they're never the
reference for normal product use. If you ever open `.planning/`, you'll find a familiar structure if
you've already used VibeFlow on a code project: it's literally the same format the planning engine
lays down for you, applied here to the product's own development.

## The manual's exit

**Where to report a problem.** A GitHub issue on the project's repository is the open channel today,
with no preformatted template — describe what you observed, what you expected, and what actually
happened. A reproducible case (the scope used, the module involved, the exact command) is always
more useful than a general description. This channel is also where you'll find out whether something
you ran into is a known limitation or a genuine bug worth fixing.

**What source-available allows.** VibeFlow's code and history are public and readable, but usage
remains subject to a license specific to the project rather than a standard open-source license —
exactly what that allows, and within what limits, is spelled out in the `LICENSE` file at the
repository root. This page doesn't summarize it any further: a license is a legal text, meant to be
read in full, not by excerpt.

**The trust promise**, already stated once in the repository's `README` in that exact form, isn't
repeated here word for word — you've already met it, embodied in detail, throughout this theme:

- Auditable scripts rather than a black box — covered in detail on
  [the-install-engine](./the-install-engine.md).
- An idempotent install, with an automatic backup before any overwrite — same page.
- Nothing runs before you've chosen it yourself, including automatic session-startup behaviors —
  covered on [anatomy-of-an-installed-lab.md](./anatomy-of-an-installed-lab.md) and confirmed by the
  fail-open principle detailed in [the-machine-gates.md](./the-machine-gates.md).
- Routing between agents and skills that relies on a real inventory of the disk rather than a
  marketing promise — covered in the [Reference](../06-reference/where-to-find-what.md) theme.

This repository also applies its own doctrine: the same gates that protect your code protect its
own, and a fresh install of the baseline is automatically verified in a blank environment before
every release — the best proof a promise holds is applying it to yourself first.

Now what? If a question remains after this manual, the most reliable starting point is always the
same: re-read the table of contents, pick the theme closest to your question, and if the answer
isn't there, the repository itself — code, gates, doctrine — is one `Read` away.

A summary of the path this manual walked, from its first theme to its last: you started from a
two-command install, crossed the concepts that give meaning to the words VibeFlow uses, the catalog
of available modules, the day-to-day development cycle, the mechanics of an agent team, the quick
reference for finding a command or fixing a hiccup, and you end here, under the hood, with what you
need to audit what actually runs on your machine. This manual stops at this last theme; the product
keeps going, and nothing stops you from coming back to a specific page whenever you need it instead
of re-reading everything.

That's it. Seven themes, two languages, one table of contents, and a repository that stays legible
the whole way down.

Enjoy VibeFlow.

<!-- vf-manual:nav -->
[← Previous](../07-under-the-hood/architecture-decisions.md) · [↑ Contents](../README.md)
<!-- /vf-manual:nav -->
