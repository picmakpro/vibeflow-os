# Glossary

<!-- vf-manual:lang -->
[Français](../../fr/02-concepts/glossaire.md) · **English**
<!-- /vf-manual:lang -->

This glossary covers VibeFlow's **product** vocabulary — lab, scope, module, team. It's distinct
from the **methodology lexicon**
(`plugin/reference/content/methodology/vocabulary/lexique.md`), which covers the vocabulary of the
doctrine itself (registers, constitution, principles). If you're looking for a methodology term
rather than a product one and can't find it here, that's where to look.

Each term is defined in plain language. A link points to the page that develops it, when that
page already exists in the manual; otherwise, the definition stands on its own.

The order isn't alphabetical — it follows the natural progression of understanding: first the
folder (lab, scope), then what gets installed into it (module, bundle, baseline), then how a team
works within it (team-kernel, driver lock, DAG, mission digest), then what guarantees that work
stays under your control (halt condition, fresh judge, machine gate, typed report), and finally
two infrastructure notions that come up often without ever being named elsewhere (worktree,
anti-thrash, ready frontier).

**Lab** — A folder on your disk where VibeFlow has laid down a constitution, one or more agents,
and a memory. Covered in [what-is-a-lab.md](./what-is-a-lab.md).

**Scope** — Where VibeFlow writes what it installs: account, project, or project-without-commits.
Detail in [choosing-your-scope.md](../01-get-started/choosing-your-scope.md).

**Module** — An installable unit that adds one precise capability to a lab. Covered in
[modules-and-bundles.md](./modules-and-bundles.md).

**Bundle** — A special kind of module that lays down a complete agent team for a given line of
work, instead of a single capability. Covered in
[modules-and-bundles.md](./modules-and-bundles.md).

**Baseline (socle)** — The set of mandatory modules of a lab (`conductor` and its transitive
dependency closure). Covered in [modules-and-bundles.md](./modules-and-bundles.md).

**Team-kernel** — The reusable team-orchestration core usable in any line of work (driver lock,
DAG, typed reports, halt conditions, mission digest, tool cloistering). Hosted by the `conductor`
module, it's what every business bundle instantiates instead of reinventing its own team
coordination.

**Driver lock** — The mechanism that guarantees only one mission drives a step at a time. It
carries a TTL and a heartbeat: if the driver disappears without releasing it, the lock gets
recovered cleanly instead of staying stuck forever.

**DAG** — A long mission's battle plan, represented as a graph of tasks with their dependencies
instead of a linear list. The manager only dispatches tasks whose dependencies are all
complete — the "ready frontier" — often several in parallel.

**Mission digest** — A summary of at most 30 lines injected into every mandate handed to a worker,
so it doesn't have to re-read the project's entire working memory. Disk stays the source of
truth; the digest only cushions the re-reading.

**Halt condition** — A trigger that stops an autonomous execution dead and escalates the decision
to you, with a structured message. Covered in
[gates-and-human-validation.md](./gates-and-human-validation.md).

**Fresh judge** — An evaluation agent dispatched without having watched the production happen,
which judges a deliverable as it stands on disk rather than on what it watched get built.
"Fresh" signals it carries no leniency bias toward work it would have followed itself.

**Machine gate** — An automated check that returns a binary verdict (exit code 0 or 1), never a
prose recommendation. Covered in
[gates-and-human-validation.md](./gates-and-human-validation.md).

**Typed report** — The format a worker returns to its manager: a closed status
(`passed`/`gaps_found`/`human_needed`/`blocked`) instead of free-form narrative. Covered in
[gates-and-human-validation.md](./gates-and-human-validation.md).

**Worktree** — An isolated git working copy, dedicated to one session or agent. Every concurrent
writer (a human session or an agent) works in its own worktree, which keeps two active parallel
sessions from stepping on each other over the same files.

**Anti-thrash** — The guardrail that makes an autonomous loop **give up** on a stuck point after a
fixed number of attempts (typically three) instead of grinding at it forever. Without it, an agent
could spin on the same failure without ever escalating the problem.

**Ready frontier** — In a mission DAG, the set of tasks whose dependencies are all complete and
that can therefore be dispatched **right now**, possibly in parallel if their scopes don't
overlap.

If a term used elsewhere in this manual isn't listed here and it's blocking you, that's a gap in
this glossary, not something you're expected to already know — the product's vocabulary has
nowhere else to be learned.

This glossary isn't frozen: it will grow as the manual's later themes get written and new product
terms show up. A link to a page that doesn't exist yet will never appear here before that page is
actually written — that's a strict manual rule, not an oversight.

Use `Ctrl+F` (or your browser's equivalent) rather than scanning the list top to bottom: the
sixteen terms are meant to be easy to find, not to memorize in order. Come back here whenever a
page in the manual throws a word at you that you don't recognize — that's exactly what this page
is built to absorb, so you never have to guess from context alone.

Sixteen terms is deliberately small for a product with this much surface area. That's a choice,
not an accident: a glossary that tries to cover everything stops being something anyone actually
reads.

<!-- vf-manual:nav -->
[← Previous](../02-concepts/gates-and-human-validation.md) · [↑ Contents](../README.md) · [Next →](../03-modules/catalog.md)
<!-- /vf-manual:nav -->
