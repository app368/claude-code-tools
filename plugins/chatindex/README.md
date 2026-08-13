# ChatIndex

Closing out a working session, without losing what happened in it.

## The problem

At the end of a long session you ask for a summary, and you get one written from memory.
Memory drops things. In the session this came out of, an index written that way was missing
two entire topics — a bug investigation and an agreed piece of follow-up work. Both had
taken real time; neither made the list.

There is a second problem underneath. "Summarize the session" quietly bundles four
different jobs, and they pull in different directions: what was discussed, why things were
chosen, what the thing now is, and what should change in how you work next time.

## The fix

The plugin does two things.

**It dumps the human's turns from the session log.** Every topic that came up is on the
list, in order, with the interface noise stripped out. The index still gets written by
hand — turns record what was said, not what was done — but nothing goes missing.

**It keeps the four products apart**, each with its own rule for what belongs in it:

| Product | Question | Nature |
|---|---|---|
| Session index | what was discussed | freezes with the session |
| Decisions | why this and not that | made once |
| Process file | what came out of it | lives and gets rewritten |
| Rules queue | what should change in how we work | drains over time |

The index includes everything, even what was later dropped — it is a finding aid. The
process file remembers only the final state. Confusing the two produces documents that
are half history and half description, useful for neither.

## Install

```
/plugin marketplace add app368/claude-code-tools
/plugin install chatindex@claude-code-tools
```

## Use

Ask to wrap up, summarize, or close the session. The skill fires and walks the steps.

The dumper can also be run on its own from a project directory:

```
replies.py --list          # which sessions exist
replies.py --session ID    # a specific one
replies.py --full          # complete text of each turn
```

## Notes

- Reads the local session log under `~/.claude/projects/`. Nothing leaves the machine.
- The log format is internal to Claude Code and can change between versions.
- Housekeeping turns are flagged by keyword; the word list is at the top of `replies.py`
  and is meant to be edited for your own habits and language.

## License

MIT
