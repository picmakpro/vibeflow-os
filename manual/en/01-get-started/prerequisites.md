# Prerequisites

<!-- vf-manual:lang -->
[Français](../../fr/01-demarrer/prerequis.md) · **English**
<!-- /vf-manual:lang -->

Before installing VibeFlow, check that your machine has the following four things. Nothing
exotic: these are common tools, and the installer checks them itself the first time you run it.

## What you need

### 1. Claude Code, up to date

VibeFlow is a **Claude Code plugin** — it doesn't work without it. You need Claude Code installed
and recent enough that the `claude plugin` command exists. If you type `claude plugin` in a
terminal and the command isn't recognized, update Claude Code before continuing: this is the most
common cause of installation issues (a dedicated troubleshooting guide for these blockers will
round out this theme).

### 2. Three command-line tools

VibeFlow relies on shell and Python scripts to work (the **engine**, which installs and updates
modules). You need:

- **`bash`**, version 3.2 or newer. macOS and Linux already have this by default.
- **`jq`**, a tool that reads and transforms JSON on the command line, version 1.6 or newer.
- **`python3`**, version 3.8 or newer.

`awk`, `grep`, and `sed` are also used, but they ship with any standard Unix or Linux install —
you normally don't need to do anything about them.

### Check what you already have

Before trying to install anything, look at what your system already has: open a terminal and
type `bash --version`, `jq --version`, `python3 --version`. Each of these three commands prints a
version number if the tool is present, or a "command not found" error otherwise. That's exactly
what preflight does for you — but if you'd rather verify it yourself before running anything,
these three commands are all you need.

### 3. A terminal that can run bash

On macOS and Linux, your usual terminal works fine. On Windows, see the dedicated section below:
it's the only case that requires an extra install step.

### 4. No special access required

You don't need any private account, any manual repository clone, or any `gh` (the GitHub
command-line tool) authentication. Installation happens entirely through the `claude plugin`
commands — see [installation.md](./installation.md).

## The Windows case

If you're on Windows, read this section in full: it's the only system that needs one extra step
before VibeFlow can run.

**Git Bash is required.** Claude Code runs VibeFlow's shell scripts through bash — on Windows,
that means you need **Git for Windows** installed (it bundles Git Bash). Without it, the engine's
scripts simply cannot run.

**`jq` isn't included by default on Windows.** Install it with:

```bash
winget install jqlang.jq
```

**For Python, don't use the Microsoft Store shortcut.** The `python3` shortcut offered by the
Microsoft Store is **not** a real Python interpreter — it just opens the Store page. Install
Python from [python.org](https://www.python.org) and check the **"Add to PATH"** option during
setup, otherwise the `python3` command won't be found in your terminal.

**The CRLF trap.** Windows terminates text lines differently from macOS and Linux (CRLF instead
of LF), and Windows's native `jq` inherits this in its output. You don't need to do anything
about it: the engine neutralizes this automatically. It's mentioned here only so you know it's
not a bug if you happen to run into a reference to it somewhere.

**Preflight checks it for you.** You don't need to verify all this by hand: the first time you
run `/vibeflow-install` (see [installation.md](./installation.md)), a **preflight** step checks
these prerequisites and shows you the exact command for whatever is missing, adapted to your
operating system.

## What's continuously verified, and what isn't

It's more honest to tell you plainly what's tested automatically on every project change, rather
than letting you guess.

**Verified by continuous integration (CI)**: the engine's behavior is tested automatically on
**macOS**, **Debian**, and **Ubuntu** on every change to the repository. If you're on one of
these systems, you benefit from that coverage directly.

**Not verified by CI, but functional**: **Windows** (via Git Bash) is **not** covered by this
automatic continuous integration. That doesn't mean it doesn't work — the Windows substance above
(Git Bash, `jq`, Python, CRLF) is documented precisely because it was identified and handled in
the engine. But if you run into unexpected behavior on Windows, know that you're on a path that
gets automatically retested less often than macOS or Linux — don't hesitate to document precisely
what you observe if you open a report.

**Other Linux distributions** (Fedora, Arch, etc.): not explicitly tested by CI either, but
there's no known technical reason to expect different behavior from Debian or Ubuntu, since the
engine only relies on `bash`, `jq`, `python3`, and standard POSIX utilities.

**Next step.** Once these prerequisites are in place (or if you'd rather just let preflight tell
you what's missing), move on to [installation.md](./installation.md) for the two commands that
set up the plugin.

<!-- vf-manual:nav -->
[↑ Contents](../README.md) · [Next →](../01-get-started/installation.md)
<!-- /vf-manual:nav -->
