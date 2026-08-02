# Your first session

<!-- vf-manual:lang -->
[Français](../../fr/01-demarrer/premiere-session.md) · **English**
<!-- /vf-manual:lang -->

You've just finished `/vibeflow-install` (see [installation.md](./installation.md)). This page
covers the fifteen minutes that follow: what happens when you open your next Claude Code session,
how you talk to VibeFlow, and what you should see appear to know it's working.

## What happens when the next session opens

Nothing launches automatically. As covered in [installation.md](./installation.md), VibeFlow
never opens on its own — that's intentional. You open Claude Code as usual, in the folder where
you installed VibeFlow (or anywhere, if you chose the account scope), and you start talking.

The only thing that changes compared to before installation: Claude Code now knows about the
agents and commands VibeFlow set up. There's nothing for you to activate.

## How you talk to VibeFlow

This is the single most important thing to understand right away: **you talk in natural
language, not in commands**. Commands exist (`/vibeflow`, `/vf-new-lab`, `/vf-update`...), but
they aren't the main entry point — they're mostly shortcuts for people who already know them. The
real entry point is saying what you want, in your own words.

Concretely, you can type sentences like:
- "help me move forward on this project"
- "create me a lab to organize my content"
- "check that everything's configured correctly"
- "update VibeFlow"

VibeFlow detects the intent behind your sentence and routes to the right action on its own. You
don't need to know in advance which agent or which command does what.

### You don't need to memorize anything

You don't need to know the name of a single agent before getting started — VibeFlow picks the
right agent for your request, not you. If your sentence is imprecise or oddly phrased, that's
fine: VibeFlow asks a clarifying question instead of guessing on your behalf and heading in the
wrong direction. And nothing irreversible happens without you confirming first — actions that
change something (installing, updating, uninstalling) always show you a summary before running.

## A first concrete exchange

Here's a short exchange you can copy exactly for your very first interaction. Type:

```
help me get started
```

What you'll typically see appear: VibeFlow notices you haven't given it a precise task, and asks
you a short question to narrow down what you want to do — for example, if it detects this folder
is a code project, it might offer to help you move it forward; if it detects nothing in
particular, it asks you directly what you're trying to do (create a new lab, check a
configuration, something else).

Just answer its question, in one sentence, the way you'd talk to a colleague. For example, if you
want to see lab creation from start to finish:

```
I want to create a lab to run my content
```

From there, VibeFlow walks you through a short scoping conversation — a few questions to
understand your field and what you want this lab to know how to do — before building anything.
You never have to guess the next step: every VibeFlow reply ends with a question or a clear
proposal of what comes next.

**If you word it awkwardly.** Nothing bad can happen from typing a clumsy or incomplete sentence —
at worst, VibeFlow asks the question again a different way. You can also change your mind
mid-exchange about what you want to do: just say so, something like "actually, never mind, I'd
rather...".

**What not to do right away.** Don't try to memorize the list of commands or read the entire
documentation before getting started: natural language is enough to begin, and you'll pick up
commands as you go if you need them. Also don't fire off several requests in parallel in the same
session while you're still finding your footing — one intent at a time, until the workflow feels
familiar.

Once you've had a taste of this exchange, the logical next step is creating a first complete lab
end to end — that's the subject of the next page in this theme.

### What you don't need to know yet

As you go through this manual, you'll come across words like "lab," "scope," or "registry." You
don't need to master them before talking to VibeFlow: they get defined as you encounter them, and
the first exchange above works perfectly well without them. The most important word for now is
"lab" — the workspace VibeFlow builds for you — and it's explained in detail on the next page,
through use rather than theory.

If a word genuinely trips you up along the way, the simplest way to clear it up is to just ask
VibeFlow directly in your session — that's faster than searching the manual, and the answer will
be tailored to whatever you're doing at the moment you ask. There's no such thing as a beginner
question that wastes anyone's time here.

Take that as permission to stop reading and go try it — the rest of this manual will still be
here afterward.

<!-- vf-manual:nav -->
[← Previous](../01-get-started/choosing-your-scope.md) · [↑ Contents](../README.md) · [Next →](../01-get-started/your-first-lab.md)
<!-- /vf-manual:nav -->
