# Issue amont — prête à poster sur open-gsd/gsd-core

> **Statut : RÉDIGÉE, NON POSTÉE.** Poster est un geste externe gaté humain — sur accord de
> Samuel : `gh issue create --repo open-gsd/gsd-core --title "<titre ci-dessous>" --body-file <ce
> corps>`. Rédigée le 2026-08-10 contre gsd-core **1.10.0** (post-#3021). Contexte lab :
> `27-AUDIT-claude-orchestration-amont.md`.

---

**Titre :**

```
bug(claude-orchestration): workflow backend never populates WAVE_WORKTREE_MANIFEST — executor commits stay stranded on worktree-wf_* branches (follow-up to #3021)
```

**Corps :**

```markdown
## Summary

#3021 (fixed in 1.10.0) taught the three worktree guards about the Workflow tool's
`worktree-wf_<runid>-<n>` branch namespace. This report is the next gap on the same
backend, one layer up: **nothing ever populates `WAVE_WORKTREE_MANIFEST` when a wave is
dispatched through the Workflow tool**, so the manifest-scoped merge chain — the only
authorized merge path — has no input. Executor commits complete successfully and then
stay stranded on their `worktree-wf_*` branches. No error is raised; the phase looks
green while its work never reaches the integration branch.

We hit this on a real run (details below), then confirmed by static analysis that the
gap is structural, not environmental.

Environment: GSD 1.10.0 (also present in 1.9.1), Claude Code (standalone install),
`workflow.use_worktrees: true`, `claude_orchestration.enabled: true`,
`execution_backend: "auto"`, all 7 gates passing (`workflow_backend_active`).

## The gap

The merge chain is manifest-scoped by design (#3384: "Do not fall back to broad worktree
discovery"), and the manifest is populated at exactly one point:

- `workflows/execute-phase.md:780` — "**After each `Agent()` returns**, parse
  executor-returned worktree metadata (`<worktree_metadata>`) … then record the
  `{agent_id, worktree_path, branch, expected_base}` entry with
  `gsd_run query worktree.record-agent --manifest "$WAVE_WORKTREE_MANIFEST" …`"

On the workflow backend there is no per-plan `Agent()` return: a **single tool call
wraps the whole wave**, so the orchestrator never sees the individual
`<worktree_metadata>` blocks. The manifest stays `{worktrees: []}` and
`worktree.cleanup-wave` correctly merges nothing.

The capability's own docs assert the opposite without any code behind it:

- `bin/lib/capability-registry.cjs` (the `execute:wave:pre` fragment): "The orchestrator
  still runs steps 4–5.8 (wait for completion, worktree cleanup, post-merge gate,
  tracking update) **exactly as it does for inline dispatch**"
- `bin/lib/claude-orchestration.cjs:503-504` (emitted script tail): "// Each agent writes
  SUMMARY.md on its worktree branch; commits land there **and are merged by the
  orchestrator exactly as in inline wave dispatch**."

`grep -rn "wf_" gsd-core/` shows the only `wf_`-aware code is #3021's guard fix; no code
bridges Workflow-run results into `record-agent`. There is also no safety net behind the
gap: `reap-orphans` skips unmerged branches (`branch_not_merged`), and the Claude Code
harness never merges subagent worktrees (its periodic sweep explicitly spares worktrees
that still hold work). Stranded branches accumulate indefinitely.

## Observed on a real run

2-plan wave, disjoint `files_modified`, dispatched via `resolve-wave-dispatch` (no
`--agent-sdk-version` flag; gate ladder fully green) and executed with the real Workflow
tool:

- Both agents completed in parallel, wrote their files, no collisions, no errors.
- Zero worker commits reached the integration branch; both worktrees
  (`.claude/worktrees/wf_<runid>-{1,2}`, branches `worktree-wf_<runid>-{1,2}`) were left
  behind with the work in them, invisible to `cleanup-wave` (empty manifest).

Note the run used short test briefs, so the agents also skipped the commit protocol —
that part is on us (see finding 2). But even with contract-compliant briefs and
committing agents, the empty manifest means the merge chain still has no input.

## Suggested direction

The per-agent results are recoverable after the run: the Workflow runtime journals one
`{"type":"result",...}` line per agent (`journal.jsonl` in the run's transcript dir),
and `gsd-executor`'s `<worktree_metadata_capture>` block already puts the metadata in
each result. Two options, either would close the gap:

1. Specify in the `execute:wave:pre` fragment that after the Workflow run completes, the
   orchestrator extracts each agent's `<worktree_metadata>` from the run's per-agent
   results and feeds them to `worktree.record-agent` (namespace already accepted since
   #3021), then runs the existing `cleanup-wave` unchanged; or
2. Have the emitted script `return` the agents' results (it currently returns nothing),
   so the orchestrator receives the metadata in the tool result itself, then record +
   cleanup as above.

## Related findings (same backend, smaller)

1. **Gate 4 is hardcoded.** `claude-orchestration-command-router.cjs:60`
   `const CAPABLE_HOST = { dispatch: { nested: true, background: true } };` (applied at
   `:160`): the registry's runtime descriptor is never read, so gate 4 always passes
   except under a manual `--no-nested-dispatch`. There is no actual detection of the
   Workflow tool's presence; the only real discriminators are runtime id + SDK version.
2. **Brief spec omits two blocks.** The fragment's brief contract enumerates
   `<objective>/<execution_context>/<files_to_read>/<success_criteria>` but omits
   `<worktree_branch_check>` (the build-time `{EXPECTED_BASE}` embed) and
   `<parallel_execution>`, both of which the inline path carries.
   `emitWorkflowScript` treats the brief as an opaque string, so nothing catches the
   omission.
3. **Resume widens the gap.** `resumeFromRunId` replays completed agents from cache;
   cached agents don't re-emit metadata, so after a resume even option 1 above can't see
   the earlier agents' worktrees unless the journal from the original run is consulted.
4. **Role mismatch.** The contribution is declared `into: "executor"` while its entire
   text addresses the orchestrator (per `references/loop-hook-dispatch.md`'s contract).

Happy to provide the full run transcripts or test the fix on our setup.
```
