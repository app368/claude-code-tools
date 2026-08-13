---
name: chatindex
description: Closing out a session — dumps the human's turns from the session log, then uses them to write the session index, record decisions, update the process file, and collect new working rules. Use when the user asks to wrap up, summarize, or close a session.
---

# ChatIndex

Closing out a session is four separate jobs, and mixing them up costs you.

| Product | Question it answers | Where it goes | Nature |
|---|---|---|---|
| **Session index** | what was discussed | last message of the session | freezes with the session |
| **Decisions** | why this and not that | your decisions folder | made once |
| **Process file** | what came out of it | your process/spec file | lives and gets rewritten |
| **Rules queue** | what should change in how we work | a queue file, e.g. `PROTOOLS.md` | drains over time |

The first looks back and lists everything, including what was later dropped. The second
explains the choice. The third describes the present and remembers nothing extra.
The fourth looks forward.

**Do only what was asked.** The user may want the index alone — then leave the rest alone.
None of the four is mandatory: a session may produce no new process and no decisions.

**Order matters** in one place: record decisions before rewriting the process file,
because the process file links to them.

## Step 1 — Dump the turns

From the project directory:

```bash
"${CLAUDE_PLUGIN_ROOT}/replies.py"
```

`--list` for available sessions, `--session ID` for a specific one, `--full` for complete
text, `--project PATH` for another project.

Service records from the interface are dropped automatically; housekeeping turns
("make a commit", "merge the branch") are marked `[hk]`.

**Why bother.** Memory loses topics. In the session this skill came out of, two whole
topics were missing from an index written from memory — a bug investigation and an agreed
piece of follow-up work. Both turned up in a minute of reading the list.

## Step 2 — Session index

Read the list, group turns into topics, write the index. A topic is a run of turns about
one thing, usually three to ten.

- Keep the heading constant — it is a search anchor
- Only what was done: no retelling of discussions, no arguments
- Chronological order
- Phrase it in words someone would search for: screen names, entities, functions
  ("Settings page: theme picker added", not "UI improvements")
- Decisions taken without code: one line, marked as such

**When in doubt, include.** An extra line costs nothing; a missing topic costs a search
through the whole session.

The turn list is insurance against gaps, not the source. The index is written by hand:
turns record what was **said**, the index must record what was **done**. Work carried out
autonomously after "just do all of it" is one turn and ten deeds.

## Step 3 — Decisions

Only decisions **about the product**: architecture, the user's model of it, how it is put
together. Not about documentation or method.

Format is free as long as it is clear: problem, decision, reasoning. Record what was
rejected together with the reason — that part earns its keep, because an unrecorded
rejection has to be re-argued later, and not necessarily to the same conclusion.

A decision is made once. Changed your mind? That is a *new* decision that supersedes the
old one; the old file stays untouched.

## Step 4 — Process file

If the session brought a process to working order, rewrite its file **as the final state**.
Rewrite, not append: intermediate variants are not wanted.

A coarse grouping of the turns by business process gives you the skeleton — the groups
fall into "what it consists of", "how it works", "how it is verified".

**The file belongs to the process, not to the session.** A session edits an existing file;
a new file is only for a new process. Otherwise you end up with two descriptions of the
same thing, and descriptions that have drifted apart are worse than none: you can't tell
which is true.

## Step 5 — Rules queue

Go through the non-topical turns with one question: **will this still matter after the
session closes?**

- **No** — housekeeping approvals: "make a commit", "merge it". They authorize something
  already decided and live three minutes.
- **Yes** — rules stated in passing during those same exchanges: "decide commit points
  yourself as you go".

**When in doubt, add it.** This is a queue of raw material, not a rulebook: sorting happens
later. Filtering at the door means the queue never fills.

| Category | What goes in |
|---|---|
| **Code** | how to write it: comments, idioms, structure, formatting |
| **Git** | branches, commits, merges; what happens automatically and what waits for a word |
| **Communication** | order of dialogue, shape of an answer, what not to say, how to give instructions |
| **Documentation** | what goes where, templates, boundaries between documents |
| **Tools** | anything runnable: scripts, skills, working techniques |
| **Method** | reasoning about software development in general, portable to another project |

**Rules born from friction are not a separate category — friction is how you mine them.**
A rule that grew out of repeated misunderstanding lands in one of the six: "explain what a
command does" is communication. But note the origin: a line that came from three
repetitions of the same failure carries more weight than one proposed from first principles.

One question is chance. Two in a session is a trace. Three is a rule.

**Anything already in the queue doesn't go in again** — it holds only unsorted material.

## Draining the queue is separate work

Not at session close. A sorted line goes where it belongs and leaves the queue; a rejected
one is deleted without recording why — working rules are small, and storing refusals costs
more than re-deciding.

| What | Where |
|---|---|
| General rule, portable to any project | user-level instructions |
| Rule for this project | project-level instructions |
| Observation not yet a rule | memory |
| Reasoning about development in general | your methodology notes |

## What not to do

**Don't compute percentages and shares.** Interesting once, never again: the ratio depends
on what you happened to work on and shifts by itself.

**Don't build the index mechanically from the turns.** The list reflects the conversation;
the index must reflect the result.
