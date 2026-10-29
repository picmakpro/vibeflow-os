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

At the `product` and `dev` roles, the installer makes it run for you after every merge (see below).
At the `solo` role, nothing runs it: you call it by hand, from the `conductor` module's scripts, when
you merge branches that touch the planning.

```bash
bash .claude/scripts/check-divergence.sh --path .
```

That path applies to a project or local scope install; in user scope, the script is under
`~/.claude/scripts/check-divergence.sh`.

It answers `0` (consistent), `1` (divergence found, naming the number or numbers involved), `2`
(cannot be verified — never a courtesy green) or `3` (the repository isn't partitioned, nothing to
check).

The lab's other checks follow the active topic: the planning-state check no longer cries "STATE.md
missing" on a partitioned repository, and requirements are read per topic.

### The safety net armed at the product and dev roles

When a `product` or `dev` role is installed, the installer puts two git hooks in **your clone**,
`post-merge` and `post-rewrite`. They replay the check after every `git pull`, `git merge` or
`git pull --rebase`. At the `solo` role, nothing is installed.

- **It cries on a divergence**, but the merge is not undone: a hook cannot undo it. When everything is
  consistent, it says nothing more. When it cannot judge, it says "cannot be verified": never a
  courtesy green.
- **The journal**: every cry and every "cannot be verified" appends a line (date, hook, verdict, HEAD,
  signals) to the file `.git/vf-divergence/journal.tsv`. It is not versioned, it belongs to your clone
  (your worktrees share it) and it survives removal of the safety net.
- **The state**: `bash .claude/scripts/vf-divergence-hook.sh status --path .` says whether each hook
  is armed, third-party or absent, and how many lines the journal holds. A hook you armed by hand
  carries the path of the plugin cache script: ask `status` through that same script (the installed
  plugin's `conductor/scripts/vf-divergence-hook.sh`). Asked through the lab copy in `.claude/scripts/`,
  that hook reads as third-party, because the path in its line is not the copy's.
- **It never runs your repository**: the check is launched from the installed plugin, not from a
  script the merge may have just brought in.
- **It never takes the place of a hook of yours**: if a hook already exists, or if `core.hooksPath` is
  set (husky, for instance), nothing is overwritten, and the installer prints the line for you to add
  to that hook yourself.
- **The way out**: `VF_DIVERGENCE_HOOK=off` at install, when changing role, or when updating. See
  [installation](../01-get-started/installation.md) and
  [updating](../01-get-started/updating-and-uninstalling.md).

### What the safety net does not see

These limits are measured, not assumed. The safety net does not fire on:

- `git reset --hard`, `git switch` and `git checkout`;
- `git cherry-pick`;
- a `git rebase` that rewrites no commit.

A merge done on the forge is only seen at your next `git pull`. After a plugin update, run
`/vf-update` so the hook follows the installed plugin: without it, it may say "cannot be verified".
On Windows (Git Bash), the safety net has not been measured yet.

<!-- vf-manual:nav -->
[← Previous](../05-agent-team/branches-and-worktrees.md) · [↑ Contents](../README.md) · [Next →](../05-agent-team/tidying-up-after-yourself.md)
<!-- /vf-manual:nav -->
