# Security Policy

## Supported versions

Only the **latest published release** of VibeFlow OS receives security fixes. Update with
`/vf-update` before reporting, and check whether the issue still reproduces.

| Version        | Supported |
| -------------- | --------- |
| Latest release | ✅        |
| Older releases | ❌        |

## Reporting a vulnerability

**Please do not report security vulnerabilities through public issues, pull requests or
discussions.**

Report them privately through GitHub:
**[Report a vulnerability](https://github.com/picmakpro/vibeflow-os/security/advisories/new)**
(repository → *Security* tab → *Report a vulnerability*).

Please include:

- the affected component (module, hook, script, installer) and the VibeFlow version;
- the runtime (Claude Code, Codex, kimi-code) and the OS;
- the steps to reproduce, and a proof of concept if you have one;
- the impact you observed or expect.

## What to expect

- Acknowledgement within **5 business days**.
- An assessment and, if confirmed, a remediation plan shared through the private advisory.
- A fix published in a new release, with credit to the reporter unless you prefer to remain
  anonymous.

Please give us a reasonable delay to ship a fix before any public disclosure.

## Scope

VibeFlow installs hooks and scripts that run on the user's machine inside AI coding agents.
Of particular interest:

- hooks or scripts that execute unintended commands, or can be steered by content from the
  repository being worked on (prompt or command injection);
- the install and update engine (`plugin/_internal/`) writing outside its intended scope;
- guards that can be bypassed silently while reporting success.

Out of scope: vulnerabilities in Claude Code, Codex, kimi-code or `@opengsd/gsd-core`
themselves — report those to their respective maintainers.
