# Anatomy of an installed lab

<!-- vf-manual:lang -->
[Français](../../fr/07-sous-le-capot/anatomie-d-un-lab-installe.md) · **English**
<!-- /vf-manual:lang -->

So far, this manual has shown you what you can **do** with VibeFlow. This page answers a different,
more concrete question: when you run `/vibeflow-install` and confirm, what actually **lands** on
your disk? The only trace of this question elsewhere in the repository is an uninstall table, which
poses it backwards — a list of what to remove, not of what was placed and why. This page poses it
the right way round, read directly from the install script itself.

## What the install writes, file by file

Everything starts from a **scope** (see [choosing-your-scope](../01-get-started/choosing-your-scope.md)),
which fixes a single target root: `$HOME/.claude` for the account scope, `./.claude` for the project
or uncommitted-project scope. Everything below is relative to that root, except a doc-only module's
content, which goes elsewhere — covered further down.

- **An install registry.** A plain text file at the target root (`scripts/.vibeflow-installed`)
  listing, one line per module, the module's name and its installed version. This is the memory of
  what you've installed — it's what `/vf-update` and the install status read to know what to update.
- **Skills.** Each skill becomes its own folder under `skills/`, with its `SKILL.md`. A module that
  ships several skills (an orchestration module, for instance) places several — never a flat file
  directly at the root of `skills/`.
- **Agents.** A module shipping a single "face" agent places one file under `agents/<name>.md`; a
  module shipping a full team of agents places one file per agent, all under `agents/`. Nothing is
  merged: one file on disk always maps to one agent.
- **References for an agent or a skill.** When a module bundles a `references/` folder alongside its
  skill or agent, it's copied as-is under `skills/<mod>/references/` or `agents/<mod>-references/`
  depending on the module type. This is documentation loaded on demand by the agent, never preloaded
  in full.
- **Sample configuration.** A module shipping a `config/` folder (project configuration templates,
  for you to copy and adapt) places it under `skills/<mod>/config/`. Nothing activates on its own:
  it's a starting point, not an applied configuration.
- **Auto-scoped rules.** A module's `rules/*.md` files are copied under `rules/` at the target root.
  Some load only when you touch a file matching their pattern, others load unconditionally — that
  distinction lives in each rule's own header, not on this page.
- **Scripts and their data.** Every shell or Node script a module ships (never your project's own
  source code) is copied under `scripts/`, made executable, along with any accompanying data files
  and its test folder. It's the same shared folder for every installed module — no name collision is
  expected between two different modules.
- **A doc-only module's content.** The one exception to the target root: a purely documentary module
  (the methodology library, for instance) copies its content under `docs/<module-name>/`, **relative
  to your project's folder**, never under `$HOME/.claude` even in the account scope. This doc isn't
  runtime material, it has no place among the files Claude Code loads every session.
- **An embodiment command.** After placing a "face" agent, the install generates a command file under
  `commands/<name>.md`, letting you invoke that agent directly from the main window
  (`/<agent-name>`). This step is best-effort: if it fails, the agent stays usable in plain language,
  only the explicit command is missing.

### A concrete example

Take a module shipping a full team agent — a manager, several specialists, a quality judge —
together with its own coordination scripts and rules. Once placed, you'll find under your target
root: one file per agent under `agents/`, a shared references folder under
`agents/<mod>-references/`, the coordination scripts under `scripts/`, the auto-scoped rules under
`rules/`, and one more line in the `.vibeflow-installed` registry. None of it mixes with your
project's own code: everything lives under the chosen scope's target root, except the doc-only case
described above. It's this predictability — the same layout for every module, whatever it brings —
that makes a clean uninstall possible.

Nothing about this layout is guessed at runtime. Each artifact type maps to a fixed, documented
target under the scope's root — the same mapping the install script itself follows every time, for
every module, whether it ships one file or twenty.

## MCP injection into executing agents

One point that, before this manual, nothing documented for a user: if your project declares MCP
servers in its own `.mcp.json` (an iOS build server, a database connection, a drivable browser), the
install **injects** access to those servers into the agents that actually do the work — the ones
that compile, test, or fix code. Agents that only plan or review are left untouched: they don't need
it, and the guiding principle is to grant each agent the least privilege it needs.

Concretely, only the servers **your project itself declares** are affected — never a server
configured only at your user account's level, and never a server name guessed or hardcoded into a
generic agent. If you add a new MCP server to your project after the initial install, restarting
Claude Code is required for the executing agents to pick it up — this allowlist is only read at
session startup.

## What isn't written

Just as useful as the inventory above: what the install **never touches**.

- **No project source file.** The install places skills, agents, scripts, and rules — never a line
  in the code you write yourself.
- **No git history.** The one exception, documented nowhere else but here: in the uncommitted-project
  scope, the install adds lines to your `.gitignore` so the paths it placed stay local. It touches
  nothing else on the git side — no commit, no branch, no remote.
- **No silent network call.** Nothing is sent outward during install — no telemetry, no usage report.
- **No automatic launch.** The install never runs on its own at session startup: you invoke it
  (`/vibeflow-install`), it acts, it stops. This point is developed in
  [installation](../01-get-started/installation.md); it isn't repeated here.
- **No hidden startup behavior.** A "hook" — a script that fires automatically at a given moment, for
  instance when Claude Code opens — only appears if the module **you explicitly chose to install**
  declares one. No module imposes one you wouldn't have seen coming: the exact content of what fires,
  and the promise that goes with it, are covered on the next page of this theme.

For how to cleanly remove everything this page just described, the procedure lives in
[updating-and-uninstalling](../01-get-started/updating-and-uninstalling.md) — it isn't duplicated
here.

Reading this page shouldn't leave you guessing what's true today versus what changed last release:
everything above was read directly from the install script's current source, not from a description
that could drift out of sync with it — the same discipline the next page applies to the mechanism
itself.

<!-- vf-manual:nav -->
[← Previous](../06-reference/where-to-find-what.md) · [↑ Contents](../README.md) · [Next →](../07-under-the-hood/the-install-engine.md)
<!-- /vf-manual:nav -->
