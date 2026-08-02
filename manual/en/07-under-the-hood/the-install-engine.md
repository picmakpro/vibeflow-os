# The install engine

<!-- vf-manual:lang -->
[Français](../../fr/07-sous-le-capot/l-engine-d-install.md) · **English**
<!-- /vf-manual:lang -->

The previous page showed **what** the install writes to your disk. This one shows **how** it does
it — for anyone who wants to audit before running it, or simply understand why re-running an install
never breaks anything. Everything below reads straight from the install script itself: nothing is
hidden behind an interface.

## The principle: one scope, one root, one local cache

Every install command starts from an explicit **scope** (see
[choosing-your-scope](../01-get-started/choosing-your-scope.md)), which fixes a single target root for
the whole operation. No ambiguity possible: two runs with the same scope always write to the same
place.

The source for the modules themselves is a **local cache** prepared by `/vibeflow-install` from the
plugin Claude Code has already downloaded — there's no second download at install time, and no git
repository cloned behind the scenes. If that cache is missing, the install stops immediately with an
explicit error rather than improvising a substitute source.

### The mandatory baseline

A module can be flagged **mandatory** in its own manifest — that's the case for the governance
baseline that hosts the scripts shared across modules. If that baseline were ever missing from an
already-configured lab (for instance because it was published after your first install), a global
update catches it automatically, together with its full dependency closure. This is the only form of
automatic addition the engine allows itself: never a feature module you didn't choose, only the
baseline without which the other modules can't work correctly.

## What every operation guarantees

Three properties hold regardless of module or scope:

- **Idempotence.** Re-running an install or an update on a module that's already present never
  breaks it: either nothing changes because the version is identical (in which case only governance
  — scripts and hooks — gets re-synced, without a full re-copy), or the module is cleanly replaced
  by its new version.
- **Backup before modification.** Before overwriting an already-installed module, the engine first
  copies what exists into a timestamped backup folder, kept apart from anything actively in use. A
  dedicated restore command can bring back a module's latest backup in one step, if an update goes
  wrong.
- **Symmetric removal.** Uninstalling a module only removes the files **that module** owns — never a
  shared file placed by another module, even if they live in the same folder (`scripts/`, `agents/`,
  `rules/`). This symmetry between placing and removing is what makes the previous page's inventory
  trustworthy: what it describes is exactly what an uninstall removes, module by module.
- **Dependency closure, never silent.** Installing a module with its dependencies computes the full
  list of required modules before placing anything. If that computation can't complete correctly,
  the install never quietly continues on an incomplete list: it prints a visible, explicit warning
  rather than risking a half-equipped lab you wouldn't know about.

## What VibeFlow does not run

This is where — and nowhere else in this manual — this promise lives, stated once so it's never
half-repeated elsewhere.

**No automatic startup behavior exists before you've chosen to install it yourself.** A module may
declare a configuration fragment that fires at certain moments (session startup, editing a specific
file) — but that fragment is only merged into your Claude Code configuration **at the moment you
install that module**, never before, and never by a module you didn't choose. Before merging
anything, the engine backs up your existing configuration — the same safety net as everywhere else.
Removing the module removes the corresponding fragment, and only that one.

Concretely, that means three simple things you can verify yourself: (1) nothing fires at Claude Code
session startup as long as no module capable of doing so is installed; (2) the exact content of what
will fire is readable in plain text, before you even install the module that carries it; (3) if you
uninstall that module later, that behavior disappears with it — nothing stays attached to your
configuration.

### What you can read yourself to verify

The install engine is a single shell script, called by the install skill — not a compiled binary,
not a remote service. Everything this page and the previous one claim can be verified by reading it
directly: which folders it creates, when it backs up, when it merges an automatic behavior, when it
stops rather than improvising. If an optional mechanism (generating an embodiment command,
regenerating a reference index) is missing from your environment, the install carries on without it
rather than failing — those steps are announced as secondary precisely because they never gate the
install's overall success.

None of this needs a special tool: the engine is an ordinary shell script, callable directly from the
command line (status, install, update, uninstall, restore) if you'd rather take that path than plain
language. Reading it only requires knowing how to read shell — no VibeFlow-internal knowledge is
needed to verify what these two pages claim.

The simplest question to settle whether something about the install feels odd: "does this step leave
a readable trace in the script, with a reason written next to it?" If so, it isn't a hidden bug — it's
a deliberate decision, documented right where it runs. That readability is intentional: an install
mechanism you could only understand by watching it run wouldn't be auditable, only observable.

No version number appears on this page by design (D-11): check a module's `module.json`, or the
repo's `CHANGELOG.md`, to find out exactly what's currently available.

One last thing worth knowing about this engine's spirit: it observes, it never decides for you. A
status command exists to compare, module by module, what's installed against what's available — but
it never triggers an update by itself. That's the exact same restraint you'll find in the machine
gates described on the next page of this theme: detect and surface a fact, never act on it without
you asking.

Nothing here is described from memory of how it used to work: every claim above is checked directly
against the install script's current source before this page is finalized, so it stays true to what
actually runs on your machine, not to a past release's behavior. If it ever falls out of sync, the
fix is to re-read the script, not to guess. That's a better habit than trusting any single page,
including this one, forever.

<!-- vf-manual:nav -->
[← Previous](../07-under-the-hood/anatomy-of-an-installed-lab.md) · [↑ Contents](../README.md) · [Next →](../07-under-the-hood/the-machine-gates.md)
<!-- /vf-manual:nav -->
