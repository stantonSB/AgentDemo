# Plan: format-on-save

Auto-format a file every time Claude edits or writes it.

## Files this task owns

- `hooks/format-on-save.sh` (new)
- `test/test_format_on_save.sh` (new)

Touch nothing else. `hooks/tool-logger.sh` and `test/test_tool_logger.sh` are the worked
example — copy their shape, don't modify them.

## Spec

**Event / matcher:** `PostToolUse`, `Edit|Write`.

**Behaviour:** read `tool_input.file_path` from the JSON payload on stdin. If the file is a
supported type, run the matching formatter on just that file — `prettier --write` for
`.js` / `.ts` / `.json` / `.md`. For unsupported extensions, a missing `file_path`, a missing
file, or a missing formatter binary: no-op.

**Output contract:** always exit `0` — formatting is best-effort and must never block Claude.
If the formatter itself errors, print a short warning to stderr and still exit `0`.

## Implementation steps

1. Create `hooks/format-on-save.sh`, self-contained (no shared lib), starting from the
   `tool-logger.sh` pattern: `set -euo pipefail`, `payload="$(cat)"`, extract fields with
   `jq -r '... // empty' 2>/dev/null || true` so malformed JSON can't hard-fail the hook.
2. Carry the settings snippet as a header comment so it travels with the file:
   ```json
   "PostToolUse": [ { "matcher": "Edit|Write", "hooks": [
     { "type": "command", "command": "${HOME}/.claude/hooks/format-on-save.sh" } ] } ]
   ```
3. Guard clauses first (empty `file_path`, file doesn't exist, `command -v prettier` fails →
   exit `0`), then a `case` on the extension, then run the formatter with failures downgraded
   to a stderr warning.
4. Payload note: committed payloads use a placeholder `cwd` with a repo-relative `file_path`.
   Use `file_path` as given and run from the `claude-hooks-workshop` root (as `run-tests.sh`
   does) — don't resolve it against the payload `cwd`.

## Tests (`test/test_format_on_save.sh`)

Follow `test/test_tool_logger.sh`: source `test/lib/assert.sh`, use a `mktemp -d` + `trap`
cleanup. `samples/messy.js` is deliberately unformatted — back it up to the temp dir first and
restore it after, so the suite stays repeatable.

1. Pipe `test/payloads/posttooluse-edit.json` through the hook → exit `0` and
   `samples/messy.js` is reformatted in place (assert the content changed / now contains
   formatted output like `const x = 1`).
2. A payload for an unsupported extension (build the JSON inline with `printf`) → exit `0`,
   file untouched.
3. A payload with no `file_path` → exit `0`, nothing changes.
4. Malformed JSON on stdin → still exits `0`.

## Definition of done

- [ ] All acceptance tests above pass via `bash test/run-tests.sh` (run from
      `claude-hooks-workshop/`), with the existing `tool_logger` test still green.
- [ ] The hook is a single self-contained file with its settings snippet in the header.

## Kickoff prompt

```text
cd into claude-hooks-workshop/ and read plans/format-on-save.md. Implement it exactly:
create hooks/format-on-save.sh and test/test_format_on_save.sh, copying the pattern of
hooks/tool-logger.sh and test/test_tool_logger.sh. Don't modify any other files.
Run `bash test/run-tests.sh` from claude-hooks-workshop/ and iterate until every test
passes before reporting done. Show me the final test output.
```
