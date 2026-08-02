# Architecture decisions

<!-- vf-manual:lang -->
[Français](../../fr/07-sous-le-capot/decisions-d-architecture.md) · **English**
<!-- /vf-manual:lang -->

If this is the first time you've come across the term **ADR** ("Architecture Decision Record"),
here's what it is: a short, dated note that freezes **one** design decision — the problem
encountered, the options weighed, the choice made, what it changes. The VibeFlow repository keeps a
full registry of these, written for the repo's agents and contributors, not for you as someone using
the product. This page pulls out the fifteen decisions that **actually concern you** — the ones that
change something about what you see or what you can do — and tells you what each one changes,
without restating the full reasoning. The full registry, with the discarded options and their
reasons, lives in [`docs/ADR.md`](../../../docs/ADR.md) at the repository root, if you want to go
deeper on any one of them. This page groups them by what they concretely change for you, rather than
by their numbering — the number stays in parentheses so you can find it in the registry in an
instant.

## What protects you

Four decisions set limits VibeFlow never crosses, no matter the pressure of the moment or how
obvious a fix might seem.

- **Human validation before any irreversible action (ADR-031).** A fix, a deletion, the
  materialization of a structural file never happens without your explicit consent — the central
  commitment already detailed in
  [gates-and-human-validation.md](../02-concepts/gates-and-human-validation.md).
- **MCP access kept to the minimum needed (ADR-051).** An agent that compiles or tests your code
  automatically receives access only to the MCP servers **your own project** declares — never
  broader access, never a guessed or hardcoded server name (already covered on
  [anatomy-of-an-installed-lab.md](./anatomy-of-an-installed-lab.md)).
- **Guardrails that actually hold on Windows (ADR-054).** VibeFlow's protections are designed to
  behave identically on Windows, macOS, and Linux, with tests that verify an announced protection
  really blocks an attempt — not just that it exists on paper.
- **Memory that doesn't pile up into a mess (ADR-032).** What you decide, learn, and get blocked on
  in a lab is indexed and archived automatically across four distinct pillars, so it stays readable
  even after months of use.

## What constrains code and the agent's work

Four decisions shape how an agent produces code and behaves while working for you — the material
behind a refused write or a detour before a fix arrives.

- **The density charter (ADR-029).** The agents and skills VibeFlow ships stay deliberately short —
  that's why they load fast and cost little on every invocation, rather than accumulating content
  that's only used a fraction of the time.
- **The code architecture doctrine (ADR-035).** The code agents write for you follows design
  principles that favor short files and separated responsibilities — the doctrine enforced by the
  gates covered on [the-machine-gates.md](./the-machine-gates.md).
- **Native agent conformity (ADR-044).** Every agent you come across necessarily carries a valid
  frontmatter (name, description, model, memory scope) — that's what makes it routable
  automatically by Claude Code and checkable by a gate rather than by a manual review.
- **Documentation research before debugging (ADR-045).** Before an intensive diagnosis on a library,
  a framework, or native behavior, an agent is expected to check the official documentation first
  rather than guess a fix at random — something you'll sometimes notice as a detour before a fix
  lands.

## What governs a team mission and the ecosystem

Seven decisions cover the widest ground: how a long mission unfolds on your git repository, and how
VibeFlow positions itself relative to what surrounds it — an external planning engine, a third-party
tool already installed.

- **Lock-and-graph driving (ADR-053).** A long mission is driven by a single lock and a graph of
  ready or blocked tasks, never by improvisation — that's what makes it cleanly resumable after an
  interruption.
- **One branch per mission, never a direct commit (ADR-059).** A team mission always works on its
  own branch and finishes with a pull request **left open** — never a direct commit to your default
  branch, and never a merge decided by the agent itself.
- **Review as a first-class stage (ADR-060).** Code review becomes a step systematically posed by
  the mission's manager, graded by objective risk criteria — never an option a worker could silently
  skip.
- **One writer, one work tree (ADR-064).** Two actors working in parallel on your repository (two
  missions, or a mission and you in conversation) each get their own work tree — isolation becomes
  physical, rather than relying on everyone's good intentions (already covered in the Agent team
  theme).
- **One planning engine per code project (ADR-055).** VibeFlow's non-dev tracking baseline steps
  aside as soon as an external development engine is already in place on your project, rather than
  competing with it and producing two incompatible tracking formats.
- **No exclusivity claimed against a third-party tool (ADR-057).** If a VibeFlow capability overlaps
  with a third-party tool already present in your session (another debugging skill, another code
  review), VibeFlow documents the boundary rather than claiming to be the only legitimate path — the
  choice stays yours.
- **The external planning engine enters the scope of updates (ADR-058).** Its state is now part of
  the diagnostic `/vf-update` displays — no longer something you discover by chance long after it
  changed.

These fifteen decisions aren't frozen forever: each can be revised if real-world evidence challenges
it, with a new registry entry rather than a silent rewrite of the old one. It's the same discipline
applied to this manual itself: a decision gets documented, it never disappears without a trace.

If one of these fifteen decisions concerns you directly in a specific situation — a refused write, a
mission branch you didn't expect to see appear — the full registry cited above carries the entire
reasoning: the problem observed, the options discarded, and why. This page doesn't replace that, it
leads you to it.

One last thing worth keeping in mind before closing this page: none of these fifteen decisions was
chosen to impose a gratuitous constraint. Each answers a problem actually encountered, documented in
the registry — never a rule set by abstract principle. Doubting a constraint is legitimate; the
registry exists precisely so you can check for yourself, without taking anyone's word for it,
including this page's.

That's everything this page had to tell you — the registry takes over from here, with the
reasoning this page deliberately left out.

That's on purpose, so the reasoning never has to be maintained in two places at once.

<!-- vf-manual:nav -->
[← Previous](../07-under-the-hood/the-doctrine-and-its-patterns.md) · [↑ Contents](../README.md) · [Next →](../07-under-the-hood/contributing-and-going-further.md)
<!-- /vf-manual:nav -->
