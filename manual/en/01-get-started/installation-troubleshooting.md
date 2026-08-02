# Troubleshooting — installation

<!-- vf-manual:lang -->
[Français](../../fr/01-demarrer/depannage-installation.md) · **English**
<!-- /vf-manual:lang -->

This page covers the four documented failures that can happen **during installation**. For the
"the launch is always manual" note, see [installation.md](./installation.md) — this page doesn't
repeat it, to avoid telling the same thing twice in two different places.

## The four known failures

### "`claude plugin` not found"

**Symptom.** You type `claude plugin marketplace add ...` or `claude plugin install vibeflow`,
and the terminal replies that the `plugin` command doesn't exist.

**Cause.** Your Claude Code version is too old — the `plugin` command only exists in recent
versions.

**Fix.** Update Claude Code, then retype the two installation commands (see
[installation.md](./installation.md)).

### The setup UX doesn't open at session start

**Symptom.** You open a new Claude Code session after installing the plugin, and nothing happens
automatically — no setup that starts on its own.

**Cause.** This is **not a failure**: it's the normal behavior. VibeFlow never opens on its own;
this launch is intentionally manual.

**Fix.** Type `/vibeflow-install` yourself. If the command isn't recognized by Claude Code, check
that the plugin is actually installed and that you restarted your session **after** running
`claude plugin install`:

```bash
claude plugin list
```

The `vibeflow` plugin should appear in that list.

### The marketplace isn't found

**Symptom.** `claude plugin install vibeflow` fails, saying it can't find the plugin, or that the
marketplace isn't registered.

**Cause.** The first command (`claude plugin marketplace add ...`) wasn't run, failed silently,
or the local catalog cache is stale.

**Fix.** Re-run the marketplace add, then check it actually appears in the list:

```bash
claude plugin marketplace add picmakpro/vibeflow-os
claude plugin marketplace list
```

The `picmakpro/vibeflow-os` repository should show up in the second command's output.

### Reinstalling everything from scratch

**Symptom.** None of the above fixed your problem, and you'd rather start from a clean slate than
keep diagnosing.

**Fix.** Remove and reinstall the plugin:

```bash
claude plugin uninstall vibeflow
claude plugin install vibeflow
```

This only touches the **plugin** (the bundle in Claude Code's cache) — not the modules already
deployed in your scope. If you want a truly clean slate, including modules already set up, the
full two-layer uninstall procedure is covered by
[updating-and-uninstalling.md](./updating-and-uninstalling.md).

## Before going further

These four cases cover everything documented so far as an installation failure. If your problem
doesn't match any of them, the most effective reflex is still to describe exactly what you see
(the full error message, the command you typed) rather than guess at a cause — most installation
blockers get resolved in seconds once the exact symptom is identified.

The four failures on this page cover every known cause as of today; if Claude Code itself
evolves, this list will be updated to match.

Either way, the install stays idempotent: replaying the same commands several times in a row
breaks nothing, even if you're not sure you already succeeded at a step. When in doubt, just
retype the command — nothing gets duplicated or corrupted by running it twice. That's true for
every command on this page.

## If the problem happens after installation

Everything above covers failures **during** installation itself. If your lab works but something
unexpected shows up later, once you're using VibeFlow day to day, a dedicated general
troubleshooting reference page — distinct from this one — will cover that case in a theme further
along in this manual.

<!-- vf-manual:nav -->
[← Previous](../01-get-started/updating-and-uninstalling.md) · [↑ Contents](../README.md) · [Next →](../02-concepts/what-is-a-lab.md)
<!-- /vf-manual:nav -->
