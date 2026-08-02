# The doctrine and its patterns

<!-- vf-manual:lang -->
[Français](../../fr/07-sous-le-capot/la-doctrine-et-ses-patterns.md) · **English**
<!-- /vf-manual:lang -->

Everything this manual has shown you so far — the principles, the gates, the mechanics of a
mission — comes from a methodology library far larger than a usage manual needs to cover. This page
is its map: what it contains, how it's organized, and which of its texts are genuinely worth your
time. It doesn't summarize any of its content — the doctrine runs to nearly ten thousand lines, and
a page that tried to condense it would drift from it at the very next update. It **cites and
routes**, it doesn't duplicate.

**The single canonical source** is the reference module's content folder, in the repository at
`plugin/reference/content/`: that's where the up-to-date version of everything below lives, and it's
the only one to cite if you want to verify something or dig deeper. Other copies of this doctrine may
exist elsewhere in some repositories — they're never the reference.

## How the library is organized

This three-layer organization isn't arbitrary: it mirrors the order the doctrine itself recommends
for discovering it — the founding texts first, to set the principles; the patterns next, to see how
they take concrete form; the vocabulary and templates last, once the meaning of the words no longer
needs guessing. Nothing forces you to follow that order to the letter — this page itself departs
from it, pointing you first to the two patterns most useful to a user rather than the full canon.

Three layers, from most foundational to most operational:

- **The founding texts.** The canon — the text that's authoritative on the principles, the
  five-component architecture, and the five memory registries — plus a cross-cutting text on
  enforcement ("a guardrail the machine doesn't run doesn't exist," already crossed on the previous
  page of this theme) that explains why VibeFlow builds gates rather than recommendations.
- **The twelve architectural patterns.** Each answers four fixed questions — what, why, how, a
  fictional example — and covers one precise aspect of the architecture: a lab's constitution, its
  memory registries, its agents, its skills, its auto-scoped rules, capitalization, transposing to a
  new domain, continuous evaluation, meta-procedures for autonomous execution, adversarial plan
  review, immediate-halt conditions, and tool-level compartmentalization. None of these patterns is a
  recipe to follow to the letter — they're proven ways of doing things, meant to be adapted to your
  context.
- **Vocabulary, templates, and one full example.** A methodology lexicon (to be distinguished from
  this manual's own product glossary, which defines different words — see
  [glossary](../02-concepts/glossary.md)), dozens of generic templates for building a new agent, a
  new skill, or a new registry, and a single end-to-end fictional example (a freelance music
  teacher's lab) that shows all twelve patterns in context — useful as a model if you want to see
  what a lab applying the doctrine in full looks like: a complete non-dev lab, memory included,
  rather than a plain list of rules.

## Which patterns are worth a user's time

Not every pattern speaks to the same audience. Some are aimed first at whoever designs a new
capability for VibeFlow; two of them, in particular, directly explain a behavior **you** observe
while using the product, and deserve your attention before the others:

- **The halt-conditions pattern.** It explains why an agent running autonomously stops dead rather
  than forcing a decision on your behalf — the five universal immediate-halt triggers you'll run into
  during a long mission are defined here.
- **The tool-compartmentalization pattern.** It explains why an agent evaluating a deliverable never
  has the technical ability to fix it itself — that's not a promise written in a text, it's a
  restriction enforced at the level of the tools that agent is given.

Concretely, if a long mission ever stops with a message you didn't expect, it's almost always one of
the five triggers from the first pattern that just fired — reading it once saves you from
reinterpreting every stop as a special case.

The patterns on agents and on capitalization are also worth the detour if you want to understand why
VibeFlow's agents have a single mandate rather than being swiss-army knives, and why nothing decided
or learned in a lab is ever lost from one session to the next. The other patterns — domain
transposition, adversarial review, execution meta-procedures — speak more to whoever builds or
extends VibeFlow than to whoever uses it day to day; they remain accessible, just lower priority for
a first read.

A reading map accompanies the library itself, with suggested paths by goal: discovering the doctrine,
setting up a new instance, building a fork for a different domain, operating with rigorous autonomy,
designing safe agents, auditing an existing project. That map is finer-grained than the selection
above — it speaks equally to the designer and the curious user, and is worth the detour if one of
those goals speaks to you more than "understanding what I'm observing."

## A doctrine to read, never to copy

If you want to keep a local copy of this library in your own project instead of browsing the VibeFlow
repository, the general mechanism that places a module's documentation on your disk is the same one
described on the previous page of this theme — installing the documentation module gives you a
complete, up-to-date copy, at the location the install places the documentation of any module that
only brings that.

Keep the right posture toward this doctrine: it documents proven ways of doing things, not absolute
rules. If a pattern collides with a concrete reality of your work, that's not a mistake on your
part — it's a signal worth documenting as a deliberate departure, not one to ignore silently.

### Why this page doesn't copy anything

A ten-thousand-line doctrine evolves. A summary freezes a precise instant of that evolution and
drifts from it at the very next update — exactly the trap this manual's own material inventory
caught, finding two copies of this library slightly out of sync with each other at the time this
theme was written. This page deliberately chooses the option that can't drift: say what exists, say
who it's for, say where to read it — never restate the substance, which belongs to its one canonical
source. That's the same discipline you've already seen applied to this manual itself: cite and route
rather than duplicate. A doctrine and its usage manual age better when they share the same rule.

If this summary and the canonical source ever disagree, the canonical source is always right. That's
not a hedge — it's the whole design of this page, applied consistently down to its last line, so
you never have to wonder which one to trust — and neither will this page, six months from now, once
the doctrine has moved on and this map hasn't tried to move with it. Read the map, then read the
territory — in that order, and only when you actually need the territory.

That's the whole page, and everything it promised: a map, nothing more.

<!-- vf-manual:nav -->
[← Previous](../07-under-the-hood/the-machine-gates.md) · [↑ Contents](../README.md) · [Next →](../07-under-the-hood/architecture-decisions.md)
<!-- /vf-manual:nav -->
