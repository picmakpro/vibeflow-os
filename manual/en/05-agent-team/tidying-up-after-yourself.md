# Tidying up after yourself

<!-- vf-manual:lang -->
[Français](../../fr/05-equipe-agents/ranger-ce-qu-on-cree.md) · **English**
<!-- /vf-manual:lang -->

A mission produces traces: one more status entry in `STATE.md`, a report, a worktree, a branch, an
agent memory. Nothing removes them, and a lab that's never tidied ends up unreadable — a state file
close to 200 KB that no agent reads in full, fifteen worktrees of which half are already merged.
This page says what VibeFlow measures, when it tidies, and what it never does.

## The method budgets

One script, `check-method-budget.sh`, compares your lab to thresholds. By default it **only
observes**: it moves and deletes nothing, and it returns code `0` even when a budget is exceeded
(`--strict` returns `1` if you want to turn it into a check). Each threshold is set through an
environment variable.

| What is measured | Threshold | Variable |
|---|---|---|
| One `STATE.md` (and each topic's `STATE.md`) | 8 KB | `VF_STATE_BUDGET_KB` |
| Active worktrees per repository (main tree not counted) | 3 | `VF_WORKTREE_BUDGET` |
| Open topics in `BACKLOG.md` | 20 | `VF_BACKLOG_OPEN_BUDGET` |
| Lines of the `MEMORY.md` index | 200 | `VF_MEMORY_INDEX_BUDGET_LINES` |
| `ROADMAP.md` | 64 KB | `VF_ROADMAP_BUDGET_KB` |
| One `STATE.md` note paragraph / one `BACKLOG.md` entry | 12 / 40 lines | `VF_STATE_NOTE_MAX_LINES` / `VF_BACKLOG_ENTRY_MAX_LINES` |

It also spots what is **tidyable**: a local branch already merged, a worktree whose branch is merged
(a fresh branch never counts), a worktree whose folder has vanished (*orphan*), a stash nobody
owns, an agent memory outside git or outside its index. Remote branches are never tidied by the
machine: that's a human action.

## Tidying at the end of a mission and at the end of a gesture

**When a mission closes,** before releasing the driver lock, the manager runs the script in `--auto`
mode. The script archives what overflows, never committing or deleting anything; the manager then
commits that archiving, replaces the current position in `STATE.md` instead of stacking one more
entry, removes without `--force` the merged worktrees and branches that **the mission** created, and
prunes the orphans. What it couldn't tidy goes into the
`## Budgets` section of its report. An exit check compares the final state to a snapshot taken at
the start of the mission: what existed before is never blamed on it nor tidied by it, and a gap
blocks the exit until the head settles it.

**At the end of every turn, outside a mission,** a stop hook plays the same role for an ordinary
session, and it is **opt-in**:

- it acts **only in an armed repository** — one whose root contains `.planning/.fin-de-geste-armed`.
  No installation creates that file: you arm it yourself (`touch .planning/.fin-de-geste-armed` at
  the repository root). Elsewhere, it does nothing, says nothing, writes nothing;
- at session start, it takes a snapshot of the existing clutter; at each stop, it archives what an
  exceeded budget points to, then **blocks the stop** as long as tidyable items **appeared since
  that snapshot** remain — a merged worktree or branch, a stash, an unindexed memory. It tells you
  what to tidy, with the exact commands;
- what doesn't depend on the session (archiving refused, budget exceeded, check impossible) is
  told to you and never blocks;
- **circuit breaker**: after 3 blocks in a row without progress, it lets you out with a visible
  message, then goes quiet. A failed state write releases it too, saying so;
- `VF_FIN_DE_GESTE=block` (default), `warn` (it says so, moves nothing, blocks nothing) or `off`.

One limit worth knowing: two sessions open at the same time on the same repository can't be told
apart. The message therefore reminds you not to delete an object that isn't yours, and the circuit
breaker caps the cost of a mistake.

## Archiving is not deleting

Automatic archiving is a **traced, reversible move**, not a correction: it doesn't contradict the
rule "never repair without your approval" (see
[architecture-decisions.md](../07-under-the-hood/architecture-decisions.md)). It targets three
things: closed topics in `BACKLOG.md`, the history of a `STATE.md` beyond its budget (never its
open-state sections), and the shipped milestones of a `ROADMAP.md` beyond its own.

- The moved block lands as-is under `.planning/archives/<type>/`, a `<!-- vf-archive: … -->` line
  stays in its place, and a line is added to `.planning/archives/INDEX.tsv` (date, type, source,
  archive, original version, reason).
- **The tool never commits**: the move shows in `git status`, and you review it like any other
  change. When a mission closes, the manager commits it; the end-of-turn hook leaves the archiving
  uncommitted. A
  modified but uncommitted file is refused, nothing is written. On a partitioned repository, only
  the session's topic is archived; with no topic resolved, nothing is attempted.
- **Undo**: the "original version" column of `INDEX.tsv` is a git reference, and
  `git cat-file blob <reference>` returns the file as it was before archiving.

One last detail, on the creation side: installation puts a `.worktreeinclude` file at the root of a
lab installed for a project. It only makes an agent worktree receive those of `.claude/hooks/` and
`.claude/scripts/` that git ignores; if git tracks them, they reach the worktree through git, and the
file does nothing.

<!-- vf-manual:nav -->
[← Previous](../05-agent-team/parallel-topics.md) · [↑ Contents](../README.md) · [Next →](../05-agent-team/specialized-teams.md)
<!-- /vf-manual:nav -->
