# Modules and bundles

<!-- vf-manual:lang -->
[Français](../../fr/02-concepts/modules-et-bundles.md) · **English**
<!-- /vf-manual:lang -->

VibeFlow installs as building blocks. This page defines the installation vocabulary — module,
mandatory baseline, dependencies, business bundle, scope — **straight from disk**, never from an
approximate description: the full module catalog has its own theme (`03-modules/catalog.md`),
this page doesn't duplicate it and carries no hardcoded version number.

## Module, baseline, dependencies

A **module** is an installable unit: a folder under `plugin/` carrying its own `module.json`
(name, version, description, dependencies). It's the unit you turn on or off — each module adds
one precise capability (an agent team, a skill, a verification tool) without touching the others.

The `module.json` field that matters most is `requires`: the list of other modules this one needs
to work. For instance, the `conductor` module — the entry point of every lab — declares
`requires: [planning-core, validator, skill-creator]`. Installing `conductor` therefore
mechanically pulls in those three modules without you having to ask for them yourself: the
installer resolves the `requires` **transitive closure** and shows you exactly what's about to be
laid down before it does it.

Exactly one module currently carries `"mandatory": true`: `conductor`. That's a lab's **mandatory
baseline** — without it (and therefore without its dependencies), there is no lab in the sense of
[what-is-a-lab.md](./what-is-a-lab.md). Every other module is optional: you pick the ones
that fit your line of work.

### The transitive closure, in practice

Resolution doesn't stop at the first level. `conductor` requires `validator`; `validator` in turn
requires `consolidator`, `infrastructure-audit`, and `audit-architecture`. Installing `conductor`
alone therefore actually lays down seven modules on disk — never one more, never one fewer than
what the `requires` chain declares. You never have to walk that chain yourself: the installer's
resolver walks it and announces the full list **before** writing anything, so you know exactly
what's landing on your disk.

### Mandatory doesn't mean sufficient

The mandatory baseline gives you a lab **capable of governing itself** — creating, checking,
updating — but not yet a lab that's productive in any given line of work. `planning-core`, for
instance, is part of the baseline: it carries lab-altitude tracking regardless of the line of
work. But a dev lab only gets its real production capability by adding `dev-orchestrator` on top;
a business lab, by adding `business-pilot-bundle`. The baseline is the foundation shared by every
lab, not the capability that tells them apart.

## Business bundle

A **bundle** is a special kind of module: instead of adding a single capability, it lays down a
**complete team** ready to work for a given line of business — a mission manager, several
cloistered specialist agents, a read-only quality judge, and a simple entry-point skill. Three
bundles exist today: business, content, growth. Each declares the same core dependencies in its
`module.json` (`conductor`, `planning-core`, `consolidator`, `audit-architecture`, `validator`) —
a bundle installs **on top of** the baseline, never in its place.

An ordinary module adds a one-off capability (for instance, `mobile-test` knows how to run an app
on a simulator). A bundle adds a **way of working** — several agents that coordinate with each
other on a long mission, with a driver lock and typed reports (what that guarantees the user is
covered further into this theme, in the page on gates and human validation).

### One iron law per bundle

Every bundle carries at least one non-negotiable rule, enforced by its own fresh judge rather than
left to an agent's good will: the business bundle **never** sends anything to a client without
human validation and **never** invents a financial figure; the growth bundle blocks every real
send behind that same human gesture and rejects any campaign carrying an unsourced number; the
content bundle never distributes anything without human validation either. These aren't promises
written in prose — they're eliminatory criteria in each bundle's judge rubric, which fails the
deliverable regardless of the rest of the score.

### Scope, an independent notion

**Scope** is independent from picking modules: it's **where** VibeFlow writes what it installs
(account, project, or project-without-commits). The same set of modules can be laid down at three
different scopes for three different labs — scope doesn't change *what* you install, only *where*
it lands. The full detail of the three scopes and how to choose is covered in
[choosing-your-scope.md](../01-get-started/choosing-your-scope.md), not here.

## What this page deliberately skips

On purpose: no table of existing modules (the catalog lives elsewhere and gets derived from disk
every time it's read, never copied — thirteen out of seventeen module versions were already stale
in the old README by the time this page was written, proof that copying a version is a debt that
comes due). No hardcoded version number: this page points to each module's `module.json` and
`CHANGELOG.md` for up-to-date information.

If you want to know precisely what a module does before installing it, the most reliable source
stays its own `README.md` under `plugin/<module>/` — not a summary table elsewhere in the repo,
however tempting a quick glance at one might be. A module's README can be updated without anything
else needing to follow along.

That's the same reflex that should guide how you read this manual itself: whenever a piece of
information can go stale (a version, a module count, a list), this manual prefers pointing at
disk over freezing it into a sentence — the disk is always right; a copied number, sooner or
later, is not.

<!-- vf-manual:nav -->
[← Previous](../02-concepts/what-is-a-lab.md) · [↑ Contents](../README.md) · [Next →](../02-concepts/agents-skills-and-commands.md)
<!-- /vf-manual:nav -->
