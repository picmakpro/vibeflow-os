# Several topics in parallel

<!-- vf-manual:lang -->
[Français](../../fr/05-equipe-agents/sujets-en-parallele.md) · **English**
<!-- /vf-manual:lang -->

[branches-and-worktrees.md](./branches-and-worktrees.md) settles the case of two actors writing to
the same repository. This page settles the neighboring case, on the **planning** side: two lines of
work moving at the same time, each with its own roadmap and state, neither waiting for the other to
finish. VibeFlow calls each line of work a **topic** (the planning engine says *workstream*). You
don't need any as long as you work alone on a single line of work — that's the default, and it
suits most labs.

## One planning, or several topics

By default, a lab has **a single planning**: one `.planning/` with a roadmap, a state, phases. When
"several of us will be on this lab", or two lines of work have to move in parallel, you can split
that planning into topics: each keeps its own phases and its own state, under
`.planning/workstreams/<topic>/`. The `/vf-split-planning` command does that; you can also trigger
it in plain language ("split the planning into topics"). It is also offered at the end of a code
lab's initialization.

It asks **a single question** — "will several people or agents work in parallel on separate
topics?" — and the default answer is no. Until you say yes, nothing is created. In a
non-interactive session, it never answers for you: single planning.

Then, three things to know:

- **It refuses if a phase is in progress.** A machine check, not your memory, decides: a state
  marked `executing`, a phase with more plans than write-ups, or a phase folder holding a plan with
  no write-up is enough. Finish the phase, then run it again. If the check itself can't be done, it
  changes nothing and says so.
- **The first topic is the default topic.** On a lab already under way, the current planning is
  filed under a topic — named after the command's argument, otherwise the project title, otherwise
  the lab folder — and it tells you before doing it, with the option to pick another name or back
  out. That topic is picked up from one session to the next without asking you. A topic added
  later never changes the default.
- **It commits nothing.** Only the planning engine writes; the command then offers to commit the
  planning files that changed, and leaves the decision to you.

To start the first milestone of a following topic, the command gives you the line to type:
`/gsd-new-milestone --ws <topic>`. That action is interactive, and it's yours.

## Working on a topic

Once the planning is split, just say "resume topic X" or "work on topic X". The dispatched team then
receives the topic in its mandate: every call to the planning engine carries `--ws X`, and the
`GSD_WORKSTREAM` environment variable is exported in the mission's worktree. If X doesn't exist,
VibeFlow tells you and offers `/vf-split-planning`.

You can set the topic yourself when you run a planning action by hand: `--ws my-topic` on the
command (for example `/gsd-new-milestone --ws my-topic`), or, for a whole terminal session:

```bash
export GSD_WORKSTREAM=my-topic
```

**What you see at startup.** On a partitioned repository, if no topic resolves — neither
`GSD_WORKSTREAM` nor the shared pointer `.planning/active-workstream` — the session you just opened
flags the absence and prescribes `export GSD_WORKSTREAM=<name>`. The reason: the engine otherwise
keeps a session pointer in a temporary folder, erased at restart and distinct per worktree, so it
is never inherited from one session to the next, and a name that no longer matches a folder is
dropped without a word. The signal is **informative**: it observes, it blocks nothing. On a
single-planning lab, it says nothing.

## What watches over the partition

Two topics each moving on its own branch can diverge with no visible conflict: a `git merge`
silently merges two phases that took the same number. A check script, `check-divergence.sh`, acts
as a safety net. It changes nothing and looks for three defects:

- two phase folders of the same topic carrying the same number;
- a topic with more phase folders (or completed phases) than its own roadmap documents;
- a phase number owned by a topic that reappears in the root roadmap.

No hook runs it in your lab: you call it by hand, from the `conductor` module's scripts, when you
merge branches that touch the planning.

```bash
bash .claude/scripts/check-divergence.sh --path .
```

It answers `0` (consistent), `1` (divergence found, naming the number or numbers involved), `2`
(cannot be verified — never a courtesy green) or `3` (the repository isn't partitioned, nothing to
check).

The lab's other checks follow the active topic: the planning-state check no longer cries "STATE.md
missing" on a partitioned repository, and requirements are read per topic.

<!-- vf-manual:nav -->
[← Previous](../05-agent-team/branches-and-worktrees.md) · [↑ Contents](../README.md) · [Next →](../05-agent-team/tidying-up-after-yourself.md)
<!-- /vf-manual:nav -->
