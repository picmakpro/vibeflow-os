<!--
Thanks for contributing! French or English are both fine.
Please read CONTRIBUTING.md first. For a large change, open an issue before the pull request.
Security fixes: do NOT open a public pull request — see SECURITY.md.
-->

## What & why

<!-- What does this change, and why? Link the issue it closes: "Closes #123". -->

Closes #

## Type of change

- [ ] Bug fix
- [ ] New feature / capability
- [ ] Documentation only
- [ ] Refactoring (no behavior change)
- [ ] Gate, hook or CI change (commit carries a `Gate-Touche:` trailer)

## Affected modules

<!-- e.g. plugin/conductor, plugin/dev-orchestrator, scripts/, docs/ -->

## How was it tested?

<!-- Commands you ran and their result. A new check must also be shown turning red on a bad input. -->

```
$ bash plugin/<module>/tests/test-<name>.sh
```

- Runtime(s) tested: <!-- Claude Code / Codex / kimi-code -->
- OS: <!-- macOS / Linux / Windows Git Bash -->

## Checklist

- [ ] My commits are signed off (`git commit -s`) and I agree to the
      [licensing of contributions](../CONTRIBUTING.md#licensing-of-contributions)
- [ ] The test suites covering my change pass locally
- [ ] I added or updated tests for behavior changes
- [ ] I updated the relevant module `CHANGELOG.md` / `README.md` if behavior changed
- [ ] I did **not** bump `VERSION`, `plugin.json`, `marketplace.json` or README badges
      (releases are cut by the maintainers)
- [ ] No absolute machine paths (`bash scripts/check-machine-paths.sh`)
