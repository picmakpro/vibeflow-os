# Branches and worktrees

<!-- vf-manual:lang -->
[Français](../../fr/05-equipe-agents/branches-et-worktrees.md) · **English**
<!-- /vf-manual:lang -->

This is the most operational page in this theme, because it hands you a concrete practice the
moment you work alongside a mission. The previous pages said *why* a team gets deployed and *how*
it moves forward; this one says what that changes for your day-to-day use of git.

## Why a mission never works on your current branch

A team mission produces dozens of commits with no direct supervision. Nothing guarantees they're
all good, and the only after-the-fact recourse, had it committed on your main branch, would be a
mass `revert` of history that's already public — potentially already pulled by other clones. This
is a real incident observed on this repository: a mission once produced 32 commits directly on
`main`, with no damage, but by luck rather than by design.

The rule that follows (ADR-059): **every team mission creates its branch before its first commit,
keeps all its commits there, and finishes with a pull request left open.** The manager never merges
it itself — the merge is yours, like any action that commits to your public history. On a branch,
the recourse is no longer a mass revert: it's simply not merging. The PR adds a grouped review
point on top, which an end-of-mission report, written by whoever did the work, doesn't replace.

The branch name follows a readable convention (`feat/<scope-in-kebab-case>`), and a mission has
exactly one branch, even when it spans several roadmap steps. If the target repository has no
remote, or the PR tool isn't available, the mission falls back cleanly and tells you so in its
report instead of failing — the fallback detail is covered in
[what-is-asked-of-you.md](./what-is-asked-of-you.md), not repeated here.

What triggers this rule is a **manager being dispatched**, not the nature of the work. A quick
fix, a doc update, or framing done directly in your conversation stay outside this rule — otherwise
every exchange would create a branch, adding weight to your daily flow without protecting anything
more. The rule targets specifically unsupervised work at volume.

## One writer, one worktree

The branch alone protects against one case: a mission accidentally committing on your main branch.
It doesn't protect against the other, more insidious case, also observed on this repository:
**two actors sharing the same branch from the same working tree without knowing it.** On
2026-07-31, a mission driven by a manager and an ordinary conversational session wrote to the same
branch in parallel — three out-of-scope commits ended up in the PR of a mission that hadn't
produced them. The driver lock already existed, but it only protected a step, and above all it was
only consulted by managers; an ordinary session walks right over it without ever knowing.

The rule that follows (ADR-064): **as soon as two actors work in parallel on the same
repository — two missions, a mission and a conversational session, two waves of the same
mission — each holds its own working tree.** It's the only barrier that doesn't rely on the good
will of whoever's writing: two distinct trees physically can't step on each other, whatever their
occupants intend. The branch stays necessary (ADR-059); it simply isn't sufficient on its own.

**What you see if you open a second session on the same repository.** If you start an ordinary
session on a branch already driven by an active lock set from another tree, a signal shows up at
startup — something like: *"this branch is already driven from another working tree (by such
owner, on such step, for N minutes) — one writer, one worktree"*. This signal is **advisory**: it
observes, it blocks nothing, and two sessions deliberately on the same branch remain a legitimate
and frequent case — the judgment call is yours (ADR-031), a hook that refused to let you write
would break perfectly normal uses. Two sessions in the *same* tree never trigger this signal: it's
writing from a third-party tree that's the surprise, not coexistence itself.

**Creating and removing a worktree**, in outline:

```bash
# from the main repository, create an isolated tree on a new branch
git worktree add ../my-repo-mission feat/my-mission

# once the work is done and merged, remove the tree cleanly
git worktree remove ../my-repo-mission
```

VibeFlow's principle here isn't to reimplement this mechanism: it's the harness's own
(`isolation: worktree` at mission dispatch), not a homemade rebuild. What VibeFlow adds is the
signal that warns you when someone else already holds one on your branch.

You can also check the situation yourself before committing to a branch you didn't create, rather
than waiting for the automatic signal: the same script that posts this signal at startup can be
called directly, and it answers with a clear verdict — nobody else is driving, someone else is
driving from another tree, or nothing could be verified. That last case — indeterminate — never
means "the coast is clear": it's an absence of certainty, not a green light.

## When a claim is refused

There's a difference between the advisory signal described above — which informs an ordinary
session — and an actual refusal, which applies between mission managers. When a manager tries to
start and the step it targets is already driven by an active lock, the acquisition **fails
outright**: the second mission doesn't quietly start alongside the first, it gets an explicit
refusal (who's driving, since when) and stops rather than pushing forward blind.

What you see in that case depends on how fresh the lock is. If it's active and recent, the refused
mission tells you and waits for your call — retry later, or confirm the first mission is indeed the
one that should keep going. If it's stale (the holder vanished without releasing it), the recovery
mechanism described in [a-long-mission.md](./a-long-mission.md) takes over on its own, and
the reclaim gets recorded in the report — you have nothing to unblock by hand in that specific
case.

Once a mission is done and its PR merged, the cleanup gesture is short: remove the worktree that
was dedicated to it (`git worktree remove`), and delete the merged branch if you don't plan to
reuse it. None of this is automatic — that's deliberate, so removing a working tree always stays a
gesture you make, never one the mission makes for itself.

Taken together, the three rules on this page cost you one habit to build: before starting parallel
work on a repository a mission might be using, take a moment to check whether it already has a
tree of its own. That single habit is what turns a physical isolation mechanism into a practice you
actually benefit from, instead of a safety net you only discover after tripping it.

<!-- vf-manual:nav -->
[← Previous](../05-agent-team/what-is-asked-of-you.md) · [↑ Contents](../README.md) · [Next →](../05-agent-team/specialized-teams.md)
<!-- /vf-manual:nav -->
