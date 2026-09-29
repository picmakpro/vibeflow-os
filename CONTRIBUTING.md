# Contributing to VibeFlow OS

**English** · Issues and pull requests written in **French are welcome too** — the maintainers
work in French day to day.

Thanks for taking the time to contribute! This guide explains how to propose a change to
VibeFlow OS, the Claude Code plugin marketplace published in this repository.

- [Before you start](#before-you-start)
- [Licensing of contributions](#licensing-of-contributions)
- [Reporting bugs and proposing features](#reporting-bugs-and-proposing-features)
- [Your first pull request](#your-first-pull-request)
- [Running the tests and gates locally](#running-the-tests-and-gates-locally)
- [Conventions](#conventions)
- [What maintainers handle](#what-maintainers-handle)

## Before you start

- **You don't need to be a collaborator.** The repository is public: fork it, push a branch to
  your fork, and open a pull request against `main`.
- **For anything bigger than a small fix, open an issue first.** VibeFlow is governed by
  architecture decision records (`docs/ADR.md`) — a change that contradicts one needs a
  discussion before code.
- Please read and follow our [Code of Conduct](./CODE_OF_CONDUCT.md).
- **Security issues must not be reported in public issues** — see [SECURITY.md](./SECURITY.md).

## Licensing of contributions

VibeFlow OS is **source-available under a proprietary license** (see [LICENSE](./LICENSE)), not
open source. To keep the project distributable, every contribution comes with the following
terms. By submitting a pull request, you agree that:

1. **You have the right to submit it.** The contribution is your original work, or you have
   the right to submit it under these terms, as described by the
   [Developer Certificate of Origin 1.1](https://developercertificate.org/).
2. **You grant a license to the repository owner.** You grant picmakpro (the repository owner) a
   perpetual, worldwide, non-exclusive, royalty-free, irrevocable license to use, reproduce,
   modify, sublicense and distribute your contribution as part of VibeFlow, under the project's
   license or any future license.
3. **You keep your copyright.** This is a license grant, not a transfer of ownership.

Certify point 1 by signing off each commit (`git commit -s`), which adds a trailer:

```
Signed-off-by: Your Name <your.email@example.com>
```

Third-party content (code, prompts, skills) must come with its license and be compatible with
redistribution — say so explicitly in the pull request.

## Reporting bugs and proposing features

Use the [issue templates](https://github.com/picmakpro/vibeflow-os/issues/new/choose). A good
bug report includes:

- the VibeFlow version (`VERSION` file, or the version shown by `/vf-update`);
- the runtime and its version (Claude Code, Codex, kimi-code) and the OS (macOS, Linux, Windows
  with Git Bash);
- the installed modules and the install scope (user / project);
- the exact command, the observed output, and what you expected.

## Your first pull request

1. **Fork** the repository and clone your fork.
2. **Create a branch** from `main` with a descriptive name: `fix/<topic>`, `feat/<topic>`,
   `docs/<topic>`.
3. **Make a focused change.** One pull request = one intent. Unrelated cleanups go in separate
   pull requests.
4. **Run the tests and gates** that cover what you touched (see below).
5. **Push to your fork** and open a pull request against `main`. Fill in the template.
6. **CI must be green.** Every pull request runs the four CI jobs (test suites, quality gates,
   fresh-lab install, armed fresh-lab install). A maintainer reviews, may ask for changes, and
   merges.

## Running the tests and gates locally

Requirements: `bash`, `git`, `jq`, `python3`. The engine-dependent checks also need Node.js 24+
and `@opengsd/gsd-core` (the CI installs it with `npm install -g @opengsd/gsd-core@^1`).

Run every test suite, exactly as the CI discovers them:

```bash
find plugin scripts -type f -path '*/tests/test-*.sh' | sort | while read -r t; do
  bash "$t" || echo "FAIL $t"
done
```

The quality gates most contributions hit:

```bash
bash scripts/check-version-sync.sh            # VERSION ↔ plugin.json ↔ marketplace ↔ READMEs
bash scripts/check-machine-paths.sh           # no absolute machine path in tracked files
bash plugin/conductor/scripts/check-agents.sh --strict --agents-dir=plugin/<module>/agents
```

The complete, authoritative list is the `gates` job in
[`.github/workflows/ci.yml`](./.github/workflows/ci.yml) — when in doubt, replay its commands
rather than any summary.

## Conventions

- **Module anatomy.** Each module under `plugin/<module>/` has its own `VERSION`,
  `module.json`, `CHANGELOG.md` and `README.md`. If you change a module's behavior, add a
  `CHANGELOG.md` entry for it.
- **Agents.** Every agent needs a frontmatter with `description`, `model` and `memory`
  (checked by `check-agents.sh`). Agent files warn from 251 lines and are blocked above 300;
  skills stay under 500 lines (ADR-029).
- **Gates and hooks.** A commit that modifies a gate, its test suite, `.github/workflows/ci.yml`
  or a hook must carry a trailer explaining why:
  ```
  Gate-Touche: <path-or-pattern> — <reason>
  ```
- **Proof over claims.** A new check must be shown able to fail: include a test that turns it
  red on a bad input, not only green on a good one.
- **Commit messages.** The history is in French (`type(scope): description`, e.g.
  `fix(conductor): …`). English is accepted from external contributors; maintainers may reword
  on merge.
- **Portability.** Scripts must run on macOS (BSD tools), Linux (GNU tools) and Windows Git Bash.
  Avoid GNU-only flags and absolute paths.

## What maintainers handle

- **Releases.** Do not bump `VERSION`, `plugin.json`, `marketplace.json` or the README badges
  in your pull request — releases, tags and GitHub releases are cut by the maintainers.
- **Protected paths.** Changes to `.github/`, `scripts/hooks/` and the instruction budget
  baseline require a review by [@picmakpro](https://github.com/picmakpro) (see
  [CODEOWNERS](./.github/CODEOWNERS)).

## Maintainers

- [@picmakpro](https://github.com/picmakpro) — creator and repository owner
- [@samuel-neveugall](https://github.com/samuel-neveugall) — main contributor and release driver
