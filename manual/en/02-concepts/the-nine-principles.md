# The nine principles

<!-- vf-manual:lang -->
[Français](../../fr/02-concepts/les-9-principes.md) · **English**
<!-- /vf-manual:lang -->

VibeFlow follows **nine principles**, sourced from the canonical document `VIBEFLOW_CORE.md`.
That's the number that carries authority today: if you run into a mention of "seven principles"
elsewhere (in `VIBEFLOW_PHILOSOPHY.md` or `VIBEFLOW_EXPLAINED.md`), know that the canon itself
labels those as **historical** — an earlier version predating the additions of qualitative
evaluation (P8) and then modularization (P9). This page translates all nine for you, in the
language of usage, not of design. For the long version and the testable criteria, the canon stays
the reference — this page doesn't copy it.

## The nine principles, one by one

### P1 — Capitalize

Your lab forgets nothing: every structuring decision and every learning gets traced into a
searchable memory, with the full reasoning attached. In practice, you can understand why a choice
was made three weeks ago by reading a single entry, without reconstructing the conversation.

### P2 — Structure the context

Every agent only receives what it needs for its task, not an exhaustive briefing. You feel it in
an agent that answers in a focused way instead of drifting into context that has nothing to do
with what you asked.

### P3 — Orchestrate and execute

A mission manager plans and delegates; it never produces work itself. In practice: when a decision
falls outside an agent's mandate, it **stops and escalates it to you** instead of silently
extending its own scope.

### P4 — Clarify before executing

No work starts on a fuzzy instruction. Before a structuring action, VibeFlow asks questions or
waits for your validation — that's why a session sometimes opens with questions rather than
immediate execution.

### P5 — Verify in a loop

No "it's done" claim without evidence produced in the current session. You'll see commands
actually run, exit codes, files re-read — never a "this should work" without checking.

### P6 — Iterate in short cycles

Work moves forward in small cycles, each ending in a deliverable and a capitalization step, not in
one opaque multi-hour block. You can interrupt, resume, and see exactly where things stand at any
point.

### P7 — Transpose, don't copy

VibeFlow doesn't reuse dev vocabulary in a business lab: every line of work gets its own words.
That's why Karim's lab talks about "clients" and "sessions", never "sprint" or "feature".

### P8 — Evaluate cognitive quality

The quality of an AI-produced answer is **measured**, not assumed good because it sounds
convincing. That's what makes a fresh judge score a deliverable against an explicit rubric instead
of letting the producing agent grade its own work.

### P9 — Modularize for cognition

No file, agent, or document exceeds its useful cognitive capacity — one responsibility per unit, a
limit enforced by the machine. **This is the most indirect of the nine for you**: its observable
consequence isn't a behavior you see directly, it's a second-order effect — agents that stay
coherent over time instead of drifting or contradicting themselves across long instructions.
Stating that plainly rather than inventing an immediate benefit: P9 protects the reliability of
the system answering you, not an action you trigger yourself.

### A principle isn't a marketing number

Each principle is written in the canon as a **testable contract**: a binary criterion (met / not
met), not a vague intention. The version above gives you its consequence, not the list of
criteria themselves — that's deliberate, this page stays at the level of usage. If you want to
verify for yourself that a principle is actually applied on a given lab, the canon is what you
open, not this page.

## Why nine, never seven

The Core went through several editions: seven principles in v3 (pre-Core, dev-web only), eight
with the addition of P8-Evaluate (v4.0), then nine with the addition of P9-Modularize (v4.2,
originating from the AI-Safe software architecture doctrine). `VIBEFLOW_PHILOSOPHY.md` and
`VIBEFLOW_EXPLAINED.md` haven't caught up with these last two editions and still talk about "seven
principles" — the canon itself labels them historical. This manual doesn't fix those two files
(out of this phase's scope); it simply documents the version that carries authority today.

If you ever spot a tenth edition cited somewhere in the repo before this page has caught up, apply
the same rule you were just given: the canon rules, everything else has a date on it. The editions
cited above (v3, v4.0, v4.2) describe the canon's own history, not a module or plugin number — so
this page isn't freezing anything that concerns you directly. This distinction between the canon's
own edition number and a module's shipped version is worth keeping in mind across the whole
manual: one dates an idea, the other dates a piece of software on your disk. Confusing the two is
exactly how the old seven-principles pages went stale in the first place — they froze a count
instead of pointing at the canon.

<!-- vf-manual:nav -->
[← Previous](../02-concepts/vibeflow-gsd-and-superpowers.md) · [↑ Contents](../README.md) · [Next →](../02-concepts/gates-and-human-validation.md)
<!-- /vf-manual:nav -->
