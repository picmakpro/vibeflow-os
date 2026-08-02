# A long mission, the mechanics

<!-- vf-manual:lang -->
[Français](../../fr/05-equipe-agents/une-mission-longue.md) · **English**
<!-- /vf-manual:lang -->

The previous page said *why* a team gets deployed on a long mission. This one says *how* it holds
together across ten steps without anyone stepping on anyone else — trimmed to what produces an
observable consequence for you. The full internal detail lives in the ADRs cited below; here, only
what changes what you see.

The vocabulary on this page (driver lock, DAG, typed report, mission digest) is defined once and
for all in the [glossary](../02-concepts/glossary.md) — this page doesn't redefine it, it explains
how these pieces fit together.

Three mechanisms make up this machinery, and they chain in this order: the graph that says what to
do and in what order, the lock that says who's allowed to drive it, and the typed report that says
what actually happened once a node is handled. Each has an honest limit worth knowing, and all
three are stated below without softening them.

## The battle plan: a graph, not a list

When the manager receives your mission, it doesn't produce a list of steps to run in order. It
produces a **DAG**: each step becomes a node, and that node carries its dependencies — the other
nodes that must be done before it can start.

That changes two things for you. First, **parallelism**: the manager always dispatches the "ready
frontier" — every node whose dependencies are satisfied — not one at a time. If step 3 and step 4
don't overlap, they move forward together, and your mission finishes faster than a sequential run
without losing any rigor. Second, **re-entry**: if a review sends an already-marked-done step back
for correction, that's not a bolted-on exception — the node simply drops back to "ready", and its
dependents follow. The graph absorbs the step backward instead of treating it as an accident.

What you'll actually see of this in a mission report: several steps committed in the same minute
(parallelism), and sometimes a step that reappears after looking finished (re-entry). Both are
normal.

Review itself is a node in the graph, not a courtesy left to the discretion of whoever produced the
work. The manager places it systematically after every production step and dispatches it directly,
to a reviewer who didn't write the code — the same principle as "the judge is never the author"
from [why-a-team.md](./why-a-team.md), applied here inside the graph rather than
to the final deliverable. A join between two lots that advanced in parallel also triggers a
dedicated review, decided by the shape of the graph rather than an estimate of overlap — two steps
that technically touched no shared file can still assemble badly, and that's exactly what this join
review catches.

## The driver lock: what it guarantees, and what it doesn't

The **driver lock** exists for one precise reason: to stop two managers from driving the same step
at once without knowing it. The manager who starts a mission acquires the lock, refreshes it while
working (a heartbeat), and releases it at the end — success, failure, or abandonment alike. A lock
whose heartbeat stalls too long is considered stale and reclaimed automatically, with the recovery
recorded in the report.

It's worth being honest about what this mechanism does *not* do, because it's a real limit,
observed on this repository and not just a theoretical one: **the driver lock is declarative, not
enforced**. It coordinates the actors who consult it before acting — the team managers. It stops
nothing, technically, for an actor who ignores it. The case happened here: one mission kept
committing while another held the lock on the same resource, because nothing enforces the lock by
force — it documents an intention, it doesn't impose it.

Since then, the mechanism has been widened: a branch claim is now also recorded (working tree,
branch), and an ordinary session — not just a manager — is told about it at startup if it lands on
a branch already driven from another tree. That's what
[branches-and-worktrees.md](./branches-and-worktrees.md) covers in detail: the real barrier against
two simultaneous writers isn't this lock, it's working in separate trees.

A word on recovery, because it's what makes the lock usable despite its assumed fragility: nothing
guarantees that an agent that dies mid-run releases cleanly what it held — an LLM agent can stop
without executing its last instruction. The safety net is therefore lifespan plus heartbeat, not a
promise of clean release under every circumstance. A stale lock never blocks a following mission
forever; it gets reclaimed, and the reclaim is written down in plain sight in the report you read,
never quietly skipped.

## The typed report, and a second limit worth knowing

Before it even files a report, a worker starts with a **mission digest** — a summary capped at
thirty lines, not the project's whole history. It carries the step's objective, the file scope
assigned to it, the decisions already made that bind it, and the upstream verdicts relevant to its
specific mandate. That's what keeps it lean: a worker that starts on context tailored for it works
better than a session that first has to read three hours of history to figure out what's expected
of it. The disk stays the source of truth — if the digest and the disk disagree, the disk wins, and
the worker flags it rather than deciding on its own.

When a worker finishes its mandate, it doesn't hand back a paragraph of prose for the manager to
interpret. It hands back a **typed report**: a closed status, a list of findings sorted by
severity, and the list of nodes its work unblocks. The manager runs a deterministic flow-control
check on it — nothing to guess at. That contract is what makes the graph trustworthy: a
`human_needed` status always escalates to you, never an invented answer standing in for you.

That contract rests on a second mechanism that also deserves an unflattering presentation: **tool
fencing**. On a VibeFlow team, whoever fixes the code can't touch the tests, and whoever writes the
tests can't touch the application code — the separation is carried by the list of tools each agent
is allowed to invoke. That's real, and it stops the most tempting cheat there is (weakening a test
to make it pass). But say plainly what it isn't: a tool allowlist is **a linted contract, not a
runtime sandbox**. Nothing technically stops an agent from invoking a tool outside its declared
list — it's a compliance gate checked when the module is installed, not a barrier the execution
engine enforces live while the agent runs. The discipline holds because agents are written to
respect it and because the gate rejects a module that violates it, not because a technical wall
enforces it in real time.

What you find at the end of a mission, and where, is the subject of the next page — the one that
says what's asked of you, specifically, while all of this runs.

None of the three mechanisms above requires anything from you while a mission is running. They're
described here so a mission report reads as expected behavior instead of a surprise.

<!-- vf-manual:nav -->
[← Previous](../05-agent-team/the-agents-that-ship.md) · [↑ Contents](../README.md) · [Next →](../05-agent-team/what-is-asked-of-you.md)
<!-- /vf-manual:nav -->
