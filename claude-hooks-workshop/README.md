# Claude Hooks Workshop

Practise building several Claude Code hooks in parallel git worktrees, then copy the ones you like
into your own `~/.claude`.

## Flow

1. Read `EPIC.md` — three hook specs (`format-on-save`, `codacy-analyze-on-save`,
   `worktree-session-primer`) plus a worked example (`hooks/tool-logger.sh`).
2. Brainstorm + write a short plan per hook.
3. `claude --worktree` once per hook — build each in its own worktree, in parallel.
4. Test locally (`bash test/run-tests.sh`).
5. Keep the ones you like: copy `hooks/<name>.sh` into `~/.claude/hooks/` and paste its
   `settings.json` snippet (no merge to `main` required, no installer).

## Prerequisites

See `../docs/setup-hooks-workshop.md`. In short: `jq`, `codacy-cli` (for hook 2), Claude Code
v2.1.32+.

## Layout

```
claude-hooks-workshop/
  EPIC.md            # the three hook specs (+ stretch ideas)
  CLAUDE.md          # the hook-authoring contract + how to keep a hook
  samples/           # messy.js + .codacy config to exercise the format/codacy hooks
  hooks/             # your finished self-contained hooks (tool-logger.sh is the worked example)
  test/              # run-tests.sh, payloads/, assertion helpers
```
