# Claude Hooks Workshop

Build Claude Code hooks in parallel git worktrees, then copy the ones you like into your own
`~/.claude`.

## What a hook is

Claude Code runs a shell command of yours at lifecycle events. A hook can **observe**, **inject
context**, or **block** an action. It receives the event as JSON on stdin and responds via exit
code and/or JSON on stdout.

## The contract

**Stdin** (JSON): includes `hook_event_name`, `cwd`, and for tool events `tool_name` and
`tool_input` (e.g. `tool_input.file_path` for Edit/Write, `tool_input.command` for Bash).

**Control:**
- Exit `0` — proceed.
- Exit `2` — on `PreToolUse`, blocks the tool and shows stderr to Claude; on `PostToolUse`, the
  tool already ran but stderr is surfaced to Claude so it can follow up.
- JSON on stdout — e.g. `{"hookSpecificOutput":{"additionalContext":"..."}}` (add context, used by
  `SessionStart`), or `{"hookSpecificOutput":{"permissionDecision":"deny","permissionDecisionReason":"..."}}`
  (used by `PreToolUse`).

## Self-contained pattern

Each hook is one file with no shared dependency, so a "keeper" copies cleanly into `~/.claude/hooks/`.
Read stdin inline:

```bash
#!/usr/bin/env bash
set -euo pipefail
payload="$(cat)"
file="$(printf '%s' "$payload" | jq -r '.tool_input.file_path // empty')"
```

Requires `jq`.

## Conventions

- One self-contained hook per file in `hooks/`, kebab-case.
- Carry the hook's `settings.json` snippet as a header comment, so it travels with the file.
- Keep hooks fast — they fire on every matching event.
- Hooks run arbitrary commands with your credentials. Review before keeping one.

## Testing

```bash
cat test/payloads/<file>.json | hooks/<name>.sh    # run one hook against a payload
bash test/run-tests.sh                              # run the whole suite
```

## Keeping a hook (manual — no installer)

1. Copy `hooks/<name>.sh` into `~/.claude/hooks/` (create the dir if needed).
2. Back up `~/.claude/settings.json`, then paste the hook's header-comment snippet under the
   right event (merge it into any existing array for that event).
