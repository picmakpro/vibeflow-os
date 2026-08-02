# Framing an idea

<!-- vf-manual:lang -->
[Français](../../fr/04-cycle-de-dev/cadrer-une-idee.md) · **English**
<!-- /vf-manual:lang -->

Framing is the first movement of the cycle, and the one most often skipped. That's a mistake you
pay for in cash: a badly framed idea produces a plan that looks right, an execution that runs
without error, and a result that isn't what you wanted. By that point the work is done — redoing it
costs a hundred times what the conversation would have.

Framing serves one purpose: turning "I want X" into a scope somebody else could execute without
asking you again. Including yourself, three weeks from now.

## How it goes

You open the subject in plain language — "I want to add a CSV export", "the signup form is too
long, it needs rethinking". The lab doesn't start writing code. It asks you questions, and this is
the moment to answer seriously.

The questions aren't generic: they're about what's ambiguous in *your* project. The lab reads your
code and your tracking before asking, so it won't ask what it can deduce. What it asks you is what
**only you** can settle: a trade-off between two acceptable behaviours, a constraint nothing in the
code reveals, a priority.

Three things come out of the exchange, and they're worth telling apart.

**A locked decision** is a choice you made explicitly. It's written down, with its reason. It won't
be reopened at execution time, and if something later contradicts it, that will be flagged as a
contradiction rather than silently absorbed.

**A deferred idea** is an idea that came up during the conversation, that's good, and that is
**not** in this step. It gets written down too, in a separate list. That's the mechanism that
protects you from scope creep: a deferred idea isn't a lost idea, so you have no reason to force it
in now "while we're at it".

**An assumption** is what the lab supposed in the absence of an answer, written in plain sight so
you can contradict it. If an assumption jumps out at you as wrong on re-reading, framing did its
job.

All of this lands in a context file, under the project's tracking folder, next to the step
concerned. It isn't a decorative artifact: it's what the plan will read next.

## An example exchange

Take "I want to add a CSV export". A real framing looks like this:

> **You** — I want to let people export the client list as CSV.
>
> **The lab** — I looked: the list is paginated at fifty entries and the search filter is applied
> server-side. Two things to settle. Does the export cover the displayed page, the full filtered
> result, or the entire database? And should a user who can only see their own clients be able to
> export other people's?
>
> **You** — The full filtered result. And no, everyone exports only what they can already see.
>
> **The lab** — Noted, both points locked. One more question: exporting the whole database can take
> a while. Do we accept the request blocking, or do we need a background export with a
> notification?
>
> **You** — Blocking is fine for now. We'll see if it becomes a problem.
>
> **The lab** — Locked: synchronous export. I'm filing "asynchronous export with notification" as a
> deferred idea, with your reason — to reconsider if volumes grow.

Four exchanges, and the scope is sharp. Notice the last point: the asynchronous export idea wasn't
thrown away, it was **filed**. That's exactly the difference between a framing and a list of
refusals.

## What you bring, what you can leave

**What you bring**: the intention, the constraints the code doesn't state (a client demanding a
particular format, a deadline, a past decision that mustn't be undone), and the arbitration when
two options are both valid. Nobody else can supply that.

**What you can leave**: the current state of the code, existing dependencies, how the project
already does similar things, the conventions in force. The lab will go find them.

A word on pacing: if you don't have the answer to a question, say so. An assumption owned and
written down beats an answer invented to keep the conversation moving — because a written
assumption is one you'll see again in the plan and can still correct. An invented answer becomes a
locked decision built on sand.

### Two framing mistakes that cost you

**Answering "whatever you think".** It's tempting when the question is about a technical detail
that feels unimportant to you. The trouble is that a question asked during framing is almost never
a detail: it's asked because two different behaviours follow from the two answers. If you have no
opinion, say "take the simplest one and note it as an assumption" instead — you get the same
result, but you'll see it written down and can still correct it.

**Framing three things at once.** A framing conversation covering the CSV export, the menu rework,
and a performance problem will produce a mushy scope and a wobbly plan. Separate them. Three short
framings beat one long one, and nothing stops you running them back to back in the same session.

Once framing is done, the next step is the [plan](./planning.md).

<!-- vf-manual:nav -->
[← Previous](../04-development-cycle/the-cycle-at-a-glance.md) · [↑ Contents](../README.md) · [Next →](../04-development-cycle/planning.md)
<!-- /vf-manual:nav -->
