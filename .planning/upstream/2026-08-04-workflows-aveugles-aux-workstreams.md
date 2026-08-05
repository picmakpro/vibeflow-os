> ## ⛔ BANDEAU DE STATUT — pour nos agents, PAS pour l'amont
>
> **Ce texte est rédigé et prêt à poster. Il n'a PAS été posté.** Son **dépôt est réservé à
> validation humaine** (**ADR-031**) : aucun agent ne l'ouvre en issue, aucun appel d'API de forge
> n'est exécuté. Le corps ci-dessous commence à la ligne « --- » et est **en anglais**, langue du
> dépôt amont ; ce bandeau est le seul passage en français et **ne fait pas partie du texte à
> poster**.
>
> **Cette remontée est compatible avec l'adoption.** Les deux ne s'excluent pas — contrairement à ce
> que la recommandation D du cadrage laissait entendre, où la remontée amont était le complément
> d'un *refus*. Le lab a adopté les workstreams (**ADR-069**) **et** remonte la mesure : signaler
> qu'une capacité est peu couverte par son propre corpus de workflows n'est pas se dédire de
> l'avoir adoptée, c'est documenter ce qu'on a adopté.
>
> **Chiffres re-dérivés à l'écriture** le 2026-08-04, sur `@opengsd/gsd-core` **1.9.1** : identiques
> au fichier près à `24-COLLISIONS.md` § M-1 et à ADR-069. **Aucun écart.**
>
> **Cadrage de forme, non négociable** : ce n'est pas un rapport de comportement fautif. La capacité
> fait ce qu'elle est codée pour faire. Ce qui est remonté est que **la surface déclarée ne décrit
> pas le corpus qui la consomme** — même famille que le précédent **#2598**, dont la forme a été
> acceptée en amont.

---

# workstreams: the documented coverage does not describe the workflow corpus — 7 of 91 root workflows can resolve a workstream scope (1.9.1)

## Summary

This is not a report about wrong behaviour. `active-workstream-store.cjs` resolves exactly as
written, and every workflow listed below reads exactly the path it was authored to read.

What this report is about is a **descriptive gap**: the workstream capability is presented as a
project-wide scoping mechanism, but the workflow corpus that consumes `.planning/` was, in the
overwhelming majority, written before that scope existed and still addresses the repository root
unconditionally. A user who partitions `.planning/` into workstreams therefore gets a capability
whose declared surface does not match the surface the workflows actually implement.

Measured on `@opengsd/gsd-core` **1.9.1**, on 2026-08-04.

| Measure | Value |
|---|---|
| Root workflows (`workflows/*.md`, depth 1) | **91** |
| Workflows that can resolve a workstream scope | **7** (**7.7 %**) |
| Workflows that hardcode a root `.planning/` path | **45** |
| Of those, workflows with **no awareness at all** of workstreams | **42** |

## Why the count depends on a named criterion

Three different inclusion criteria are defensible, and they give three different numbers. Any of
them is fine to quote — quoting one *without naming it* is what makes two good-faith readers reach
opposite conclusions. All three are published here:

| # | Inclusion criterion | Aware | Rate | Hardcoded | Unaware |
|---|---|---|---|---|---|
| K1 | contains the word `workstream` (case-insensitive) only | 5 | 5.5 % | 45 | 43 |
| **K2** | contains `workstream` **or** the `--ws` option — *can resolve a scope* | **7** | **7.7 %** | **45** | **42** |
| K3 | K2 **or** the `GSD_WS` variable — any surface at all | 16 | 17.6 % | 45 | 35 |

**K2 is the number quoted in the title**, because the question this report asks is *can this
workflow resolve a scope?* — not *does the word appear?* (K1) and not *does the variable transit
through it?* (K3).

Two details worth having:

- K1 undercounts by false negatives. The two files K2 adds — `verify-work.md` and
  `plan-review-convergence.md` — do handle `--ws` (`verify-work.md:42-43` parses it into `GSD_WS`)
  **without ever writing the word** `workstream`.
- K3 contains one isolated false positive: `reapply-patches.md:220` mentions `${GSD_WS}` only as an
  *example of variable drift* in patch-reconciliation documentation. K3 is therefore 16 raw / 15
  real. K3 also conflates two different things: of its 16, **7 resolve** a scope and **9 merely
  propagate** `${GSD_WS}` inside a suggested command. Propagating is not resolving — but it is not
  being unaware either.

## Reproduction

`awk` for every count, `comm` for every set comparison. No `grep` in a pipeline: on the workstation
where this was measured, a piped `grep` silently truncated its output (31 of 102 matching lines
returned). That is a caveat about the local measuring tool, not about `gsd-core` — it is stated so
that the numbers below reproduce exactly rather than approximately.

The `seen` counter is not decoration. An earlier invocation of an equivalent loop reported **4**
files instead of 91, silently. Any run whose `seen` is not 91 should be discarded rather than
interpreted.

```bash
W="$HOME/.claude/gsd-core/workflows"; T1=$(mktemp); H=$(mktemp); seen=0
for f in "$W"/*.md; do
  [ -f "$f" ] || continue; seen=$((seen+1))
  # K2: knows the word, or handles the --ws flag
  awk -v F="$f" 'tolower($0) ~ /workstream/ || /--ws([^a-zA-Z0-9-]|$)/ { print F; exit }' "$f" >> "$T1"
  # hardcodes a root .planning path
  awk -v F="$f" '/\.planning\/(ROADMAP\.md|STATE\.md|phases)/           { print F; exit }' "$f" >> "$H"
done
sort -u "$T1" -o "$T1"; sort -u "$H" -o "$H"
echo "seen=$seen (must be 91)"
echo "aware=$(awk 'END{print NR+0}' "$T1")  hardcoded=$(awk 'END{print NR+0}' "$H")  unaware=$(comm -13 "$T1" "$H" | awk 'END{print NR+0}')"
comm -13 "$T1" "$H"   # the 42 unaware files, by name
```

Expected on 1.9.1: `seen=91`, `aware=7  hardcoded=45  unaware=42`.

The depth matters: `workflows/*.md` at **depth 1** is 91 files; the same directory is **115**
recursively. All figures here are the depth-1 corpus.

## The 42 workflows with no workstream awareness

`add-backlog.md` · `add-phase.md` · `add-tests.md` · `add-todo.md` · `analyze-dependencies.md` ·
`audit-fix.md` · `audit-milestone.md` · `autonomous.md` · `check-todos.md` · `cleanup.md` ·
`complete-milestone.md` · `diagnose-issues.md` · `discovery-phase.md` ·
`discuss-phase-assumptions.md` · `discuss-phase.md` · `edit-phase.md` · `execute-phase.md` ·
`execute-plan.md` · `extract-learnings.md` · `fast.md` · `forensics.md` · `graduation.md` ·
`import.md` · `ingest-docs.md` · `insert-phase.md` · `list-phase-assumptions.md` ·
`milestone-summary.md` · `new-project.md` · `next.md` · `pause-work.md` ·
`plan-milestone-gaps.md` · `plan-phase.md` · `pr-branch.md` · `progress.md` · `quick.md` ·
`remove-phase.md` · `resume-project.md` · `review.md` · `session-report.md` · `ship.md` ·
`smart-entry.md` · `undo.md`

The seven that can resolve a scope, for completeness: `new-milestone.md`,
`plan-review-convergence.md`, `settings-advanced.md`, `settings-integrations.md`, `settings.md`,
`transition.md`, `verify-work.md`.

The practical consequence is that passing `--ws` to one of the 42 does not help: the flag is not
read, and the workflow writes to the root regardless of what was passed. The failure is silent —
there is no point at which the user is told the scope was ignored.

## A second, narrower point: `pr-branch.md:235-236`

This one is narrow enough to be actionable on its own, independently of the coverage question.

The commit classification in `pr-branch.md` anchors its regexes to the repository root:

```bash
STRUCTURAL=$(... grep -E "^\.planning/(STATE|ROADMAP|MILESTONES|PROJECT|REQUIREMENTS)\.md|^\.planning/milestones/" ...)
TRANSIENT_ONLY=$(... grep "^\.planning/" | grep -vE "^\.planning/(STATE|ROADMAP|...)\.md|^\.planning/milestones/" ...)
```

On a partitioned repository, a workstream's roadmap state lives at
`.planning/workstreams/<ws>/STATE.md`. That path does not match the `STRUCTURAL` anchor, so it falls
through to `TRANSIENT_ONLY` and the commit is classified **EXCLUDED**.

The effect is that **roadmap-state commits silently disappear from PR branches** on exactly the
repositories that adopted the capability. Nothing warns; the branch simply comes out lighter than
the history it was built from. This is the same descriptive gap as above, in its most concrete
form: the classifier describes a single-root layout, and the workstream layout is not one.

## Prior art and non-duplication

Checked before writing, so this is not a re-report:

- **#853** — closed without addressing the limitation it carried. It is not this case.
- **#2598** — the closest precedent, and the form this report follows: a capability descriptor that
  does not describe the runtime, rather than a claim of faulty behaviour. That framing was accepted
  upstream, which is why it is reused verbatim here.
- **#2939** — open, but about a different runtime.

No one appears to have filed this particular case. If it duplicates something we missed, we would
rather be pointed at it than have it filed twice.

## What we are asking for

Nothing urgent, and explicitly **not** a request to make 42 workflows workstream-aware.

Two things would be enough to close the descriptive gap:

1. **State the coverage in the documentation** — with a named criterion, so it stays checkable
   across releases. "7 of 91 root workflows can resolve a workstream scope in 1.9.1" is a fact a
   reader can act on; a general statement that workstreams scope the project is one they cannot.
2. **Consider `pr-branch.md:235-236` on its own merits.** Extending the `STRUCTURAL` anchor to
   `^\.planning/workstreams/[^/]+/(STATE|ROADMAP|...)\.md` would be a contained change with a
   clearly visible effect, and it is the one place where the current anchoring loses user data
   rather than merely ignoring a flag.

For context on how we consume this: we have adopted workstreams downstream and mitigated the four
limitations we measured, including this one. This report exists because the mitigation is only
possible for someone who has measured the corpus, and the measurement should not have to be
re-derived by every adopter.

*Measured on `@opengsd/gsd-core` 1.9.1, 2026-08-04.*
