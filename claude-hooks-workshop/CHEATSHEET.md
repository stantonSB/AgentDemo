# Worktrees, Agents & Hooks — Cheat Sheet

**Worktrees isolate. Decomposition parallelises. Hooks guarantee.**

## Commands

| Command | What it does |
| --- | --- |
| `claude --worktree` (or `-w`) | Start a session in a fresh git worktree under `.claude/worktrees/<name>/` |
| `claude agents` | Agent view — every running session on one screen |
| `/hooks` | Browse and configure hooks from inside a session |
| `/statusline` | Have Claude generate a status line (model, session cost, context remaining) |

## The parallel workflow

1. **Decompose** into independent tasks — each task owns its files. If two tasks share a file,
   merge them into one task or run them sequentially.
2. **`claude --worktree` per task**, paste its self-contained prompt. Fresh sessions have zero
   planning context — the prompt must carry everything (context, acceptance criteria, tests to run).
3. **Monitor** with `claude agents`. Give every session a way to verify its own work — tests to
   run, a browser to open, a payload to pipe — and tell it to pass them before reporting done.
4. **Review each branch like a PR**, then merge one at a time.

Sweet spot: 3–5 parallel worktrees — beyond that, your review capacity becomes the bottleneck.

## Decomposition prompt (run in plan mode)

> Interview me about this epic, then break it into tasks that can run in parallel.
> For each task list the files it owns — flag any overlaps.
> Then write a self-contained prompt per task (context, acceptance criteria, tests to run)
> into `plans/task-*.md`.

## The hook contract

- Registered in `settings.json` as **event → matcher → command**.
- **Stdin**: the event as JSON — `hook_event_name`, `cwd`, and for tool events `tool_name` /
  `tool_input` (e.g. `tool_input.file_path` for Edit/Write).
- **Exit codes**: `0` proceed; `2` on `PreToolUse` blocks the tool and shows stderr to Claude;
  `2` on `PostToolUse` — the tool already ran, but stderr is surfaced to Claude so it can follow up.
- **Or JSON on stdout**, e.g. `{"hookSpecificOutput":{"additionalContext":"..."}}`.
- Keep hooks fast and scope matchers tightly — they run with your credentials on every matching event.

## Keeping a workshop hook — two steps (the script alone won't fire)

1. Copy `hooks/<name>.sh` into `~/.claude/hooks/` (create the dir if needed).
2. Back up `~/.claude/settings.json`, then paste the hook's header-comment snippet under the
   right event (merge into any existing array for that event).

## Worktree gotchas

- A worktree is not `main` — `cd` into it before running dev servers.
- `.gitignore`d files (like `.env`) aren't copied into worktrees — copy or symlink them manually.

Hooks docs: https://code.claude.com/docs/en/hooks · Repo: https://github.com/stantonSB/AgentDemo
