# Choosing your modules

<!-- vf-manual:lang -->
[Français](../../fr/03-modules/choisir-ses-modules.md) · **English**
<!-- /vf-manual:lang -->

The [catalog](./catalog.md) tells you what exists. This page tells you **what to take**, based on
what you actually do. It's a decision guide, not a list: you should come out of it with a
composition you can stand behind and the reason that goes with it.

One thing this page does not cover: **where** VibeFlow writes what it installs. That's the scope, a
question independent from picking modules, and it has its own page —
[choosing-your-scope.md](../01-get-started/choosing-your-scope.md). You can lay down the exact same
composition at three different scopes.

A useful reminder before you compose: the baseline arrives regardless. The seven modules described
in [baseline-and-dependencies.md](./baseline-and-dependencies.md) get laid down without you asking. Everything
below is added **on top**.

## Four profiles, four compositions

**You code alone, on your own projects.** Take `dev-orchestrator` and nothing else at first. It
pulls `design-orchestrator` along with it, which already gives you the full cycle — framing,
planning, execution, review — plus the ability to handle an interface phase without switching
tools. Add `software-architecture` as soon as your project outgrows a handful of files: that's the
module that stops you from letting a god class grow for six weeks. What you don't take: the
business bundles, which would lay down agent teams you'll never call.

**There are several of you on a shared repository.** Same base as above, with two differences in
posture. First the scope: install at project level so the configuration is versioned with the code
and identical for everyone — that's the only way to avoid each person running their own slightly
different VibeFlow. Second, don't neglect `consolidator`: with several people, the decision and
learning registries become the only place where the history of *why* survives someone leaving. It
arrives with the baseline, but it's only useful if you actually call it.

**You run a non-dev lab — content, sales, acquisition.** Take no dev orchestrator at all. Take the
bundle matching your line of work, exactly one: `content-bundle`, `business-pilot-bundle`, or
`growth-bundle`. Each lays down a complete team and a quality judge — the detail is in
[business-bundles.md](./business-bundles.md). Add `kpi-analyst` only once you already have material to
measure: laid down too early, it has nothing to read and produces an empty table.

**You just want to see what it looks like.** Take nothing beyond the baseline. It's enough to
create a lab, have it checked, understand the `.planning/` structure and the update gesture. You'll
add an orchestrator once you know what you want to ask it — adding one later is an ordinary
operation, covered in [enabling-and-disabling.md](./enabling-and-disabling.md).

**A special case, if you do mobile.** `mobile-test` and `mobile-test-team` exist and work, but
their own `module.json` files declare them **experimental**: they're waiting for their first
genuinely green run to drop that label. Concretely, that means you can try them, but don't build
your delivery process around them before you've seen them run on your own project. An experimental
module isn't a broken module — it's a module whose promise hasn't been verified under real
conditions often enough yet.

### How to tell something is missing

You don't have to anticipate. The signal is almost always the same: you ask your lab for
something, and it answers correctly but **by hand**, improvising, instead of running a tooled
gesture. A lab that offers to "look through the files one by one" where a module would have
produced a structured report is a lab missing that module.

The second signal is repetition. If you find yourself restating the same quality constraint on
every deliverable — "source your figures", "don't publish without showing me" — then a judge would
do that job better than you, and a bundle carries one.

## Why not install everything

That's the question everyone asks, and the answer isn't "to save disk space" — modules weigh a few
hundred kilobytes.

The real reason is **routing**. Every module lays down agents and skills, and each describes in
plain language the situations where it should fire. The more you lay down, the more those
descriptions resemble and overlap each other, and the higher the risk that a request goes to the
wrong brick. A lab carrying all three business bundles plus both orchestrators has to arbitrate
between far more candidates for every sentence you type. The modules you don't use aren't neutral:
they're noise in the decision.

The second reason is the **comprehension load**. A lab you composed yourself, module by module, is
a lab you can explain. A lab where everything is ticked is one where you no longer know who
produced what the day a result surprises you — and that's precisely the day you need to know.

The third is **maintenance**. Every module laid down is a module to carry forward when VibeFlow
moves. Removing a module you don't use is a healthy gesture, not an admission of failure — and
[enabling-and-disabling.md](./enabling-and-disabling.md) shows it takes one command, with a backup taken
before anything is deleted.

So the right reflex: start small, add when you feel something missing. VibeFlow is built so that
adding later is trivial — far more trivial than untangling an overloaded lab.

One last reassuring thing: **this choice isn't final**. None of the compositions above commits you
to anything. Adding a module next week, dropping one the month after, changing direction entirely
because your project changed — all of it takes one command, with a backup, and without losing your
lab's content. The work you've accumulated in `.planning/` belongs to the lab, not to the modules;
it survives their comings and goings.

So don't spend an hour optimizing this decision. Take the profile that looks most like you, start
working, and adjust once reality has taught you something this page couldn't have.

<!-- vf-manual:nav -->
[← Previous](../03-modules/baseline-and-dependencies.md) · [↑ Contents](../README.md) · [Next →](../03-modules/business-bundles.md)
<!-- /vf-manual:nav -->
