# Your first lab

<!-- vf-manual:lang -->
[Français](../../fr/01-demarrer/premier-lab.md) · **English**
<!-- /vf-manual:lang -->

This page walks through creating a **lab** from start to finish — the central word in VibeFlow,
one you'll see everywhere. A lab is the workspace VibeFlow builds tailored to a given field: its
memory, its agents, its guardrails. By the end of this page, you'll have created your own and
seen what it contains.

## A concrete case: Karim, independent fitness coach

To keep the example concrete, let's follow a modest, human case rather than an abstract technical
demo. Karim is an independent fitness coach: he follows about fifteen clients remotely (training
programs, progress tracking, follow-ups), and occasionally posts tips on social media. He's never
used VibeFlow before and wants a simple lab to get started, not a heavyweight machine.

### Starting the creation

Karim types, in natural language (see [your-first-session.md](./your-first-session.md) if you want a
reminder of why that's the right entry point):

```
I want a lab to track my fitness coaching clients
```

VibeFlow detects this is a lab creation and offers a choice: a full path (in-depth scoping,
several capabilities) or an **express mode** — an operational lab in under 15 minutes, only 3
questions, everything else derived and clearly marked as such. Since Karim is discovering the
tool and just wants to see it work, he picks express. Nothing stops him from coming back later to
revisit any derived point and dig deeper — express mode is an assumed starting point, not a
ceiling.

## The three questions, and plausible answers

**1. "What field is this lab for?"**
Karim answers: *"Remote fitness coaching — tracking training programs and progress for about
fifteen clients."*

**2. "Its goal, in one sentence?"**
Karim answers: *"Keep a clear view of where each client stands, and never forget anything between
two sessions."*

**3. "The 1 to 3 things it needs to know how to do first?"**
Karim answers: *"Track a client's progress over several weeks, and remind me of key points before
each session."*

Three questions, no more — that's the whole point of express mode. Everything else (the field's
vocabulary, constraints, definition of success) is **derived** from these three answers, and
explicitly marked as a derivation rather than presented as a certainty. That's an important
nuance: a derived answer isn't a randomly guessed one, it's a reasonable consequence of the three
answers Karim gave himself.

## What got created

**While Karim waits.** VibeFlow builds the lab in the background: a `CLAUDE.md` file summarizing
Karim's field and his working rules, one or two agents specialized in client tracking and session
preparation, a working memory to capitalize on what works from one client to the next. Karim can
start talking to his lab while the build finishes — he isn't sitting idle.

**The final summary.** At the end, an honest summary lists: the 3 answers the lab was built on,
each section that was derived rather than confirmed (with exactly what was derived), and how to
refine it later if a derived point turns out to be wrong in practice.

**What Karim ends up with, in brief.** Without going into technical detail (a dedicated page
later in the manual breaks down the full anatomy of a lab installed on disk), keep in mind he
gets:

- a folder holding his lab's **constitution** (the working rules, in one short page);
- one or more specialized **agents**, ready to be talked to in natural language;
- a **memory** that starts empty but will fill up: every structuring decision, every pattern
  observed across several clients, every friction point becomes an entry you can find again
  later, rather than something you have to remember yourself.

This is **not** an empty skeleton: Karim can immediately say "help me prepare [client]'s session"
and get an answer grounded in what was just built.

**What's next.** Karim's lab is intentionally minimal — that's the whole point of express mode.
Nothing stops it from growing later: asking the same question again with more detail lets you
bring the lab up to a fuller version, one capability at a time. That's the subject of pages that
come later in the manual, once you have a lab of your own up and running.

**Your turn.** If you want to reproduce this example for real rather than just reading about it,
type the same kind of sentence Karim did, adapted to your own field — swap "fitness coaching" for
whatever you actually do. Pick express mode if you want to see a result quickly; pick the full
path if you'd rather have deeper scoping from the start. Both paths lead to the same kind of lab —
only the depth of the initial clarification changes.

There's no wrong answer to the three express questions: the more concrete and precise your
answers are, the closer the derived capabilities will land to what you actually need — but even
rough answers produce a usable lab, since everything derived stays editable afterward. The only
real risk is never giving it a try.

Karim could just as well have answered in a shorter or longer sentence: what matters is that the
answer comes from him, not that it follows some precise format.

<!-- vf-manual:nav -->
[← Previous](../01-get-started/your-first-session.md) · [↑ Contents](../README.md) · [Next →](../01-get-started/updating-and-uninstalling.md)
<!-- /vf-manual:nav -->
