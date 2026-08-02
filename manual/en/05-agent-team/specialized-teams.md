# Specialized teams

<!-- vf-manual:lang -->
[Français](../../fr/05-equipe-agents/equipes-specialisees.md) · **English**
<!-- /vf-manual:lang -->

Everything you've read so far described the shared mechanics — the team-kernel, reused everywhere.
This page says what that produces concretely beyond development: three other domains where
VibeFlow deploys a team instead of a single agent. The detailed catalog of the modules that pose
them lives in [business-bundles.md](../03-modules/business-bundles.md) — here, it's about how these
teams **work**, not what each one ships in detail.

## The design team

As soon as a lab has an interface to design, improve, or critique, the `vibeflow-design` agent
routes your request — saying "this looks ugly", "what style should we go with?", or "redo the
whole app" is enough, you don't need to know the internal step names. On a large enough project,
it deploys a team: `vf-design-manager` plans in a DAG and dispatches `vf-crafter` (screen
production) and `vf-design-judge` (scored critique) in parallel across screens that don't overlap.

This team's "green" carries a numeric threshold: a screen must score at least 70 out of 100
against the lab's art direction to pass, with a cap of three correction rounds per screen before
escalation. It's the same fresh-judge principle as everywhere else in VibeFlow, applied here per
screen rather than to the whole mission.

**Actual status**: this module is installed by default alongside `dev-orchestrator` on every
development lab, with no extra action from you. It's not marked experimental — it's a mature
piece of the dev baseline.

One detail that matters to you: this team produces **specs and tokens**, adapted to your project's
detected stack (CSS variables, Swift tokens, a React Native or Flutter theme object depending on
the case), never framework code imposed by force. The real toolchain working behind the scenes —
UX reference, craft workshop — stays invisible to you: everything it produces gets reframed into
VibeFlow's vocabulary before it reaches you, and the module degrades gracefully to first design
principles if a third-party tool happens to be missing rather than failing without explanation.

## The mobile QA team

A screen can compile, pass its unit tests, and still crash at runtime on a real phone. Two
distinct modules cover that gap, and it's worth knowing the boundary between them.

The first, `mobile-test`, is the **mechanics**: a deterministic script that detects the target
(iOS simulator or Android emulator), builds if needed, runs a Maestro regression, and diagnoses
failures visually. The second, `mobile-test-team`, is the **autonomous loop** laid on top:
`vf-test-orchestrator` drives the test → fix → re-test cycle, with `vf-test-runner` and
`vf-app-fixer` fenced off from each other — whoever fixes the application code never touches the
tests, and vice versa. That fencing is what stops the most tempting cheat: weakening a test to
make it pass instead of fixing the real problem.

You call on this team either directly through its skill, or indirectly: a dedicated rule wakes
itself up as soon as you edit mobile screen code or a Maestro flow, and makes the doctrine of real
verification active while you develop.

**Actual status, stated plainly**: both modules are **explicitly experimental**, and their own
documentation says so without softening it. The mechanical pipeline was designed and validated
under real conditions on its origin project, but **no real green run has been traced yet in a
VibeFlow context** — that's precisely the exit condition for this status. The autonomous loop
carries an additional risk, named as such by its own authors: a sub-agent that drives other
sub-agents through nested dispatches hasn't yet been proven by a real end-to-end run. Until those
runs exist, treat both modules as a solid base **still to be confirmed**, not as a proven
mechanism on par with the design team or the business teams below.

A practical prerequisite specific to this team: it requires a per-project configuration file
(bundle id, Android emulator name, preferred iOS simulator) — no value is hardcoded, and the
script refuses to run until that configuration exists rather than guessing. That's deliberate: a
wrong assumption about the target would produce a test report that looks valid without being one.

## The business teams

Beyond code and design, three bundles pose a complete team for a given business function:
content, sales pipeline management, acquisition. All three rest on the same structure — a manager
that plans and distributes, fenced-off workers that each produce their part, a fresh judge that
scores the outcome without having watched it get made — and all three carry at least one
eliminatory rule in their scoring rubric: an unsourced figure or an invented financial number
fails a deliverable, whatever the rest of its score.

Each bundle runs a different chain — content's editorial chain isn't sales pipeline management's —
but the shared structure means reading one bundle's mission report prepares you to read another's:
same roles, same vocabulary, same stopping points.

What's worth repeating here, because it's the point that sets a business team apart from a simple
package of well-written prompts: **nothing ships without you.** None of these bundles sends,
publishes, or launches anything toward the outside. The lab prepares the deliverable, the judge
validates it, and it gets marked "ready" — you're the one who sends it, from your own tools, with
your own credentials. You call on them through a skill named after the function (`vf-content`,
`vf-business`, `vf-growth`), in natural language, exactly like a development mission.

**Actual status**: all three bundles are stable modules, not experimental — their validation
doesn't hinge on a run still to come, unlike the mobile QA team above. What each one ships, agent
by agent, is in [business-bundles.md](../03-modules/business-bundles.md).

A team is never presented on equal footing with another when their actual status differs. That's
deliberate: knowing a module is still to be confirmed changes how you read its reports, and hiding
that difference would produce a manual that promises more than the product delivers.

A lab can install several of these teams without conflict — each declares its own baseline
dependencies on top of the same foundation — but nothing forces you to pose them all upfront. A
team placed on a lab that doesn't yet carry the framing content it needs (positioning, tone of
voice, art direction) will produce generic work; that's not a flaw in the team, it's a lack of
material to feed it, and it's fixed by feeding the lab, not by switching modules.

The same read applies across all four teams on this page: what they can do is fixed by their
design, but how well they do it still depends on what you've told the lab about your work before
asking it to run.

<!-- vf-manual:nav -->
[← Previous](../05-agent-team/branches-and-worktrees.md) · [↑ Contents](../README.md) · [Next →](../06-reference/commands.md)
<!-- /vf-manual:nav -->
