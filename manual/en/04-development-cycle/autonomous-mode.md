# Autonomous mode

<!-- vf-manual:lang -->
[Français](../../fr/04-cycle-de-dev/mode-autonome.md) · **English**
<!-- /vf-manual:lang -->

Autonomous mode runs the cycle's four movements, step after step, without you sitting in front of
the screen. You say "do it all", "figure it out", "I'll be back tomorrow morning, keep going", and
the lab runs.

It's VibeFlow's most impressive feature and the easiest to misuse. This page says when it makes
sense, what stops it, and what you find when you come back.

## When it makes sense, and when it's a bad idea

**It makes sense** when the scope is already framed and what's left is unrolling work: several
steps already described in the roadmap, a project whose direction you've validated, a series of
fixes each of which is clear. In other words: when the decisions are made and it remains to apply
them.

**It's a bad idea** in three very recognizable cases. When you don't yet know what you want —
autonomy will frame it for you, on assumptions, and you'll get work done well on the wrong thing.
When the subject touches something irreversible or sensitive — production data migration, billing,
mass deletion. And when you don't intend to read what gets produced: autonomy doesn't excuse you
from the read-through described in [shipping-and-reviewing.md](./shipping-and-reviewing.md), it postpones it.

A simple landmark: autonomous mode is built to **execute a lot**, not to **decide a lot**. If your
next session holds more decisions than implementation, stay in conversational mode.

Note too that this mode adapts to the size of the work. A short mission is handled directly; a long
mission, or one where you've signalled an extended absence, triggers the deployment of a genuine
agent team — that's the subject of the next theme.

## What stops it

This is the important question, because it's what makes autonomy usable at all. The loop doesn't
push through at any cost: it has blunt stopping triggers.

- **A decision to make.** Any grey area framing didn't settle comes back to you rather than being
  arbitrated in silence.
- **A destructive or irreversible action.** Mass deletion, history rewrite, a real send. That needs
  your explicit confirmation, no exceptions.
- **A blocker that persists.** After three attempts with no measurable progress on the same point,
  the loop drops that point and reports it. It doesn't try forever, and it doesn't work around.
- **A plan divergence that won't converge.** If a plan is revised several times without landing,
  that's a signal something is badly posed — and it comes back to you.
- **Scope drift.** Files touched outside the approved contract stop the loop, which shows you the
  gap.
- **A missing external resource.** A service down, a quota exhausted, a file not found. The loop
  stops instead of inventing a workaround.

And one guarantee worth stating bluntly: the loop **doesn't cheat**. It weakens no test to make a
step pass, it doesn't break a test that was green, and it doesn't quietly rewrite a success
criterion downward. Without those three prohibitions, an autonomous mode would mostly produce
lying green.

Autonomy **never cancels** the human validation commitment. It changes *when* you're asked, not
*whether*. The stopping points and their logic are described in
[gates-and-human-validation.md](../02-concepts/gates-and-human-validation.md) — they apply in
full under autonomous mode.

## What you find, and how to take back control

**When you come back**, you have a synthesis report: what was done, step by step, what was
committed, what failed, and above all **what's waiting on a decision from you**. Start with that
last point: it's what's blocking the rest.

The reading order that works best: pending questions first, then the commit history (the most
reliable summary of what actually happened), and only then the per-step detail. The report will
also tell you whether the loop stopped on its own, and on which trigger — that's more useful
information than the number of steps handled.

Then apply the read-through from [shipping-and-reviewing.md](./shipping-and-reviewing.md). It doesn't change
because the work was done autonomously. It matters more, in fact, because you didn't watch the work
happen: the diff is your only window.

**Taking back control mid-run** is always possible. You can interrupt at any moment; committed work
stays committed, and the state on disk describes where the loop had got to. If you want to stop
cleanly and resume later without losing the context, ask for that explicitly rather than cutting
the session — the lab will write a resume point, and the next session picks up from there instead
of rediscovering the subject.

One last piece of advice, and it's the one that counts: **try autonomy on a single step before
handing it ten**. You'll see what its report looks like, what it decides alone, and what it calls
you for. A delegated night of work is far easier to judge when it isn't the first one.

And one precaution that costs nothing: before starting a long autonomous session, make sure your
repository is in a clean state and your work in progress is committed. Not because autonomy is
dangerous — it works on its own branch — but because a clean starting point makes the next
morning's diff infinitely easier to read.

Autonomous mode is a multiplier, not a substitute. It multiplies what you framed well, and it
multiplies just as faithfully what you framed in a hurry. That asymmetry is the whole reason the
framing page comes before this one — and the reason it's worth re-reading before a long night of
delegated
work.

<!-- vf-manual:nav -->
[← Previous](../04-development-cycle/shipping-and-reviewing.md) · [↑ Contents](../README.md) · [Next →](../05-agent-team/why-a-team.md)
<!-- /vf-manual:nav -->
