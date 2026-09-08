# Installing outside Claude Code

<!-- vf-manual:lang -->
[Français](../../fr/01-demarrer/autres-runtimes.md) · **English**
<!-- /vf-manual:lang -->

VibeFlow started as a Claude Code plugin, but it is no longer limited to it: install and usage
have been **measured end to end** on **Codex** and on **kimi-code**. This page states exactly what
was proven on each runtime, with which commands, and **what gets lost** — because portability that
hides its losses isn't portability, it's a promise.

## What is proven, runtime by runtime

| Runtime | Install channel | What was observed |
|---|---|---|
| **Claude Code** | `claude plugin` | Reference runtime: the full surface, governance hooks included. |
| **Codex** | `codex plugin` (native) | Real install **and** real usage: a manager → worker delegation produced code. |
| **kimi-code** | *none* — per-file loading | A VibeFlow agent loaded via `--agent-file` produced code **and** its typed report. |
| **OpenCode, others** | not measured | The engine guesses nothing: it prints the **manual step** to take and exits cleanly. |

Two practical consequences before going further.

**Runtime detection is a cascade, and the first one found wins** — in the order `claude`, `codex`,
`opencode`, then kimi-code (probed separately, by capability, because its binary is called `kimi`
and another product shares that name). On a machine that **also** has Claude Code installed, the
engine will therefore pick Claude Code. To force a target, set the `VF_RUNTIME` environment
variable:

```bash
VF_RUNTIME=codex …
```

Without it, you measure a Claude install while believing you are measuring Codex — that's pitfall
number one on this page.

**Hooks are not ported to any runtime other than Claude Code.** VibeFlow writes its governance
hooks into `settings.json`, which the other runtimes do not execute. The fidelity gate **tells
you** so at install time and at status time (`[fidelity-coexistence]`) rather than letting you
believe the protections are running. Everything else — agents, skills, on-disk planning — works.

## Codex

Two commands, the same logic as under Claude Code (mind the verb: it's `add`, not `install`):

```bash
codex plugin marketplace add picmakpro/vibeflow-os
codex plugin add vibeflow@vibeflow-os
```

Then launch configuration as anywhere else: ask VibeFlow to install itself (`/vibeflow-install`
under Claude Code, the same skill in plain language under Codex). The repository ships a native
Codex manifest alongside the Claude Code one — support is explicit, no longer riding on an
undocumented fallback.

### Three environment preconditions

They are not optional, and two of them fail **silently**:

1. **`multi_agent_v2` must be on.** Without that feature, **no spawn tool exists** on the Codex
   side: the mission team cannot deploy. The engine tries to enable it for you
   (`codex features enable multi_agent_v2`) and reports what it found.
2. **The target repository must be trusted.** Until an interactive `codex` launch inside the
   folder has answered the trust prompt, `.codex/agents/` is **never parsed**: zero VibeFlow roles
   loaded — while `codex doctor` keeps reporting that everything is fine. That trust is a human
   gesture; no VibeFlow script writes it for you.
3. **`VF_RUNTIME=codex`** if `claude` is present on the same machine (see the cascade above).

### What gets lost, stated plainly

- **Governance hooks do not run** (see above). Codex does have its own hook surface, but VibeFlow
  has not targeted it yet — nothing is promised before it ships.
- **Per-role confinement is inert.** `sandbox_mode`, `approval_policy` and `[permissions]`
  declared inside a role file are accepted, then ignored — measured in a real session, a role
  declared read-only actually wrote to disk. A VibeFlow judge is only confined by a **separate
  `codex exec -s read-only` session**, never by its role file.
- **Agent memory is not ported**, and models are **remapped** to Codex models (the Claude names do
  not exist on Codex and would make every spawn fail).

Removal is symmetric: uninstalling a module also removes the Codex roles it had registered.

## kimi-code

kimi-code has **no** install channel: nothing is converted, nothing is registered. Its parser
reads the VibeFlow agent file directly, the one you point it at:

```bash
kimi --agent-file <path>/vf-coder.md
```

Always go through `--agent-file` rather than directory discovery: it is the only form that yields
a complete error message when an agent is rejected, and it bypasses the "first name wins" rule
that can hide an agent silently.

**What survives**: `name`, `description`, `tools`, `disallowedTools` — that last one really does
remove the tool from the toolset, it isn't decorative.

**What is dropped with no diagnostic at all**: `model`, `memory`, `vf-internal`, `effort`,
`skills`, `vf-requires`, `vf-mcp-consumer`, `vf-mcp-tools`. The parser tolerates them and throws
them away.

**The most important consequence of that list**: since `vf-internal` is lost, a worker designed to
be **dispatched only by an orchestrator** becomes directly invocable by you (`kimi --agent
<name>`). The partitioning no longer holds on this target — measured, not inferred. kimi's
`subagents` field restricts dispatch by a parent, never direct invocation: a partial mitigation,
not a fix.

**Next step.** System prerequisites (`bash`, `jq`, `python3`) are the same on every runtime — see
[prerequisites.md](./prerequisites.md). For the reference procedure under Claude Code, see
[installation.md](./installation.md).

<!-- vf-manual:nav -->
[← Previous](../01-get-started/installation.md) · [↑ Contents](../README.md) · [Next →](../01-get-started/choosing-your-scope.md)
<!-- /vf-manual:nav -->
