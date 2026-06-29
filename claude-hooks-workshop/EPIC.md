# Hooks Workshop — EPIC

## Overview

Build **three independent Claude Code hooks**, each in its own git worktree (so you practise
working on several in parallel). Test each locally. Then **keep the ones you like** by copying
them into your own `~/.claude` — there is no merge to `main` required and no installer.

Each hook is a **self-contained single file** under `hooks/`. A worked example,
`hooks/tool-logger.sh`, shows the full pattern end-to-end — copy its shape.

> None of these hooks use AI at runtime — they are deterministic shell scripts. The AI angle is
> *how you build them*: several parallel Claude Code sessions in git worktrees.

## The hook contract (see CLAUDE.md for detail)

- A hook receives the event as JSON on **stdin** (`hook_event_name`, `cwd`, `tool_name`,
  `tool_input`, …).
- Control Claude via **exit code** (`0` proceed; `2` block on `PreToolUse` / surface stderr to
  Claude) or **JSON on stdout** (`hookSpecificOutput.additionalContext`,
  `hookSpecificOutput.permissionDecision`).
- Read stdin inline (no shared lib):
  ```bash
  payload="$(cat)"
  file="$(printf '%s' "$payload" | jq -r '.tool_input.file_path // empty')"
  ```
- Test locally: `cat test/payloads/<file>.json | hooks/<name>.sh`.

## How to build (per hook)

1. `claude --worktree` to start a session in a fresh worktree.
2. Implement `hooks/<name>.sh` (self-contained; carry its `settings.json` snippet as a header comment).
3. Add a `test/test_<name>.sh` and make it pass (`bash test/run-tests.sh`).
4. (Optional) merge to `main` — not required.

## How to keep a hook you like

1. Copy `hooks/<name>.sh` into `~/.claude/hooks/` (create the dir if needed).
2. Back up `~/.claude/settings.json`, then paste the hook's header-comment snippet under the right event.

---

## Hook 1: `format-on-save`

**Event / matcher:** `PostToolUse`, `Edit|Write`.

**Behaviour:** read `tool_input.file_path`; if it is a supported type, run the matching formatter
on just that file (e.g. `prettier --write` for `.js`/`.ts`/`.json`/`.md`). For unsupported types
or a missing formatter, no-op.

**Output contract:** always exit `0` (formatting is best-effort and must not block Claude). On a
formatter error, print a short warning to stderr and still exit `0`.

**settings.json snippet:**
```json
"PostToolUse": [ { "matcher": "Edit|Write", "hooks": [
  { "type": "command", "command": "${HOME}/.claude/hooks/format-on-save.sh" } ] } ]
```

**Acceptance criteria:**
- [ ] Piping `test/payloads/posttooluse-edit.json` reformats `samples/messy.js` in place.
- [ ] A payload for an unsupported extension exits `0` and changes nothing.
- [ ] A payload with no `file_path` exits `0` and changes nothing.

---

## Hook 2: `codacy-analyze-on-save`

**Event / matcher:** `PostToolUse`, `Edit|Write`.

**Behaviour:** read `tool_input.file_path`; run `codacy-cli analyze --format sarif <file>` on that
single file; parse the SARIF for findings on that file.

**Output contract:** if findings exist, print them as readable lines to **stderr** and exit `2`
(surfaces them to Claude so it can fix them); if clean, exit `0`. If `codacy-cli` is not
installed, print a one-line hint to stderr and exit `0` (never hard-block on missing tooling).

**settings.json snippet:**
```json
"PostToolUse": [ { "matcher": "Edit|Write", "hooks": [
  { "type": "command", "command": "${HOME}/.claude/hooks/codacy-analyze-on-save.sh" } ] } ]
```

**Acceptance criteria:**
- [ ] Against the lint-flagged `samples/messy.js`, the hook exits `2` with the finding(s) on stderr.
- [ ] A clean file exits `0` with no findings.
- [ ] With `codacy-cli` absent, exits `0` with a hint.

---

## Hook 3: `worktree-session-primer`

**Event / matcher:** `SessionStart`, `""`.

**Behaviour:** determine whether `cwd` is inside a `.claude/worktrees/<name>` path; gather the
current git branch and a short dirty-state summary; if running in a worktree and a `.env` exists
at the main repo root but not in the worktree, copy it in.

**Output contract:** emit JSON on stdout with `hookSpecificOutput.additionalContext` containing the
branch, worktree-vs-main status, and dirty-state summary; exit `0`. Outside a git repo, emit
minimal context and exit `0`.

**settings.json snippet:**
```json
"SessionStart": [ { "matcher": "", "hooks": [
  { "type": "command", "command": "${HOME}/.claude/hooks/worktree-session-primer.sh" } ] } ]
```

**Acceptance criteria:**
- [ ] Piping `test/payloads/sessionstart-worktree.json` returns `additionalContext` naming the
      branch and stating it is a worktree (not `main`).
- [ ] When a root `.env` is present and the worktree lacks one, the `.env` is copied in.
- [ ] Outside a git repo, exits `0` with minimal context and no error.

---

## Optional stretch ideas (not required)

For fast finishers — pick from: secret guard (`PreToolUse` deny), no-commit-to-main guard
(`PreToolUse` deny), done/needs-you notifier (`Notification`/`Stop`), package-install
supply-chain gate (`PreToolUse`), session audit log (`PostToolUse`/`SessionEnd`), PR-hygiene
helper (`Stop`).
