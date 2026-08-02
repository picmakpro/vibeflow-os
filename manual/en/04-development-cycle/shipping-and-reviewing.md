# Shipping and reviewing

<!-- vf-manual:lang -->
[Français](../../fr/04-cycle-de-dev/livrer-et-relire.md) · **English**
<!-- /vf-manual:lang -->

This is the most neglected movement of the cycle, and the one that decides the real quality of what
you keep. Execution produced code; it still needs reading by a machine, then by you, before it
enters your main branch.

This page contains the list of what **you** must look at. It's the most useful part of this manual
for anyone delegating development work: nobody else can do this read-through for you, and it takes
ten minutes.

## The review stage

After execution, the work produced goes through review before being considered finished. It isn't
an option you switch on: it's a first-class stage of the cycle, on the same footing as planning or
execution.

The review is done by a reader who didn't write the code. It reads the step's diff and reports what
it finds, sorted by severity: bugs, security problems, quality gaps, inconsistencies with the
project's conventions. If blocking fixes come back, they're applied and the diff goes through
review again. The loop has a ceiling: after three rounds without converging, it stops and hands you
the state rather than spinning forever.

What follows the review is documentation hygiene: the project's tracking gets updated (the step
moves to done), and the documentation touched by the change gets revised. Concretely, if you added
a command, the file documenting commands knows about it. You don't have to think about it, but you
do need to know it happens — that's why a step's diff sometimes contains documentation files you
never asked for.

A word on git: a long mission works on **its own branch**, never directly on your main branch, and
leaves its merge request open rather than merging itself. That's deliberate, and it's what makes
the read-through below possible. The detail of the mechanism — branches, isolated working copies,
what happens when two sessions run at once — is covered in the next theme, about the agent team.

## What you read before merging

Here's the list. It's deliberately short: a long list doesn't get done.

- **The whole diff, once.** Not line by line — skim it, hunting for what surprises you. A file you
  didn't expect, a deletion you didn't ask for, a modified configuration file. Surprise is the
  signal, not the syntax error.
- **What was deleted.** Additions read themselves; deletions don't. Look specifically at removed
  lines: that's where silent regressions and edge cases that existed for a reason hide.
- **The tests.** Two questions. Are there any for what was added? And has an existing test been
  modified or disabled? A test weakened to make a step pass is the costliest fault there is, because
  you pay for it later, on something else.
- **Hardcoded values and secrets.** An API key, a production URL, a credential, a path specific to
  one machine. It takes seconds to spot and avoids accidents.
- **The behaviour, for real.** Launch the application and perform the gesture concerned. A step can
  be green on every check and still not do what you wanted — checks verify what they were told to
  verify, not your intention.
- **The plan's success criteria.** Take them one by one and tick them off. This is the check that
  closes the loop with framing: you verify the result matches what you asked for, not just what was
  planned.
- **The commit messages.** A readable history is what will save you in six months. If a commit says
  "fix", now is the time to ask for better, not in six months.

If something's off, say it in plain language — "this function name is wrong", "the empty-list case
is missing". The correction goes back into the cycle; it doesn't get patched by hand in a corner.

## After the merge

Two gestures are worth it, and neither is mandatory.

**Look at what was deferred.** The ideas set aside during framing are still there. This is the
right moment to decide whether one of them becomes the next step, or can keep waiting. A deferred
idea nobody ever re-reads becomes a lost idea again.

**Ask where you stand.** "Where are we?" returns the project's state: what's done, what's left,
what's blocked. It's more reliable than your memory, and it costs one sentence.

### How long to spend on it, honestly

The temptation is to skip this read-through when everything is green. That's understandable and
it's a bad trade: green says the checks pass, not that the result is good. A test verifies what it
was asked to verify; it knows nothing about your intention.

A useful rule of thumb: spend on the read-through **roughly the time it would take you to redo the
work by hand if you found a problem in a month**, divided by ten. For a small step, that's five
minutes. For a change touching data or money, it's half an hour, and it's very well spent.

And if you genuinely only have two minutes, do just two things: look at **what was deleted**, and
launch the application to perform **the gesture concerned**. Those two checks catch the majority of
what matters, and they fit in the time it takes to drink a coffee.

Everything else on the list is worth doing when the change is bigger, touches money or data, or
goes out to people who aren't you. Scale the read-through to the blast radius, not to the number of
lines changed — a three-line change to a pricing rule deserves more of your attention than three
hundred lines of new
tests.

And if you'd rather not run this cycle step by step, there's a mode for delegating it entirely:
[autonomous-mode.md](./autonomous-mode.md). It removes none of the checkpoints above — it batches them.

<!-- vf-manual:nav -->
[← Previous](../04-development-cycle/executing.md) · [↑ Contents](../README.md) · [Next →](../04-development-cycle/autonomous-mode.md)
<!-- /vf-manual:nav -->
