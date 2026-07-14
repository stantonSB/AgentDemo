# Pre-baked plans (time-saver fallback)

Ideally you brainstorm and decompose `../EPIC.md` yourself — that's the skill this workshop
practises. But if the session is running tight on time, these ready-made plans let you skip
straight to the implementation part.

Each plan is **self-contained**, following the structure from the talk: the files the task owns,
the behaviour spec, acceptance criteria, and the tests to run — everything a fresh session needs,
because a new worktree session has zero context from this one.

## How to use

Open one terminal per hook, start a fresh session in each:

```bash
claude --worktree
```

Then paste the **kickoff prompt** from the bottom of the plan you're assigning. That's it —
the agent reads the plan, implements the hook, and iterates until the test suite passes.

| Plan | Hook | Event |
|------|------|-------|
| [format-on-save.md](format-on-save.md) | `hooks/format-on-save.sh` | `PostToolUse` (Edit\|Write) |
| [codacy-analyze-on-save.md](codacy-analyze-on-save.md) | `hooks/codacy-analyze-on-save.sh` | `PostToolUse` (Edit\|Write) |
| [worktree-session-primer.md](worktree-session-primer.md) | `hooks/worktree-session-primer.sh` | `SessionStart` |

The plans own disjoint files, so all three can run in parallel and merge cleanly.
