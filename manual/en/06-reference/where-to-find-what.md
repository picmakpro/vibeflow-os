# Where to find what

<!-- vf-manual:lang -->
[Français](../../fr/06-reference/ou-trouver-quoi.md) · **English**
<!-- /vf-manual:lang -->

This manual doesn't claim to say everything. Some things live elsewhere in the repo, kept current
by construction because they're maintained in the same place as what they describe — copying their
content here would let it go stale, exactly the problem
[where a module lives](../03-modules/where-a-module-lives.md) details for version numbers. This page
is the deliberate bridge to those places: one line each, rather than a repeated explanation. It's
the last page of the reference theme, and that's intentional: it closes the manual by saying where
to keep looking once it isn't enough anymore.

## The resource map

| You're looking for | Look here | Not here |
|---|---|---|
| A module's installed version and its history | The module's `module.json`, then its `CHANGELOG.md` if it has one | No page of this manual — see [where a module lives](../03-modules/where-a-module-lives.md) |
| Why a structural decision was made | `docs/ADR.md`, the repo's architecture-decisions register | The README, which only cites a subset |
| The full methodology doctrine (principles, patterns, vocabulary) | `plugin/reference/content/`, the canonical source | `docs/reference/` in your own lab, which is a copy of it |
| What changed between two published VibeFlow versions | `CHANGELOG.md`, at the repo root | This manual, which never narrates that history |
| What a machine check actually verifies | Each module's `scripts/` (e.g. `plugin/conductor/scripts/`) | A plain-language paraphrase, always less precise than the script itself |
| A lab built end-to-end as an example | `plugin/reference/content/examples/PetitsCoursFlow/` | — |
| Licensing terms | `LICENSE` (root, license for the plugin itself) **and**, separately, `plugin/reference/content/LICENSE.md` (usage terms specific to the methodology doctrine) | A single shared text — these are two distinct licenses, for two distinct things |
| How the repo checks its own changes before publishing | `.github/workflows/ci.yml` | An informal description of what "the CI" does |
| This manual's own order and structure | `manual/toc.yml` — the canonical sequence of themes and pages | A hierarchy guessed from navigation alone |

Each row answers a specific question. If your question doesn't match one exactly, the move that
almost always works is the same: ask your lab directly rather than hunting for the file yourself —
a VibeFlow agent knows where to read these sources, and answers with the exact value rather than
an approximation. This table doesn't escape the rule it describes either: it points, it never
copies the content of the files it names.

**On `plugin/reference/content/` versus `docs/reference/`: which one wins?** If your lab has the
`reference` module installed, a copy of the doctrine lives in your own project, under
`docs/reference/`, placed there at install time. That copy can lag slightly behind its source if
the module has moved since — an accepted duplicate, not a bug, but **when in doubt, the source in
this repo (`plugin/reference/content/`) always wins**.

**On the two licenses.** `LICENSE` covers the plugin code you install and run.
`plugin/reference/content/LICENSE.md` covers a different object: the usage terms for the
methodology content itself (the principles, the patterns, the templates), once it's been copied
into your own project. Mixing the two up means getting wrong what you're allowed to do with what —
worth seeing once, explicitly, rather than guessed at.

### The principle behind this page

This page applies to itself the rule that governs this whole reference theme: never copy
information that lives — and changes — elsewhere. A version number goes stale the moment a module
next updates; a doctrine excerpt goes stale the moment its source moves without the copy
following. Pointing to the source costs one line and stays true indefinitely; copying its content
costs more lines and goes false silently, with nothing flagging it. That's exactly the choice
[where a module lives](../03-modules/where-a-module-lives.md) made for version numbers, applied here
to every other resource in the repo.

## Why you don't normally need to open `docs/` or `.planning/`

This is the question this manual exists to answer, so it's worth saying it explicitly, right where
you might be tempted to go look for yourself.

`docs/` and `.planning/` — whether at the root of this distribution repo or inside a lab you built
with VibeFlow — are written **for agents**, not for you. They're the working memory: a step's
progress, decisions made along the way, identified blockers, verification traces. An agent
re-reads them continuously to know where it stands and not ask you a question already answered.
The format there is optimized for that mechanical re-reading — dense, indexed, full of internal
cross-references — not for comfortable human reading.

You only need them if you want to literally inspect the machinery: understand why a mission made a
particular call, or check a raw state rather than the reformulated version an agent would give
you. That's never forbidden — nothing there is hidden — but it's never necessary either to use
VibeFlow day to day. If you catch yourself opening `.planning/` to understand *what VibeFlow does*
rather than *what one specific mission did*, that's the signal the question belongs to this
manual, not to those folders — and that this page might deserve a report (next section) if it
doesn't answer it yet.

This manual, by contrast, is written **for you**: what you read here has been rephrased,
structured, and explicitly dated to be read by a human who's discovering something or coming back
to check something specific — not to be re-read in a loop by a machine. If a page in this manual
sends you toward `docs/` or `.planning/`, it's always for a one-off, named need (an architecture
decision, one specific mission report) — never as a default reading you're expected to do.

Concretely, the boundary draws itself like this: a question starting with "how do I" or "what is"
belongs to this manual. A question starting with "what exactly did Tuesday's mission do" or "why
did this agent write that file" belongs to `.planning/` — and even then, most of the time it's
faster to just ask your lab in plain language than to go read the raw file yourself.

## Reporting a problem or suggesting an improvement

This repo is public on GitHub, at `picmakpro/vibeflow-os`. A behavior anomaly, a manual page that's
aged badly, or an improvement idea — the normal path is a GitHub issue on this repo.

Describe what you observe rather than what you assume the cause is: that's what gets it fixed
fastest, for the same reason a precise symptom beats a guessed cause on the
[troubleshooting](./troubleshooting.md) page. If your report is specifically about this manual — a
missing page, a dead link, a fact that changed without the page reflecting it — say so explicitly
in the issue: the manual evolves in writing waves distinct from the code's, and a clear report on
its scope helps route it to the right one.

There's no preformatted issue template on this repo as of when this page was written — a
free-text issue, clearly describing the context, is enough. That's neither a gap nor an oversight:
it's simply the repo's state today, and this page doesn't pretend one exists just to spare you
looking for one that doesn't.

That closes this reference theme, and with it, this manual's guided coverage of VibeFlow as it
stands today.

<!-- vf-manual:nav -->
[← Previous](../06-reference/troubleshooting.md) · [↑ Contents](../README.md) · [Next →](../07-under-the-hood/anatomy-of-an-installed-lab.md)
<!-- /vf-manual:nav -->
