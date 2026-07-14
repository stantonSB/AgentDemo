# Plan: worktree-session-primer

Give every new Claude session instant situational awareness: which branch it's on, whether it's
in a worktree, how dirty the tree is — and fix the classic missing-`.env` worktree gotcha.

## Files this task owns

- `hooks/worktree-session-primer.sh` (new)
- `test/test_worktree_session_primer.sh` (new)

Touch nothing else. `hooks/tool-logger.sh` and `test/test_tool_logger.sh` are the worked
example — copy their shape, don't modify them.

## Spec

**Event / matcher:** `SessionStart`, `""` (all sessions).

**Behaviour:** read `cwd` from the JSON payload on stdin, then:
1. Determine whether `cwd` is inside a `.claude/worktrees/<name>` path (string match on the
   path is fine; the main repo root is the part before `/.claude/worktrees/`).
2. Gather the current branch (`git -C "$cwd" rev-parse --abbrev-ref HEAD`) and a short
   dirty-state summary (e.g. count of `git -C "$cwd" status --porcelain` lines).
3. If running in a worktree and a `.env` exists at the main repo root but not in the worktree,
   copy it in.

**Output contract:** emit JSON on stdout —
`{"hookSpecificOutput":{"additionalContext":"..."}}` — where the context names the branch,
worktree-vs-main status, and dirty-state summary; exit `0`. Outside a git repo, emit minimal
context and still exit `0`. Never let a git error break session start.

## Implementation steps

1. Create `hooks/worktree-session-primer.sh`, self-contained, `tool-logger.sh` pattern —
   tolerate malformed JSON and non-git dirs (`... 2>/dev/null || true` everywhere it matters).
2. Header-comment settings snippet:
   ```json
   "SessionStart": [ { "matcher": "", "hooks": [
     { "type": "command", "command": "${HOME}/.claude/hooks/worktree-session-primer.sh" } ] } ]
   ```
3. Build the context string, then emit the JSON with `jq -n --arg` so it's always valid JSON.
4. Like `tool-logger`'s `CLAUDE_TOOL_LOG`, keep the hook testable: everything is derived from
   the payload `cwd`, so tests control behaviour by pointing `cwd` at a directory they set up.

## Tests (`test/test_worktree_session_primer.sh`)

The committed payload's `cwd` is a placeholder with no git history, so build the world you need
in a `mktemp -d` (with `trap` cleanup) and generate payloads inline with `printf`/`jq -n`:

1. **Worktree case:** create a throwaway git repo (`git init`, one commit, a branch), fake the
   layout by creating `<repo>/.claude/worktrees/<name>` as a real worktree
   (`git worktree add`) — or simply a nested `git init` checkout on a branch — and point the
   payload `cwd` there. Assert stdout JSON has `additionalContext` naming the branch and
   stating it's a worktree (not `main`), and exit `0`.
2. **`.env` copy:** put `.env` at the repo root, none in the worktree → after the hook runs,
   the worktree has `.env`. Also assert an existing worktree `.env` is not overwritten.
3. **Outside a git repo:** payload `cwd` pointing at a plain temp dir → exit `0`, minimal
   context, no error output.
4. Also fine to reuse `test/payloads/sessionstart-worktree.json` as a smoke test — it must
   exit `0` and emit valid JSON even though its `cwd` doesn't exist.

## Definition of done

- [ ] All acceptance tests above pass via `bash test/run-tests.sh` (run from
      `claude-hooks-workshop/`), with the existing `tool_logger` test still green.
- [ ] The hook is a single self-contained file with its settings snippet in the header.
- [ ] Output is always valid JSON on stdout with exit `0` — in a worktree, on main, and
      outside git entirely.

## Kickoff prompt

```text
cd into claude-hooks-workshop/ and read plans/worktree-session-primer.md. Implement it
exactly: create hooks/worktree-session-primer.sh and test/test_worktree_session_primer.sh,
copying the pattern of hooks/tool-logger.sh and test/test_tool_logger.sh. Don't modify
any other files. Run `bash test/run-tests.sh` from claude-hooks-workshop/ and iterate
until every test passes before reporting done. Show me the final test output.
```
