# Enabling, disabling, changing your mind

<!-- vf-manual:lang -->
[Français](../../fr/03-modules/activer-desactiver.md) · **English**
<!-- /vf-manual:lang -->

You composed your lab, you're using it, and something is missing. Or the opposite: a module you
laid down three months ago is no longer useful. This page covers those three gestures — adding a
module, removing one, changing scope — for a lab that already exists.

It does **not** cover uninstalling VibeFlow entirely, nor updates: that's the subject of
[updating-and-uninstalling.md](../01-get-started/updating-and-uninstalling.md). Here we touch a
single module inside an installation that stays in place.

## The gesture, in all three cases

There's only one front door: the `/vibeflow-install` command. Despite its name, it isn't only for
the first install — it's also the reconfiguration command. You run it whenever you like, as many
times as you like, and you say what you want in plain language:

```
/vibeflow-install
```

Then, depending on your need: "add the design module", "remove kpi-analyst", "I want to change
scope". The gesture is the same in all three cases; what changes is what you ask for.

**Adding a module.** The tooling first resolves the requested module's dependencies, shows you the
complete list of what's about to be laid down, and waits for your confirmation. A module that pulls
others in tells you **beforehand**, not after — you never discover a module on your disk without
having seen it go by in a summary.

**Removing a module.** Removal deletes what belongs to that module and to it alone: its skills, its
agent and reference files, its scripts, its rules. What belongs to another module stays. And if the
module you want to remove is required by a module still installed, the tooling refuses rather than
break the chain — the dependency logic is in
[baseline-and-dependencies.md](./baseline-and-dependencies.md).

**Changing scope.** This is the least trivial of the three, because it moves everything installed
from one place to another. It's covered in
[choosing-your-scope.md](../01-get-started/choosing-your-scope.md), which explains what moves and what to
check afterwards.

## What gets backed up, and what doesn't

**Before any deletion, a backup is created.** That's the default behaviour of removal: the tooling
copies what it's about to erase before erasing it. If a removal turns out to be a mistake, you
haven't lost the configuration — you have a point to come back to.

**Adding is idempotent, removing isn't.** Re-running an install of a module already laid down does
no damage: the tooling puts the same thing in the same place and the result is identical. Removing,
on the other hand, is destructive by nature: removing the same module a second time has nothing
left to remove, and more importantly, if you'd hand-edited a file that module laid down, that edit
leaves with it. One more reason not to edit the files a module drops directly.

**One nuance worth knowing**: removal scope must be **the install scope**. If you installed at
account level and ask for a removal at project level, the tooling will find nothing to remove — and
will say so, without breaking anything. If you no longer remember which scope you used, the install
registry knows; ask for it rather than guess.

## What to check afterwards

Three reflexes, in order, none of which takes more than a minute.

**Restart your Claude Code session.** Agents and skills are loaded when the session starts. Until
you've restarted, you're working with the old composition, and you may wrongly conclude that a
freshly laid-down module doesn't work. This one catches almost everybody the first time.

**Have the lab checked.** The conformity audit exists for this: it looks at whether what's laid down
holds together, whether files from a removed module are still lying around, whether a reference
points at nothing. That's the gesture that turns "I think it's fine" into "it's verified" — and it
costs one sentence: ask your lab to audit itself.

### If something looks wrong

Two situations come up often, and neither is serious.

**A removed module left traces.** An orphaned file, a reference pointing at nothing. The lab audit
detects them; it lists them and offers to clean up, without doing it on its own initiative. That's
also what the backup created before removal lets you recover if the cleanup went too far.

**Two modules seem to fight over the same request.** You phrase a sentence and the other module
takes over. That's the symptom described in [choosing-your-modules.md](./choosing-your-modules.md): too
many candidates for the same intent. The most effective answer isn't to rephrase your sentence
indefinitely, it's to remove the module you don't use.

**Try the module.** A module that's laid down but doesn't answer the sentence it exists for is a
useful signal. Ask it exactly what the [catalog](./catalog.md) says it knows how to do. If it
doesn't take over, the explanation is almost always one of the previous two: session not restarted,
or a different scope than you thought. Check both
before assuming anything worse.

These three reflexes apply to all three gestures — adding, removing, changing scope. Doing them
every time costs three minutes and avoids the most irritating category of error there is: the one
where everything is correctly installed, but you spend an hour hunting a problem that doesn't
exist. Restart, audit, try — in that order, and only then start worrying.

<!-- vf-manual:nav -->
[← Previous](../03-modules/business-bundles.md) · [↑ Contents](../README.md) · [Next →](../03-modules/where-a-module-lives.md)
<!-- /vf-manual:nav -->
