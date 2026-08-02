# The machine gates

<!-- vf-manual:lang -->
[Français](../../fr/07-sous-le-capot/les-gates-machine.md) · **English**
<!-- /vf-manual:lang -->

[gates-and-human-validation.md](../02-concepts/gates-and-human-validation.md) explained **why**
VibeFlow prefers a script that refuses over a paragraph that recommends. This page doesn't repeat
that why — it answers a more concrete question: **which gates actually run**, on what, at what
moment, and what happens when one of them fires.

## The inventory

Every module that ships a gate does so the moment you install it — never before. A minimal lab, with
only the governance baseline installed, inherits a handful of these gates; a fully-equipped lab, with
most modules, accumulates all of them. Here are the families of gates that actually ship, with what
each verifies, when it runs, and the effect of a failure.

| Gate | What it checks | When | If it fails |
|---|---|---|---|
| Agent conformity | An agent written under `agents/` carries a valid frontmatter (name, description, model, memory scope) and only declares skills that actually exist | On writing an agent (blocking) + a reminder at session startup (warning) | The write is refused, with the exact missing or invalid field named |
| The 300-line Iron Law | An edited or created code file doesn't exceed the block threshold without a tracked escape hatch | On every edit or creation of a code file | The write is refused; an explicit marker in the file's first five lines lets you record acknowledged debt instead of bypassing the gate |
| Planning guard | The tracking of a work compartment was updated before the session ends | At the end of a session | The session doesn't end until the tracking is up to date |
| Branch claim | The current branch isn't already being driven by a mission from another work tree | At session startup | A warning is shown; nothing is blocked, whether to continue stays your call |
| Memory registry read/write | An access to a memory registry follows the expected indexing protocol | Before any read or write of a registry | The access is refused if the protocol isn't followed |
| Doctrine freshness | A framing or rule document has drifted from its source without a matching update | At session startup, periodically | A warning is shown, nothing is changed on your behalf |
| Infrastructure audit | The real state of your hooks, scripts, and tooling hasn't silently drifted after an update | At session startup, if the last check is more than two weeks old | A warning is shown with the detected drift |
| Documentation research before debugging | An intensive debug session on a library, framework, or native behavior is preceded by documentation research | At session startup, as a reminder | A warning is shown; nothing prevents continuing without having searched |

Two mechanisms round out this table without being rows of their own. The **driver lock** stops two
mission managers from driving the same step at the same time: whoever arrives second waits for the
first to release the lock, or recovers an abandoned lock after a default inactivity window of thirty
minutes. And **the judge never writes**: an agent evaluating a deliverable (a review, an audit, a
quality gate) is given read-only access to the code it's judging — a guardrail enforced at the tool
level, not a rule it could break under pressure.

### The fail-open principle

A detail worth knowing: a blocking gate that hits an internal error (a missing interpreter, an
unreadable input) **never fails on the blocking side** — it lets the action through, silently,
rather than freezing your session over a problem unrelated to what it checks. Only an **explicit
refusal**, with a message that says precisely what's wrong, actually blocks an action. A broken
guardrail never turns into a wall: at worst, it goes temporarily silent until the cause is fixed.
That's a deliberate choice, not a flaw — a gate isn't meant to add a new way for you to get stuck.

## Size limits, made visible

Two size limits are concretely visible, worth naming because they're what explains a refusal you
might otherwise mistake for a whim:

- **The skill preload budget.** When an agent declares a skill to be preloaded in full at startup
  (rather than loaded on demand), the cumulative size of those skills is measured and capped —
  beyond that, writing the agent is refused. This is the density charter made concrete: an agent
  that loads too much content at startup costs more on every invocation, usually for no real gain.
- **The 300-line code threshold**, already covered in the table above, with its warning at 250 lines
  before the hard block.

**Not to overpromise:** the charter recommending agents themselves stay under 250 lines is **not**
today automatically checked by a gate installed by default in your lab — it's documented doctrine,
applied through human vigilance and review, not a blocking script. A template exists in the
methodology library for anyone who wants to set up that check themselves; it isn't installed by
default. Saying so plainly here avoids leading you to believe in a guarantee that doesn't yet exist
by default.

### A concrete example: the Iron Law refusal

Concretely, here's what you'd see if you tried to write a 320-line code file with nothing else
attached: the write is refused, with the exact line count and the exceeded threshold. Two honest
paths open up — splitting the file into several smaller modules (the recommended route), or
explicitly acknowledging the debt by adding the escape marker in the file's first lines, which lets
the gate pass as a warning instead of a block. The gate never guesses which of the two is right for
your case — it only forces the choice to be **explicit**, never silent.

## What isn't blocking

Not every script in this family blocks. A detector that spots overlap between a VibeFlow capability
and a third-party tool already present in your session (two ways of doing a code review, for
instance) **observes and displays**, it never refuses an action — VibeFlow never claims exclusivity
against a tool it doesn't control. This script isn't even fired by any automatic session behavior by
default: you invoke it by hand, or from a broader integrity check, never at startup. That's a
deliberate choice, not an oversight: between blocking a session over a tool it doesn't control and
simply informing, VibeFlow chooses to inform.

The same principle explains why some gates exist in two forms — one placed automatically at a point
in the cycle, the other callable by hand for a broader check. The file-size check, for instance,
fires on every edit in blocking mode, but also exists as a standalone command you can run over a
whole project before a commit — same threshold, same logic, two entry points for two different uses.

Keep this rule of thumb for reading any gate you come across: if it **writes a refusal with an error
code**, it's blocking — fix and retry. If it **prints a line at startup**, it's an observation — up
to you to act on it or not. The distinction is never ambiguous once you know to look for it.

If a gate ever seems to behave differently from what this page describes, this page is never the
source of truth: the script itself is, placed under your scripts folder after install, readable in
plain text. This page gives you the map, not the implementation detail — the full doctrine, with the
reasoning behind each gate, lives in the methodology library covered on the next page of this theme.
A table, however careful, remains a map — not the territory.

That's also why this page never claims to be exhaustive down to the last flag: what matters for a
reader discovering VibeFlow is the shape of the system — which gates block, which only observe, and
why the line between the two is drawn where it is. If in doubt about a specific gate you're
running into, read the script — this page will still be here when you come back, and it won't have
drifted from what actually runs on your machine. That's the whole point of pointing you at the
source instead of a summary that could go stale — a summary you're reading right now, and one this
page tries hard not to be, by always naming where the real answer lives.

<!-- vf-manual:nav -->
[← Previous](../07-under-the-hood/the-install-engine.md) · [↑ Contents](../README.md) · [Next →](../07-under-the-hood/the-doctrine-and-its-patterns.md)
<!-- /vf-manual:nav -->
