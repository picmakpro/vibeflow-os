# Updating and uninstalling

<!-- vf-manual:lang -->
[Français](../../fr/01-demarrer/mettre-a-jour-et-desinstaller.md) · **English**
<!-- /vf-manual:lang -->

This page covers what happens **after** the initial installation: keeping VibeFlow up to date,
changing its configuration, and removing it cleanly if you need to.

## Updating

The simplest gesture, once VibeFlow is installed, is to say:

```
update VibeFlow
```

This triggers the `/vf-update` command, which proceeds in **two layers**. First, it compares the
**plugin** version you have installed against the latest published one, and shows you what
changed (new capabilities, fixes, doctrine changes) before asking for confirmation — nothing
updates without your explicit agreement. Then, once the plugin itself is updated, it
re-materializes the **modules** you have installed (skills, agents, rules) based on the new
version. To know the exact version you currently have, or the one that was just installed, check
each module's `module.json` or the repo's `CHANGELOG.md` — this page never hardcodes a version
number, it changes too often to stay accurate here.

**The bare-name trap.** If you'd rather use the command line directly instead of asking in
natural language, always use the full identifier:

```bash
claude plugin update vibeflow@vibeflow-os
```

The bare name (`claude plugin update vibeflow`, without `@vibeflow-os`) can return a "Plugin not
found" error when the local catalog cache is stale. If that happens even with the full
identifier, the fix is `claude plugin marketplace update vibeflow-os`.

**The planning engine updates separately.** VibeFlow relies behind the scenes on an external
planning and tracking engine. If that engine has an update available, `/vf-update` flags it **in
a separate message**, with its own confirmation request — accepting or declining that line has no
effect on updating the plugin or VibeFlow's own modules. It's a migration that is never proposed
without you explicitly accepting it.

At the end, restart Claude Code: the plugin itself (commands, agents) only takes effect at the
next session start.

**This rule covers any change to an agent, not just an update.** The agent registry is resolved
**at startup**: if you edit an agent file yourself — to test a fix, adjust a tool, remove a line —
the running session keeps using the definition it loaded when it started. The trap is that there
is no signal: the agent still answers, it simply behaves as it did before your edit, and nothing
tells you your change did not take. And since an agent can exist in several copies on the machine
(the installed definition, the plugin cache, the catalog), editing a single copy is not enough
either. **After any change to an agent: restart the session, then verify on a real action** — that
is the only way to know your version is the one running.

## Reconfiguring, adding, or removing a module

`/vibeflow-install` isn't reserved for the first install (see
[installation.md](./installation.md)): rerun it any time to change
[scope](./choosing-your-scope.md), add a module you didn't pick initially, or remove one. Each
rerun recalculates the necessary dependencies and shows you a summary before acting.

## Uninstalling

The installation lives in **two distinct layers**, and removing the first doesn't automatically
remove the second:

- **Deployed modules** — the copies VibeFlow set up in your scope (skills, agents, rules,
  scripts).
- **The plugin itself** — the bundle Claude Code keeps in its local cache.

**Always remove the modules first, then the plugin.** The order matters: as long as the plugin is
still present, the engine knows where to find the files to remove cleanly (with an automatic
backup before each removal). If you remove the plugin first, that reference point disappears, and
you'd have to clean up the leftover files by hand.

**Step 1 — remove the modules.** Simply say "uninstall VibeFlow" (or "remove such-and-such
module" for a targeted removal) while the plugin is still installed.

**Step 2 — remove the plugin.**

```bash
claude plugin uninstall vibeflow
```

**External dependencies are never removed automatically.** The planning engine and the agent team
VibeFlow orchestrates behind the scenes are **never** uninstalled at the same time as VibeFlow —
they're external dependencies, removed following their own procedure if you truly want to. That's
a deliberate choice: VibeFlow only touches what it set up itself.

### What you keep if you reinstall later

Removing VibeFlow doesn't delete the work you produced with it — your labs, their memories, the
content you generated stay right where you created them, independent of the install itself.
Reinstalling VibeFlow later gives you back the agents and commands, but doesn't recreate anything
you had already built: none of it depended on the install to exist.

It's the same principle as removing a text editor from your machine: the program leaves, the
files you wrote with it stay exactly where you left them.

Nothing here forces you to choose between keeping VibeFlow indefinitely or losing your work: the
two are entirely independent.

So you can safely uninstall to test something, then reinstall later if you need it again — your
labs will be exactly as you left them.

<!-- vf-manual:nav -->
[← Previous](../01-get-started/your-first-lab.md) · [↑ Contents](../README.md) · [Next →](../01-get-started/installation-troubleshooting.md)
<!-- /vf-manual:nav -->
