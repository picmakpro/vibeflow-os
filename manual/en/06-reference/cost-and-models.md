# Cost and models

<!-- vf-manual:lang -->
[Français](../../fr/06-reference/couts-et-modeles.md) · **English**
<!-- /vf-manual:lang -->

VibeFlow has no pricing of its own: you pay for your Claude usage, directly, the same as any
Claude Code session. So this page gives **no price** — it explains what actually drives your
usage up or down, and what you can genuinely decide to keep it in check. No dollar or euro figure
appears below, anywhere.

## Which model runs, and why

VibeFlow's [31 agents](./agents.md) don't all run on the same model. The split isn't "judge versus
executor" — on this repo, quality judges run on sonnet, exactly like the workers they evaluate.
The real split tracks the **nature of the judgment being asked for**:

- **Face agents and mission managers** (opus, ten agents total) — routing a request whose intent
  isn't yet clear, planning a task graph with cross-dependencies across several independent
  tracks, arbitrating a call that no explicit rubric can make for you. That's open-ended judgment,
  over a scope that can shift mid-mission.
- **Workers and judges** (sonnet, twenty-one agents) — producing a specific deliverable against an
  already-framed mandate, scoring a result against a rubric written out in black and white,
  executing a step already identified. That's a bounded scope, known ahead of time.

One notable exception proves the rule rather than breaking it: `vf-test-orchestrator` drives a
mission like the other five managers, but stays on sonnet — its loop (test, fix, re-test until
budget runs out) is a bounded scope from the start, without the open-ended trade-offs of a
multi-domain battle plan.

The full breakdown, agent by agent, lives on [agents.md](./agents.md).

You never have to guess this: each agent file's `model:` frontmatter field states it explicitly,
and the [agent reference](./agents.md) reproduces it for all 31. To read it yourself on disk,
`grep model: plugin/*/agents/*.md plugin/*/AGENT.md` from the repo root gives the full list — the
same command a maintainer would run before touching any of this page's claims.

## The levers that actually control your spend

**The scope of your request.** A precise sentence ("fix the failing test in `auth.spec.ts`")
frames the work from the start. An open one ("improve the project") forces whichever agent answers
you to explore before it can act — that isn't a VibeFlow flaw, it's the normal cost of ambiguity,
the same cost you'd pay handing the same vague sentence to any human collaborator.

**The length of a mission.** The more independent tracks a mission covers, the larger the planning
context its manager holds throughout execution — even though each worker it dispatches stays on a
short, cheap mandate of its own. A three-step mission and a twenty-step mission don't cost the
same, and not linearly: the manager re-reads progress at every stage change.

**Choosing autonomous mode.** A mission launched in
[autonomous mode](../04-development-cycle/autonomous-mode.md) chains framing, planning, and execution
without coming back to you at every step — so you accumulate work (and usage) before reviewing it,
rather than splitting it into tight checkpoints. That's neither better nor worse: it's a trade-off
between your supervision time and your visibility along the way, one you choose when you phrase
your request.

**The modules you have installed.** Every module adds its own agents and skills to what the lab
can dispatch. A request that touches several domains at once (dev **and** design, say) can route
through several teams if the matching modules are installed — a richer lab has more possible
paths, not necessarily pricier by itself, but with more surface across which a broad request can
spread.

### What costs more than you'd expect

**A correction loop that doesn't converge.** A review cycle that comes back around three times in
a row obviously costs three times what it would have if it had converged on the first try.
VibeFlow caps this risk by design — a halt escalates the decision to you instead of retrying
indefinitely — but the cap limits the damage, it doesn't erase it: the attempts already spent
before the halt stay spent.

**A broad audit rather than a targeted one.** `/vf-audit` orchestrates five complementary audits
in one pass — more complete than one alone, and logically longer. If you already know which
dimension you care about (security, memory debt), an optional argument narrows the focus instead
of rerunning everything.

**A conversation split into many small exchanges.** Ten short, vague requests, asked one at a
time, force ten separate explorations where a single well-phrased request covering the same need
would have made just one.

## Five efficiency levers, quantified on this repo

This repo quantifies five efficiency levers of its own construction, as measured on this repo on
2026-08-01 — reproduced here as a measurement observed at that date, not a guarantee that holds
forever:

| Lever | Measured effect |
|---|---|
| Sonnet workers and judges, opus reserved for the manager | bulk volume at the right price |
| Mission digest bounded by construction, per mandate | on the order of one hundred to two hundred thousand re-reading tokens saved per step |
| Parallel dispatch (judges in parallel, disjoint graph nodes in parallel) | the sequential wait-wall falls |
| Next step framed while the current one is still executing | zero dead time between steps |
| On-demand loading of the doctrine | it stays out of context until it's actually needed |

This figure stays a measurement dated to this phase of the repo, not a promise about your own
lab — which is exactly why this page never copies it as a settled fact. The five levers
themselves stay documented throughout this manual, theme by theme, and that's where they remain
true independent of this precise figure; for what has changed on this repo since that date,
`CHANGELOG.md` (repo root) is the source that keeps growing.

<!-- vf-manual:nav -->
[← Previous](../06-reference/agents.md) · [↑ Contents](../README.md) · [Next →](../06-reference/troubleshooting.md)
<!-- /vf-manual:nav -->
