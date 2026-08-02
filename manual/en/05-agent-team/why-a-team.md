# Why a team

<!-- vf-manual:lang -->
[Français](../../fr/05-equipe-agents/pourquoi-une-equipe.md) · **English**
<!-- /vf-manual:lang -->

On a small task, a single session does the job perfectly well. On a long mission — ten steps, a
rework, a night of delegated work — it degrades. This page explains why, and what splitting the
work into roles concretely changes for you.

If the words "agent", "skill", and "command" aren't sharp yet, start with
[agents-skills-and-commands.md](../02-concepts/agents-skills-and-commands.md) — this page doesn't
redefine them.

This choice isn't eyeballed. The number of steps left is counted against your roadmap, compared to
a fixed threshold, and a team deploys as soon as it's reached — or as soon as you signal a duration
("overnight", "I'll check back tomorrow") even on a small scope, because the duration signal always
wins over the count. Below the threshold and without that signal, a single loop handles the request
directly: it's cheaper, and it's enough as long as the degradation described below hasn't had time
to set in.

## What degrades when one session does everything

Three things, and they always arrive in the same order.

**Memory fills up.** A session accumulates everything: the code it read, the exchanges, the errors,
the abandoned attempts. After a while, the important information from the beginning drowns under
the noise from the middle. What was decided at step two goes fuzzy by step eight — not forgotten,
but diluted to the point of no longer weighing on decisions.

**Attachment sets in.** A session that has written code has reasons to find it good: they're its
own reasons. Asking it to review its own work yields a complacent review — not out of dishonesty,
but because re-reading your own logic with the same logic can't reveal anything beyond typos.

**Scope slides.** Without someone holding the overall map, each step inherits the previous one's
context and drifts a little. After ten steps, the drift isn't little any more.

## The split into roles

A VibeFlow team answers those three problems with three distinct roles, each in its own session
with its own context.

**A manager steers.** It produces nothing itself. It reads the project's state, cuts the mission
into nodes, decides what can run in parallel, distributes the work, and reads the reports that come
back. It's the one holding the overall map, precisely because it doesn't get its hands dirty in the
detail of any one task.

**Workers produce.** Each receives a short mandate — not the mission's whole story, a compact
summary of what it needs to know. That's what keeps them sharp: a worker starting on thirty lines
of relevant context works better than a session dragging three hours of history behind it. They're
cloistered: the one writing the code doesn't write the tests, the one testing doesn't fix the app.

**A judge evaluates.** It discovers the finished result, without having seen how it was made, and
returns a verdict.

### The judge is never the author

That's the most important consequence for you, and it deserves to stand alone.

Across every VibeFlow team, the agent evaluating a deliverable is never the one that produced it.
It isn't a writing convention: it's enforced by the structure. The judge is dispatched in a fresh
session, it only sees the result on disk, and — for the quality judges — it doesn't even have
writing tools. It *cannot* fix what it criticizes; it can only flag it.

What that changes: the review you read isn't self-congratulation. When a report says "compliant",
that was observed by someone with no reason to find it compliant. And when a judge rejects a
deliverable, the correction goes back to the producer, then back past the judge — until green or
until the round ceiling.

It's the same principle as the plan review described in
[planning.md](../04-development-cycle/planning.md), applied this time to the result rather than to the
intention.

## What it costs you, and what it doesn't solve

Both are worth being honest about.

**It costs.** Several sessions means more machine work than one for the same task. The gain only
shows on a mission long enough for the degradation described above to actually happen. On a short
mission, a team is a handicap — which is why the lab only deploys one when the size warrants it, as
explained in [autonomous-mode.md](../04-development-cycle/autonomous-mode.md).

**It doesn't solve everything.** A well-organized team faithfully executes what it was asked. If
the framing was mushy, it will produce well-made work on the wrong thing, with more consistency
than a lone session. Splitting into roles protects against degradation, not against a wrong
starting point.

And one structural limit worth knowing: the coordination mechanisms between sessions are
**declarative**. They assume every actor consults them. A session that ignores them isn't stopped —
that's detailed, bluntly, in [a-long-mission.md](./a-long-mission.md) and
[branches-and-worktrees.md](./branches-and-worktrees.md).

None of this is a reason to distrust the mechanism — it's a reason to read the next two pages
before trusting it blindly on something that matters.

That's the trade this whole theme is about: less oversight per step, in exchange for reading the
few places where the mechanism tells you, plainly, what it doesn't guarantee.

<!-- vf-manual:nav -->
[← Previous](../04-development-cycle/autonomous-mode.md) · [↑ Contents](../README.md) · [Next →](../05-agent-team/the-agents-that-ship.md)
<!-- /vf-manual:nav -->
