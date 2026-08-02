# Gates and human validation

<!-- vf-manual:lang -->
[Français](../../fr/02-concepts/gates-et-validation-humaine.md) · **English**
<!-- /vf-manual:lang -->

This page carries the most important commitment VibeFlow makes to you. Read it early: it explains
what you're actually going to see happen — stops, requests for confirmation, motivated refusals —
and why those are signs the system is working, not that it's broken.

## The promise: nothing gets fixed or deleted without you

**No fix, no deletion, no materialization of a structuring file happens without explicit human
validation.** This isn't politeness — it's a rule applied systematically across all of VibeFlow:
detect and propose, yes; fix, delete, or materialize on its own, never.

You'll run into this promise in several concrete shapes, already seen elsewhere in this manual:

- A GSD engine migration is **proposed** in `/vf-update`'s summary, never applied automatically.
- An existing `.planning/`, even in a format the tooling no longer recognizes, **never gets
  silently rewritten** — the case is flagged, the decision stays yours.
- A business-line bundle module never sends a deliverable to a client without your validation
  first.

This promise has no toggle to turn it off. It applies even when a fix seems obvious to the agent —
especially then, actually, since that's exactly when the temptation to act alone is strongest.

### A concrete case: installing a third-party package

If an agent needs to install a dependency and the package fails or looks suspicious, it **never**
tries a similarly-named alternative on its own initiative — installing the wrong package by
substitution would be worse than installing nothing. It stops and asks you to verify the
package's legitimacy yourself before continuing. Same promise, applied to a concrete security risk
instead of a file in your lab.

## A script that refuses, rather than a paragraph that recommends

VibeFlow keeps this promise with **machine gates**, not with prose. Three convictions underlie it:

- **A guardrail not enforced by the machine doesn't exist.** A rule written in a `CLAUDE.md` or a
  doc, one an agent can ignore under pressure, isn't a guardrail — it's a wish. The only one that
  holds is *machine-enforced*: a script returning exit code 0 or 1, not advice.
- **A test net that doesn't run isn't a net.** Before any change to a project whose verification
  suite is broken, fix the net first — otherwise every following change moves blind.
- **No completion gets declared without executable proof.** "We'll check it by eye" is a
  hallucinated completion. The one tracked exception: a purely visual criterion, explicitly flagged
  for human review.

A **machine gate**, concretely, is a script like the one that checked this very page before it was
finalized: it returns a binary verdict, never an impression. Between two equivalent mechanisms,
VibeFlow systematically picks the one that **blocks** over the one that merely alerts — an ignored
alert protects no one.

## What you'll actually see

Three mechanisms translate this doctrine into observable behavior.

**Halt conditions.** An agent running autonomously stops dead, without trying to work around it,
the moment a precise trigger fires: an irreversible destructive action, a loop spinning without
measurable progress, a missing external resource, a gap between what was planned and what's
actually happening. The stop always comes with a structured message — what was in progress, what
triggered the stop, the current state, and concrete options you can arbitrate between in under a
minute. It's never an empty cry for help.

**The judge is never the author.** An agent evaluating a deliverable (code review, client quality
gate, audit) technically has **no write tool at all** — it can't fix what it's grading, even if it
wanted to. That's what guarantees a "return" verdict actually means something: it comes from a
perspective with nothing to gain from being lenient.

**A typed report, not free-form prose.** When a worker finishes, it returns a report with a closed
status (`passed`, `gaps_found`, `human_needed`, `blocked`) instead of a narrative summary.
`human_needed` always triggers an escalation to you — never an answer invented on your behalf.

**No claim without fresh evidence.** When an agent tells you a task is done, that claim always
comes with evidence produced in the current session — never a memory from a previous one. If you
see an agent re-run a check you thought was already done, that's not excessive caution: it's the
same rule applying.

**Business bundles' iron laws.** Every bundle carries at least one eliminatory rule, graded by a
fresh judge — no client send without human validation, no invented financial figure — that fails a
deliverable regardless of the rest of its score. That's this same promise, embodied this time in a
judge's rubric instead of a verification script.

Keep the right reading of these mechanisms in mind when you run into them: a stop, a request for
confirmation, or a motivated refusal isn't a failure of VibeFlow. It's this page's promise, kept in
real time right in front of you.

None of this makes VibeFlow slow to use day to day — most work runs straight through without a
single stop. These mechanisms exist for the moments that matter, not for every keystroke. The
signal worth watching isn't how often a stop happens, but how clear it is: a well-formed stop
resolves in a minute, a vague one costs ten times as much. If a stop ever feels vague to you,
that's worth flagging — clarity is the whole point of the mechanism, not an afterthought bolted
onto it.

If you came here from the glossary looking up "halt condition", "fresh judge", "machine gate", or
"typed report", you now have the full picture behind each of those four short definitions.

<!-- vf-manual:nav -->
[← Previous](../02-concepts/the-nine-principles.md) · [↑ Contents](../README.md) · [Next →](../02-concepts/glossary.md)
<!-- /vf-manual:nav -->
