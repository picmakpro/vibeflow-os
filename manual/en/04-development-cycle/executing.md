# Executing

<!-- vf-manual:lang -->
[Français](../../fr/04-cycle-de-dev/executer.md) · **English**
<!-- /vf-manual:lang -->

This is the long phase, and the one where you can go do something else. The approved plan is run
task by task: code gets written, checks get played, and each unit of work is committed before
moving to the next.

This page tells you what happens without asking you anything, what on the contrary stops to ask,
and how to read what scrolls past — including two behaviours that surprise you the first time you
see them.

## What runs on its own, what stops

**What runs on its own**: writing and editing the files the plan covers, running tests, linters,
type checks, fixing what fails, and committing each finished task. All of that is inside the
contract you approved when you approved the plan — asking again each time would add nothing.

**What stops to ask you** — and this is the part that matters:

- **A decision framing didn't settle.** The plan assumed something, the reality of the code says
  otherwise. Rather than choosing for you, execution stops and asks.
- **A destructive action.** A mass deletion, a history rewrite, anything that doesn't undo. That
  needs your explicit confirmation, every time.
- **A blocker that won't resolve.** After three unsuccessful attempts at the same point, the loop
  gives up instead of trying variants forever. You get the exact state, not a masked failure.
- **Scope drift.** If execution finds itself needing to touch files outside the plan, it stops and
  shows you the gap rather than absorbing it.

What those four have in common: they turn a silent slide into an explicit question. It's the same
principle described in
[gates-and-human-validation.md](../02-concepts/gates-and-human-validation.md).

## Two behaviours that surprise people

Neither of these is a bug. Knowing about them saves you from thinking something's wrong.

**Documentation research before debugging.** When a problem touches a library, a framework, a
native feature, or a version issue — or simply when a first fix has failed — execution **stops
coding** and goes to read the official documentation first. You'll see searches go by where you
expected code attempts.

That's deliberate. A model's default behaviour facing a library bug is to try things: change a
parameter, swap two lines, attempt another method. It sometimes works, it burns enormous amounts of
time when it doesn't, and above all it produces code nobody understands, including when it ends up
working. Reading the documentation first costs two minutes and replaces twenty minutes of
groping. If the search turns up nothing, only then does empirical debugging begin.

**Refusal on size overrun.** A code file reaching three hundred lines triggers a write refusal. Not
a warning: a refusal, enforced by a mechanical guardrail rather than an agent's good intentions.

The reason is specific to how work happens here. An overlong file is hard to hold in your head, for
you as much as for a model: edits become risky, side effects invisible. The threshold forces a
split before things get unmanageable. When you see it fire, execution will propose a split — that's
the moment to check the split makes sense for your domain, because it's the kind of choice that
goes better with you than without you.

## Reading the stream, and handling a failure

**What you see.** The stream shows the current task, the files being touched, the results of the
checks, and the commit produced at the end of each task. You don't have to read it all live. The
two things worth your eye are the **questions** (they're waiting on an answer) and the **commits**
(they tell you where the real work stands).

If you come back after being away, the useful question isn't "what got printed" but "what got
committed". The repository history is the most reliable summary of what actually happened.

**When a task fails.** The failure is made visible, never absorbed. You won't see a task declare
itself done with a test disabled or a success criterion quietly rewritten downward — that's an
explicit prohibition, and it's what separates an execution you can trust from one that tells you
what you want to hear.

Concretely, you get the exact point of failure, what was attempted, and the state of the
repository. Previous tasks stay committed: you don't lose successful work because of one task that
won't pass. You can then correct course, ask for a different approach, or postpone that task and
carry on with the next ones if they don't depend on it.

A final point on interruption: you can cut an execution at any moment without breaking anything.
Tasks already committed stay committed, and the plan on disk says where things stood. Resuming
later doesn't restart from the beginning — the work done is banked.

And one habit worth building: when execution asks you a question, answer it with the same care you
gave the framing. A question raised mid-execution is one the plan couldn't settle, which means it's
a real one. A hurried answer there produces exactly the kind of result you'll be tempted to blame
on the tool.

The same goes for interruptions you cause yourself: stopping to think is free, and it's much
cheaper here than three tasks later.

Nothing is lost by pausing — the commits are already there, and the plan on disk remembers the
rest.

Once execution is done, the most important movement for you remains:
[shipping and reviewing](./shipping-and-reviewing.md).

<!-- vf-manual:nav -->
[← Previous](../04-development-cycle/planning.md) · [↑ Contents](../README.md) · [Next →](../04-development-cycle/shipping-and-reviewing.md)
<!-- /vf-manual:nav -->
