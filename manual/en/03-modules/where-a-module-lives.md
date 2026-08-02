# Where a module lives, and where to read the truth

<!-- vf-manual:lang -->
[Français](../../fr/03-modules/ou-vit-un-module.md) · **English**
<!-- /vf-manual:lang -->

This page is the one that replaces, in this manual, the version summary table you might have
expected to find. It teaches you to go get information at its source rather than trust a copy — and
it explains why that difference matters more than it looks.

## The four files that tell the truth

A module is a folder. Inside that folder, four files carry the reference information, and each
answers a different question.

**`module.json` — the identity.** This is the module's manifest, the one the installer reads. It
carries the module's name, its type, its one-sentence description, its **version** number, its
**dependencies** (`requires`), and whether it's mandatory (`mandatory`). This is where — and
nowhere else — you read a module's installed version. The file is about ten lines long and reads at
a glance.

**`CHANGELOG.md` — the history.** What each version changed, most recent first. This is the file to
open when a module behaves differently than it used to, or when you want to know whether a
capability you're looking for already exists. A changelog entry tells you *what moved*; the
`module.json` only tells you *where you are*.

**`README.md` — the usage.** What the module does, how you use it, and what its limits are. It's
the most reliable source for understanding a module in depth, because it's written and maintained
in the same place as the module's own code.

**`VERSION` — the bare number.** A single-line file, redundant with the manifest field, which
exists so scripts can read it without parsing JSON.

A caveat: **not every module carries all four files.** Most do, but a few depart from it — some
have no `README.md`, others organize their content differently. Don't assume; open the module's
folder and it'll tell you what it actually carries.

## The anatomy of the rest

Around those files, a module keeps its capabilities in folders with predictable names. You never
need to touch them, but knowing where to look helps you understand what a module actually laid down
on your machine.

- **`skills/`** — the module's skills, one subfolder per skill, each with its `SKILL.md`. Modules
  carrying only one sometimes put it straight at the root instead.
- **`agents/`** — the team's internal agents, one file per agent. A module may also lay down a main
  agent at its root, distinct from those.
- **`scripts/`** — the executable scripts: machine gates, checks, generators. This is what makes a
  control return a binary verdict instead of an opinion.
- **`references/`** — the detailed documentation agents load on demand, so their prompt doesn't
  carry it permanently.
- **`hooks/`, `rules/`, `config/`** — the wiring: what fires automatically, rules that apply to
  certain paths, configuration values specific to a project.

The distinction between skill, agent, and command is explained in
[agents-skills-and-commands.md](../02-concepts/agents-skills-and-commands.md) if those three words still
blur together.

### Reading a version in three seconds

The simplest gesture is still to ask your lab: "which version of the development module is
installed?". It will go read the manifest and answer with the exact value, not an approximate one.

If you'd rather look yourself, the file reads directly. From the plugin repository root:

```bash
cat plugin/dev-orchestrator/module.json
```

The `version` field is right there, between the name and the description. Swap `dev-orchestrator`
for whichever module interests you — the names are the ones in the [catalog](./catalog.md), and
they match the folder names exactly.

## Why this manual quotes no version

You may have noticed that no page in this manual contains a version number. That's not an
oversight: it's a rule, and an automatic check enforces it every time the manual is reviewed.
Here's why.

A number copied into a documentation page becomes wrong the moment the module is next updated — and
it becomes wrong **silently**. Nothing breaks, nothing warns, nobody notices. The page keeps looking
correct, and a reader who trusts it makes a decision on stale information.

This isn't a theoretical worry. At the time these lines were written, the repository's own README
was showing stale versions for the **large majority** of modules: one module advertised several
minor versions behind its real state, another further still. The README had done nothing wrong — it
had simply been written one day, and the modules had kept moving without it.

Hence the rule: this manual never freezes information that can go stale. It points at the place
where that information lives. For a version, that place is the module's `module.json`; for the
history of its changes, its `CHANGELOG.md`. It's marginally less convenient to read, and it's
infinitely more reliable.

The same reflex is worth carrying beyond this manual. Whenever a document tells you a number, ask
yourself when it was written and whether anything forces it to stay true. If nothing does, go read
the source.

<!-- vf-manual:nav -->
[← Previous](../03-modules/enabling-and-disabling.md) · [↑ Contents](../README.md) · [Next →](../04-development-cycle/the-cycle-at-a-glance.md)
<!-- /vf-manual:nav -->
