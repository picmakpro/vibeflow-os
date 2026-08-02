# Installation

<!-- vf-manual:lang -->
[Français](../../fr/01-demarrer/installation.md) · **English**
<!-- /vf-manual:lang -->

This page is the manual's **single source of truth** for the installation procedure: it gathers
in one place everything you need to know to set up VibeFlow, from the first character you type to
the screen that confirms it worked.

## The two commands

Open a terminal (or Claude Code's command window) and type, in order:

```bash
claude plugin marketplace add picmakpro/vibeflow-os
claude plugin install vibeflow
```

- The **first command** adds the VibeFlow marketplace to Claude Code. The GitHub repository
  `picmakpro/vibeflow-os` hosts its own plugin catalog (`marketplace.json`) — this command simply
  tells Claude Code "look there too."
- The **second command** installs the `vibeflow` plugin itself: Claude Code copies the plugin's
  contents (the modules, the `installer/` skill, and the internal engine) into its local cache.

You have **no** `settings.json` editing to do, and **no** script to run yourself beyond these two
commands.

If either command fails, before any other diagnosis check prerequisite #1 (see
[prerequisites.md](./prerequisites.md)): Claude Code needs to be recent enough to know the
`claude plugin` command.

## Launching configuration

Once the plugin is installed, type in Claude Code:

```
/vibeflow-install
```

### The launch is always manual — and that's intentional

There is **no** automatic opening of this configuration when a Claude Code session starts. You
have to type `/vibeflow-install` yourself, whether for a first install or to come back and change
something later.

This isn't an oversight: an attempt to auto-launch via a `SessionStart` hook (a mechanism that
runs automatically when a session opens) existed in an earlier version of VibeFlow, then was
removed because its triggering wasn't reliable. If you open a session and nothing happens
automatically, that's **normal** — it's the expected behavior, not a malfunction. Just type
`/vibeflow-install`.

### Reconfiguring later

`/vibeflow-install` isn't a one-shot command: you can rerun it any time, as many times as you
want. Each rerun shows the same sequence — scope, modules, summary — and recalculates the
dependencies to install. This is the normal way to change scope, add a module you didn't pick at
first, or remove one.

### The four steps of configuration

When you run `/vibeflow-install`, here's what unfolds:

**1. Prerequisite check (preflight).** Before anything else, an automatic check verifies your
system has everything it needs (see [prerequisites.md](./prerequisites.md)). If something is missing,
you'll see the exact command to fix it, and setup stops there until you've done so.

**2. Scope choice.** You're offered a pre-selected choice among three possible install locations
for VibeFlow — your account, this project, or this project without committing to git. A
reasonable default is already suggested based on the detected context (for example, if the
current folder is a git repository). A dedicated page later in this theme details each option and
how to choose — this page only confirms your choice.

**3. Module choice.** The minimal governance baseline (the `conductor` module) is installed
automatically — this isn't a choice, it's the foundation without which nothing else can work
correctly. After that, you're offered one structuring choice: a development lab (code), or a new
lab for a different field. The full list of available modules is derived from the catalog present
on your disk, never hardcoded here — always check each module's `module.json` or the repo's
`CHANGELOG.md` for the exact state of the catalog at the moment you're reading this manual.

**4. Summary, then installation.** Before installing anything, you're shown a summary of
everything that's about to be installed (the module you chose sometimes pulls in other modules it
depends on) — you see exactly what's going to happen before it happens. Once confirmed, the
chosen modules are installed at the location (the scope) you settled on in step 2.

### What you see on screen when it works

At the end of setup, you get a final summary telling you what was installed and where, and it
points you to the next thing to do based on the choice you made in step 3 — for example, if you
chose a development lab, you're invited to simply say "help me dev" to get started.

You don't need to memorize anything: each step ends with a clear pointer to what comes next.

**Next step.** A dedicated page later in this theme details the trade-off between the three
scopes if you're still unsure before running `/vibeflow-install`. Otherwise, once setup is
complete, the rest of this theme is waiting to tell you what to do in the fifteen minutes that
follow.

<!-- vf-manual:nav -->
[← Previous](../01-get-started/prerequisites.md) · [↑ Contents](../README.md) · [Next →](../01-get-started/choosing-your-scope.md)
<!-- /vf-manual:nav -->
