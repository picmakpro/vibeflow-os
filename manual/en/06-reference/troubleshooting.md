# Troubleshooting — beyond installation

<!-- vf-manual:lang -->
[Français](../../fr/06-reference/depannage.md) · **English**
<!-- /vf-manual:lang -->

[installation-troubleshooting.md](../01-get-started/installation-troubleshooting.md) covers what can break
**during** installation. This page covers the opposite: your lab is installed, it works, and it's
**afterward**, once you're using it day to day, that an unexpected behavior shows up. The two pages
never overlap — if your problem looks like an install issue, the other page is the one you want.

Each issue below follows the same pattern: the exact symptom as you see it, the most common cause,
the move to make, and how to check it's actually fixed. No move proposed here is destructive
without this page explicitly saying what it destroys.

## The six known issues

### The agent didn't trigger

**Symptom.** You phrase a sentence that should trigger a specific skill — "make this look better,"
"launch a cold email campaign" — and nothing specific happens: a generic reply comes back instead,
or nothing at all.

**Most common cause.** The matching module isn't installed in this lab — a skill can never trigger
if it isn't there. Second possible cause: your sentence is too vague to match the skill's
description, even with the module present.

**Move.** First check which modules are installed (the
[module catalog](../03-modules/catalog.md) and
[where a module lives](../03-modules/where-a-module-lives.md) explain how to read that). If the module
is there, rephrase by naming the action you want more explicitly — you don't need to know a
technical name, just to be more concrete about the intent.

**Check.** Retry the same sentence. If it still doesn't fire despite a confirmed installed module,
go through `/vibeflow` followed by your request: it always routes to `vibeflow-conductor`, which
can diagnose why the direct routing didn't work.

### A mission is stuck

**Symptom.** A long mission looks suspended — no update, no new report, apparent silence.

**Most common cause.** It's waiting for human validation (`human_needed` status) already raised
earlier in the conversation, or a halt fired and its escalation message got lost in a long reply.

**Move.** Scroll back through the mission's most recent messages: an escalation is **always
explicit** — never a silent stall with no message. Answer the question it asked. If you truly find
no trace of an escalation, just ask the manager "where's the mission at?" — it should be able to
answer immediately with its current state, without restarting anything.

**Check.** The manager picks back up as soon as you answer whatever was blocking it; if it doesn't,
the blocker was elsewhere — see "the driver lock is stuck" below.

### A halt froze a node (halt condition)

**Symptom.** Execution stops dead with a message explicitly naming a stop trigger: too many
iterations without converging between plan and review, a loop with no measurable progress, an
action judged non-reversible detected before it ran, a missing external resource, or a file edited
outside the planned scope.

**Cause.** This is **intentional, not a failure**: five universal triggers exist precisely to stop
an autonomous run dead rather than let it improvise silently.

**Move.** Read the escalation message in full — it names the trigger and why it fired. Answer the
exact question it asks. **Never reply with a generic "go ahead" without reading the reason first**:
if the trigger is about a non-reversible action, your confirmation will make it execute exactly
what the message spells out in black and white — read it before confirming.

**Check.** Execution only resumes after your explicit reply; nothing restarts on its own, ever.

### The driver lock is stuck

**Symptom.** A new mission refuses to start on a given step, with a message stating that a driver
lock is already held.

**Most common cause.** A previous session was interrupted abruptly (terminal closed, crash)
without releasing its lock. The lock carries a default lifetime of thirty minutes: until that
window expires, it's still treated as live — rightly so, a mission can legitimately take its time.

**Move.** Never force anything before checking the state. Ask your lab for the lock's status, or
if you're comfortable in a terminal, run `driver-lock.sh status` from the `conductor` module's
scripts. If it reports **stale**, a recovery (`driver-lock.sh recover`) removes it cleanly — this
move only destroys the lock entry itself, never a commit or file produced by the mission that held
it. If it's **not** stale, don't force it: another mission holds it legitimately, let it finish or
release it on its own.

**Check.** The status reports absent, or a new owner if another mission has since taken over.

### The branch claim is refused

**Symptom.** You commit to a branch and a signal tells you it's already "claimed" from a different
working tree.

**Cause.** Two actors — an active mission and you, or two separate sessions — are working on this
repo without each being in their own working tree (worktree). This is an **advisory** signal,
never a block: it never stops you from committing.

**Move.** If it's intentional (you know it's really you, in another window), just carry on, nothing
to fix. Otherwise, open your own `git worktree` rather than continuing to write into the same tree
as an active mission — that's exactly the situation the rule exists to prevent: two actors mixing
their commits without realizing it.

**Check.** The signal disappears once each actor is working from their own tree.

### A mission's PR stays open

**Symptom.** A team mission finishes, its report gives a pull request URL, but that PR is neither
merged nor closed — and nothing seems to happen next.

**Cause.** This isn't an oversight: a team mission **never** merges its own PR. The merge belongs
to you — it's the final human validation on a history of several commits produced without
continuous step-by-step supervision.

**Move.** Read through the PR (the diffs, and the mission report its title and body are derived
from), then merge it yourself once satisfied — or ask for changes before doing so. This move isn't
destructive: doing nothing, or closing the PR without merging, erases no commit already pushed to
the branch.

**Check.** The PR turns merged or closed only after your explicit action; nothing automates it for
you.

## If your problem doesn't match any of these six

Describe exactly what you see — the full message, the sentence you typed — rather than guessing at
a cause: that's what lets you find which of the mechanisms above is actually at play, fastest. If
the problem persists without matching a known case,
[where to find what](./where-to-find-what.md) says how to report it.

<!-- vf-manual:nav -->
[← Previous](../06-reference/cost-and-models.md) · [↑ Contents](../README.md) · [Next →](../06-reference/where-to-find-what.md)
<!-- /vf-manual:nav -->
