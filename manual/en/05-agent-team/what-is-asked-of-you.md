# What's asked of you

<!-- vf-manual:lang -->
[Français](../../fr/05-equipe-agents/ce-qu-on-vous-demande.md) · **English**
<!-- /vf-manual:lang -->

The two previous pages said who makes up the team and how it holds together. This one takes the
opposite angle: the life cycle of a long mission **seen from outside**, as a protocol you can
follow rather than a description of the system. It complements
[autonomous-mode.md](../04-development-cycle/autonomous-mode.md), which covers the generic stopping
triggers of any autonomous loop — here, what's specific to a mission driven by a multi-agent team,
not a single session looping.

Read it before running your first team mission, not after. It comes down to six points: when
you're asked, what stops everything, how to pause, how to resume from nothing, where the produced
work lands, and what you should read before saying yes.

## What calls on you, and what stops the mission

While a team works, you're asked at precise moments, never at random. The most frequent one: a
worker's typed report comes back with the `human_needed` status — a grey area nobody on the team
has the mandate to settle alone. It escalates to you immediately, as a structured question, not a
remark buried in a long write-up.

What **stops** the mission outright, with no attempt to work around it, are the halt conditions
described in detail in
[gates-and-human-validation.md](../02-concepts/gates-and-human-validation.md) — an
irreversible destructive action, a blocker that persists after several attempts with no progress,
a plan divergence that won't converge, a gap between the files touched and the agreed scope, a
missing external resource. On a team mission, add one case specific to group work: a
**coordination conflict** — two DAG nodes touching the same resource in a way the graph hadn't
anticipated, or a branch already driven by another actor, detected at startup (see
[branches-and-worktrees.md](./branches-and-worktrees.md)). In every case, the stop comes with a
structured message: what was in progress, what triggered the stop, the exact state (steps done,
commits made), and concrete options to choose between. Never silence, never a bare "it broke" with
no context.

One guarantee worth repeating here because it applies in full to a team mission: **no deletion of
content, no risky correction, no irreversible action is ever granted under autonomy.** A manager
that needs to mass-delete, force a history rewrite, or send something outward stops and asks you,
with no exception and regardless of how much work is left.

What that looks like in your inbox, concretely: never a vague "it's stuck, what now?" Always a
one-sentence context, the factual observation that triggered the stop, the exact state of the work
at that moment, and named options to decide between — often in under a minute, because the context
doesn't need rebuilding.

## Pausing, and resuming from a blank session

You can interrupt a team mission at any moment. What's already committed stays committed — nothing
comes undone on interruption. What tells apart a **clean cut** from a **proper pause** is that the
latter is asked for explicitly: say so, and the manager writes a resume point to disk before
stopping — the DAG's state (which nodes are done, which are in progress), the decisions already
made during the mission, and what was left to do. A clean cut leaves the state on disk as-is; a
requested pause makes it readable for whoever picks it up.

**Resuming from a blank session** works because the disk, not the conversation, is the source of
truth for every VibeFlow mission. A fresh session that restarts the same manager needs no context
repeated to it: it reads the project's state itself (`.planning/ROADMAP.md`, `.planning/STATE.md`)
and the mission's graph, rebuilds its position, and resumes dispatching right where it stopped —
including reclaiming a stale driver lock if the cut was long enough for that (see
[a-long-mission.md](./a-long-mission.md)). You have nothing to reconstruct yourself; that's
exactly what the previous session's report and the state on disk make possible.

One nuance worth knowing: a clean cut (closing the tab, killing the process) doesn't necessarily
release the driver lock cleanly — that's the limit already stated in
[a-long-mission.md](./a-long-mission.md). That's fine: the stale-lock recovery mechanism
exists precisely for this case, and a following session that relaunches the same mission reclaims
it automatically, with the reclaim recorded. You have nothing to clean up by hand.

## Where artifacts land, and what to read before accepting

Three places, always the same ones. The mission's tracking (plans, detailed reports, decisions)
lives under `.planning/` in the target repository. The work itself lives on **its own branch**,
never on your main branch (ADR-059) — what that means for you in detail is in
[branches-and-worktrees.md](./branches-and-worktrees.md). And the mission ends with a **PR left
open**, never merged on its own: the merge is yours.

If the project isn't a git repository, or has no remote configured, or the PR tool isn't
available, the mission doesn't stop for that — it falls back and **tells you so** in its report
rather than failing silently or pretending the branch and the PR exist. That's an explicit
guarantee: a team mission never fails because of git mechanics, only because of the content of the
work itself.

What you read before accepting picks up, without repeating it in full, the list from
[shipping-and-reviewing.md](../04-development-cycle/shipping-and-reviewing.md) — the diff, what got deleted, the tests, the plan's
success criteria. A team mission adds one piece of its own: the **mission report** handed back at
the end, which summarizes the overall verdict, the per-step detail (done / verdicts / commits),
the decisions made under autonomy and by which mechanism, and the points explicitly waiting on
your call. Always start with that last point — it's what blocks the rest, exactly as in plain
autonomous mode.

One last thing to check, specific to the longest missions: if the plan carried a cost estimate,
the report carries the real outcome next to it, copied as-is rather than recalculated or rounded.
A large gap between the two isn't a fault — it's useful information for calibrating the next
mission of comparable size.

Hold on to the idea running through this whole page: a team mission doesn't remove any of the
checkpoints you'd have had working alone. It groups them and makes them traceable on disk, so you
can honor them even after having been away while it ran.

That shift — from continuous watching to targeted review at the right moment — is what makes a
long mission viable without chaining you to the screen. It's also the whole reason the previous
page bothered to name the mechanism's honest limits: knowing where it can silently drift is what
lets you review at the right moment instead of every moment.

<!-- vf-manual:nav -->
[← Previous](../05-agent-team/a-long-mission.md) · [↑ Contents](../README.md) · [Next →](../05-agent-team/branches-and-worktrees.md)
<!-- /vf-manual:nav -->
