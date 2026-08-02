# Business bundles

<!-- vf-manual:lang -->
[Français](../../fr/03-modules/bundles-metier.md) · **English**
<!-- /vf-manual:lang -->

A **bundle** is a particular kind of module: instead of adding one capability, it lays down an
**entire team** ready to work in a given line of business. Three bundles ship today — content,
business, growth — and they all share the same skeleton.

That skeleton comes from the team-kernel, the team orchestration core defined once and reused
everywhere: a **mission manager** that plans and distributes, **cloistered workers** that each
produce their part without seeing the rest, and a **judge** that scores the result without having
watched it being made. If those words don't mean anything to you yet, the
[glossary](../02-concepts/glossary.md) defines them all.

## What each bundle lays down

**`content-bundle` — the editorial studio.** The chain runs from brief to framing, from framing to
writing, then to repurposing into other formats. The manager `vf-content-manager` distributes,
`vf-content-strategist` frames, `vf-content-writer` writes, `vf-content-repurposer` repurposes. The
judge is called **`content-clarity-judge`**: it scores the piece's clarity and rejects the ones
that fall short. This is the bundle you use to produce content in series without quality drifting
by the third article.

**`business-pilot-bundle` — commercial steering.** The chain runs from offer to sales pipeline,
from pipeline to delivery, then to revenue. `vf-business-manager` distributes,
`vf-business-commercial` qualifies and writes proposals and quotes, `vf-business-delivery` tracks
milestones, `vf-business-finance` prepares invoices and forecasts. The gate is called
**`quality-gate-client`**: it scores everything meant to go out to a client.

**`growth-bundle` — the acquisition studio.** The chain runs from brief to channel strategy, from
strategy to producing sequences and creatives, then to measurement. `vf-growth-manager`
distributes, `channel-strategist` picks the channel and audience, `copywriter-sequences` produces,
`campaign-analyst` measures and returns a verdict — carry on, iterate, or stop. The judge is called
**`growth-quality-judge`**.

All three install **on top of** the baseline, never in its place: each declares the same core
dependencies as the others in its `module.json`. Nothing technically stops you from installing
several, but [choosing-your-modules.md](./choosing-your-modules.md) explains why that's rarely a good
idea at the start.

## What tells them apart from a bundle of prompts

That's the real question, and it deserves a clear answer. You could assume a bundle is just a
collection of good domain prompts. Two mechanisms tell it apart.

The first is the **fresh judge**. Every bundle ships an evaluation agent that didn't watch the
production happen: it discovers the finished deliverable, just like you do. It scores it against an
explicit rubric and returns a numeric verdict — the threshold is eighty out of a hundred in all
three bundles. Below that, the deliverable goes back for correction. An agent judging its own work
always finds it good; that's exactly what this arrangement prevents.

The second is the **eliminatory criterion**. Every judge carries at least one rule that fails the
deliverable regardless of the rest of the score. An unsourced figure fails a content piece or a
campaign, however excellent it is otherwise. An invented financial figure fails a business
deliverable. These aren't recommendations written in prose inside a prompt: they're criteria in the
scoring rubric, and they're eliminatory.

And above both: **nothing goes out without you**. None of the three bundles sends, publishes, or
launches anything. The lab prepares, the judge validates, and the deliverable is marked "ready" —
you're the one who sends, from your own tools. A deliverable that's green with the judge isn't a
deliverable that left: it's a deliverable that has earned the right to be shown to you. The general
mechanism behind these stopping points is described in
[gates-and-human-validation.md](../02-concepts/gates-and-human-validation.md).

## How you actually use one

Each bundle exposes a single simple entry point, a skill named after the line of work —
`vf-content`, `vf-business`, `vf-growth`. You describe your mission in plain language, the skill
routes to the bundle's manager, and the manager does the rest: it plans, distributes to the
workers, runs the judge, and stops to ask for your opinion at the points designed for it.

### What a bundle does not do

Three limits deserve to be stated plainly, because they save you a disappointment.

A bundle **doesn't know your trade for you**. It knows the *shape* of the work — the steps, the
checks, the order — not your clients, your positioning, or your tone of voice. Those live in the
lab, in the framing documents you write once and the agents re-read on every mission. A bundle laid
on an empty lab produces generic output; that's normal, and it's fixed by feeding the lab, not by
switching bundles.

A bundle **connects to no external tool**. It doesn't post to a network, doesn't send email,
doesn't touch your CRM. That's a choice, not a gap: real execution stays in your tools, with your
credentials and your responsibility.

A bundle **doesn't replace your judgement on substance**. The judge checks the quality of the form
and the absence of eliminatory faults — it doesn't know whether the angle you picked is the right
one for that client that week. That part stays yours, and it's the part that carries value.

You don't need to know the agent names quoted above. They're given here so you can understand who
did what when reading a mission report — not so you'd call them by hand. That's the principle
behind every VibeFlow orchestrator: you talk to the top, the plumbing stays underneath.

And if you ever want to see the plumbing, nothing hides it: each bundle keeps its agents in an
`agents/` folder next to its skill, one readable file per agent. Opening one tells you exactly what
that agent was told to do — including what it's forbidden from doing.

<!-- vf-manual:nav -->
[← Previous](../03-modules/choosing-your-modules.md) · [↑ Contents](../README.md) · [Next →](../03-modules/enabling-and-disabling.md)
<!-- /vf-manual:nav -->
