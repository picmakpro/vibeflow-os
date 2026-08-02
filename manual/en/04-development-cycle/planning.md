# Planning

<!-- vf-manual:lang -->
[Français](../../fr/04-cycle-de-dev/planifier.md) · **English**
<!-- /vf-manual:lang -->

The plan is the least spectacular document of the cycle and the most profitable one to read. It's
the last moment where correcting a trajectory costs one sentence. Past that point, correcting costs
code already written.

A phase plan takes the scope produced by [framing](./framing-an-idea.md) and turns it into an
ordered sequence of tasks: which files get touched, in what order, and — most importantly — **how
we'll know it worked**.

## What's inside, and why it's chopped up

A plan isn't written as one block. It's cut into tasks, and each task is meant to stand alone: it
has its files, its action, and its verification criterion.

That split isn't cosmetic. It buys three concrete things. First, it allows **one commit per task**:
your repository's history tells the story of the work instead of delivering an opaque four-hundred
line block. Second, it allows **resuming mid-way**: if a session stops at task three of six, the
next one restarts at four, not from scratch. Third, it makes failure **locatable**: when something
breaks, you know which task broke it.

Each task carries a success criterion that must be **verifiable**, not declarative. "The form
works" isn't a criterion. "Submitting the form with an invalid email shows the error message and
sends no request" is one. That requirement is what stops an execution from declaring itself done on
an impression.

The plan also carries what it doesn't do: ideas deferred during framing stay deferred, and the plan
says so. If you see a task in the plan handling an idea you explicitly postponed, that's a signal —
raise it.

## What you must check before you start

Here's the read-through that pays. It takes five minutes and often saves you several hours.

- **Is the stated objective really what you wanted?** Re-read the plan's first sentence and compare
  it to the intention you had in mind. It's the dumbest check and the one that catches the most
  errors.
- **Are the success criteria verifiable?** If one of them can't be observed by anyone other than
  its author, it will be useless.
- **Does the list of touched files surprise you?** A file you didn't expect is either a useful
  discovery or a misunderstanding. Both deserve a question.
- **Is any task spilling outside the framed scope?** That's the classic creep. It reads very
  clearly on the page and very poorly after the fact.
- **Does anything missing jump out at you?** A forgotten data migration, an unhandled error case,
  an effect on another part of the application. You know your product better than any code
  analysis.

To request a change, just say it: "task three should also cover the case where the field is empty",
"drop the notifications part, we said later". The plan gets rewritten rather than patched at the
edges, and you can read it again. Until you say go, nothing is executed.

## Plan review, and plans that are too big

**Plan review.** Before a structural plan is executed, a reviewer who didn't write it goes through
it. The principle is simple and as old as the hills: you can't be both judge and party. Someone who
has just written a plan is attached to it, and re-reading it themselves only reveals the obvious
mistakes — not the blind spots. A fresh reviewer, discovering the plan without knowing the
reasoning that produced it, sees what the author can't.

What that changes for you: the plan you're reading has already taken a critique. The remarks and
how they were handled are visible. It doesn't replace your own read-through — the reviewer checks
internal coherence and soundness, it doesn't know whether the result is what you wanted. Only you
know that.

**Plans that are too big.** Sometimes a step turns out to be larger than expected at planning time.
When that happens the plan is **split** into several plans running in sequence — never shrunk in
scope. The distinction is essential: silently shrinking the scope would hand you something
incomplete while letting you believe it was finished. Splitting hands you the same thing, in
several passes, and you know it.

If you're offered a split into several plans, you can of course run just one and see. The rest will
wait without getting lost.

### Where the plan lives, and why that matters

The plan is a file, filed alongside the step's context in the project's tracking folder. It doesn't
live in the conversation, and that's essential: a conversation gets lost, a file doesn't.

Three practical consequences. You can **re-read a plan days later**, to understand why something
was done the way it was. **Another session** can execute a plan you had written yesterday, without
rediscovering anything. And the plan stays readable **after** execution, which makes it the best
point of comparison when you review the result — that's in fact the check recommended in
[shipping-and-reviewing.md](./shipping-and-reviewing.md).

It's also why it's worth having a plan corrected rather than mentally compensating for its flaws. A
corrected plan serves several times; a correction you keep in your head serves once, and only if
you remember it.

A well-read plan is the best investment in the whole cycle. It's the only stage where five minutes
of attention replace several hours of rework — and the only one where you still get to change your
mind for free.

Once the plan is approved, on to [execution](./executing.md).

<!-- vf-manual:nav -->
[← Previous](../04-development-cycle/framing-an-idea.md) · [↑ Contents](../README.md) · [Next →](../04-development-cycle/executing.md)
<!-- /vf-manual:nav -->
