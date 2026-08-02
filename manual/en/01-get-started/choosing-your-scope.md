# Choosing your scope

<!-- vf-manual:lang -->
[Français](../../fr/01-demarrer/choisir-son-scope.md) · **English**
<!-- /vf-manual:lang -->

In step 2 of `/vibeflow-install` (see [installation.md](./installation.md)), you're asked to
confirm a **scope** — where VibeFlow will write its files. `INSTALL.md` names the three options
in one line each; this page gives you what you need to arbitrate between them knowingly.

## The three scopes, what they write and where

**Account (`user`).** VibeFlow installs into your personal Claude Code folder
(`~/.claude/...`), outside of any git repository. What you set up here is available in **every
one of your projects**, on this machine, without committing anything anywhere.

**Project (`project`).** VibeFlow installs into the current repository's `.claude/` folder, and
these files get **committed** along with the rest of the code. Anyone who clones the repository
gets the same VibeFlow configuration you have.

**Project without commit (`local`).** Same location as `project` (the current repository's
`.claude/`), but the files stay **outside of git** — the engine handles the exclusion itself, you
don't have to configure anything. It's a project scope that leaves no trace in the history.

Exactly one scope applies to **everything** you install in a single pass — VibeFlow's modules, and
the external dependencies they bring along with them. You can't mix, say, one module at account
scope and another at project scope during the same install.

### The pre-selected choice

You don't land on a cold choice between three equivalent options: `/vibeflow-install`
**detects** your context before asking you to confirm. If the current folder is a git repository,
**project** scope is pre-selected — that's the most common case, and the detection assumes that
if you're inside a repository, you're probably there to work on it with VibeFlow. If you're not
inside any git repository, **account** scope is pre-selected instead. And if you've already used
a scope before on this machine, that prior choice **takes priority** over the detection rule —
VibeFlow stays consistent with what you've already done rather than starting from scratch every
time. You always keep the final say: the pre-selection is a help, never a constraint.

## What each scope gains you, and what it costs you

**Account**: the gain is that you configure once and it follows you everywhere on this machine —
useful if you juggle several personal projects and want the same environment everywhere. The
cost: none of it is automatically shared with a team, and a project you clone elsewhere (another
machine, another collaborator) doesn't inherit your config — everyone has to install on their own.

**Project**: the gain is that the whole team working on this repository inherits the same
VibeFlow configuration the moment they clone it — nothing to reinstall by hand. The cost: VibeFlow's
files enter the project's git history, visible to anyone browsing the repository (including on a
public platform if the repo is public).

**Project without commit**: the gain is that you get VibeFlow on this specific repository without
ever leaving a trace of it in the history — useful on a repo where you don't want anyone to see
you're using this tool, or on a repo whose history needs to stay minimal. The cost: nothing is
shared with the team — every collaborator has to install on their own — and if you switch
machines, you start from scratch on this repo.

### The same scope for every dependency

The scope you choose doesn't just apply to VibeFlow's modules: it also applies to the external
dependencies they bring along with them (the planning engine and the agent team VibeFlow
orchestrates behind the scenes). That's intentional — having half your install at one scope and
the other half at another would create inconsistencies that are hard to diagnose. One scope,
chosen once, applies to everything this install sets up.

## Changing scope later

You're never locked into a first choice. Rerun `/vibeflow-install` any time: the sequence plays
out again, and you can pick a different scope. This new pass **installs** at the new scope but
doesn't automatically remove what was set up at the previous one — if you want to end up cleanly
on a single scope, remove the old one first before confirming a new one (the full lifecycle —
updating, changing, uninstalling — is covered by a dedicated page later in this theme).

**Decision rule, if you're still unsure**: a single workstation and several personal projects →
**account** scope. A repository a whole team shares and needs to find identical after a clone →
**project** scope. A repository whose git history you don't want to pollute → **project without
commit** scope.

Choosing which **modules** to install (once the scope is confirmed) is a separate decision,
covered by the dedicated modules theme later in this manual — this page only covers location, not
content.

### A rule of thumb if you're still unsure

If you're independent and juggle several client repositories from the same machine, without
necessarily needing to share your VibeFlow configuration with anyone, **account** scope saves you
from redoing the same install for every new project. Conversely, if you're joining an existing
repository where other people will also use VibeFlow, **project** scope guarantees everyone sees
exactly the same thing after a `git clone` — no "works on my machine, not on yours" caused by
diverging configurations. **Project without commit** scope remains the right default if you're
trying VibeFlow out on an existing repository and don't want to leave anything behind until
you've decided to adopt it for good.

None of these three options is objectively "better" than the others — they answer different
situations, and the right one for you depends entirely on how you work, not on some universal
best practice.

<!-- vf-manual:nav -->
[← Previous](../01-get-started/installation.md) · [↑ Contents](../README.md) · [Next →](../01-get-started/your-first-session.md)
<!-- /vf-manual:nav -->
