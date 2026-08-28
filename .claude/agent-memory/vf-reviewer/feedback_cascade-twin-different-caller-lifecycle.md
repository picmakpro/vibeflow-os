---
name: cascade-twin-different-caller-lifecycle
description: a resolution cascade claimed "identical" to a working precedent (find_hooks_merger()) can still be dead code if the CALLER's $0 lifecycle differs across install vs re-invocation
metadata:
  type: feedback
---

`runtime-cli-dispatch.sh` (Phase 38, RUNT-01/02, `plugin/_internal/`) documented its resolution as
"cascade EXACTE de find_hooks_merger()" (`$CACHE_DIR/_internal/…` then `$(dirname "$0")/…`) and
was accepted on that precedent's authority. Traced end-to-end (repro'd with a real install + a
real post-install re-invocation, `plugin/_internal/tests/test-vibeflow-update.sh`'s own
`prepare_module`/`VIBEFLOW_CACHE=` pattern) it is NOT equivalent: `find_hooks_merger()` is called
BY `vibeflow-update.sh` itself, whose `$0` is always `_internal`-adjacent (cache or dev tree) at
every invocation — so its `dirname "$0"` fallback always resolves. `runtime-cli-dispatch.sh`'s
callers (`ensure-deps.sh`, `ensure-design-deps.sh`, `check-plugin-update.sh`) are themselves POSED
module scripts: at install time `$0` is `$VIBEFLOW_CACHE/<mod>/scripts/…` (candidate 1 resolves,
`VIBEFLOW_CACHE` is exported) but at every REAL post-install re-invocation (`/vf-update` step 4c,
`/vf-calibrate`, the `check-plugin-update.sh` SessionStart hook — all documented, ordinary flows,
not edge cases) `$0` is `$TARGET_ROOT/scripts/…` and NEITHER cascade position resolves, because no
`copy_engine_lib()`-style pose step was ever added for `runtime-cli-dispatch.sh` (unlike
`vf-portable.sh`, the one prior precedent of an `_internal`-owned file needed by posed callers,
which DOES have a dedicated copy function). The whole capability silently degrades to
claude-frozen behavior forever, outside a narrow first-install window — exactly the "régression
silencieuse" its own comments disclaim.

**Why:** "cascade EXACTE de X" is a claim about the RESOLUTION CODE, not about the CALLER'S
LIFECYCLE. Two callers can run byte-identical resolution logic and still diverge completely if one
is the engine (whose `$0` never moves) and the other is a module script (whose `$0` is a copy that
gets relocated to `$TARGET_ROOT/scripts/` and re-invoked long after the cache is gone). No existing
test caught this: `test-runtime-cli-dispatch.sh` only exercises the dispatch script from its own
source location; `test-vibeflow-update.sh` never simulates a POSED caller re-invoking it.

**How to apply:** when a diff introduces a shared script under `_internal/` (or any file the
authors say is "resolved by the same cascade as an existing one"), don't trust the comment —
identify who actually calls it and grep/trace what `$0` is for THAT caller at each real lifecycle
stage (fresh install vs. later re-invocation vs. SessionStart hook). If the caller is itself a
POSED file (lives under a module's `scripts/`), the shared file needs its OWN explicit pose step
(precedent: `copy_engine_lib()` for `vf-portable.sh`) — a cascade comment alone is not evidence.
Reproducing with the repo's own test fixture pattern (`prepare_module` + a real install, then a
raw invocation from the posed location with `VIBEFLOW_CACHE` unset) turned this from a suspicion
into a confirmed, demonstrated gap in under 10 commands.
