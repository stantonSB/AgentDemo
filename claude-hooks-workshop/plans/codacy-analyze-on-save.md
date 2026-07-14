# Plan: codacy-analyze-on-save

Run Codacy static analysis on every file Claude edits, and surface findings back to Claude so it
can fix them.

## Files this task owns

- `hooks/codacy-analyze-on-save.sh` (new)
- `test/test_codacy_analyze_on_save.sh` (new)

Touch nothing else. `hooks/tool-logger.sh` and `test/test_tool_logger.sh` are the worked
example — copy their shape, don't modify them.

## Spec

**Event / matcher:** `PostToolUse`, `Edit|Write`.

**Behaviour:** read `tool_input.file_path` from the JSON payload on stdin; run
`codacy-cli analyze --format sarif <file>` on that single file; parse the SARIF output for
findings on that file.

**Output contract:**
- Findings exist → print them as readable one-per-line entries (rule, line, message) to
  **stderr** and exit `2`. On `PostToolUse`, exit `2` surfaces stderr to Claude so it follows up.
- Clean file → exit `0`, no output.
- `codacy-cli` not installed → print a one-line install hint to stderr and exit `0` — never
  hard-block on missing tooling.
- Empty/missing `file_path` or malformed JSON → exit `0`.

## Implementation steps

1. Create `hooks/codacy-analyze-on-save.sh`, self-contained, `tool-logger.sh` pattern
   (`set -euo pipefail`, `payload="$(cat)"`, `jq -r '... // empty' 2>/dev/null || true`).
2. Header-comment settings snippet:
   ```json
   "PostToolUse": [ { "matcher": "Edit|Write", "hooks": [
     { "type": "command", "command": "${HOME}/.claude/hooks/codacy-analyze-on-save.sh" } ] } ]
   ```
3. Guard clauses: no `file_path` / file missing → exit `0`; `command -v codacy-cli` fails →
   hint + exit `0`.
4. Capture the SARIF, extract findings with jq — roughly
   `.runs[]?.results[]?` → rule id, `locations[0].physicalLocation.region.startLine`, and
   `message.text` — count them, print to stderr, and pick the exit code (`2` if count > 0).
5. Payload note: committed payloads use a placeholder `cwd` with a repo-relative `file_path`.
   Use `file_path` as given and run from the `claude-hooks-workshop` root.

## Tests (`test/test_codacy_analyze_on_save.sh`)

Real `codacy-cli` may be missing or slow in a test run, so make the suite deterministic with a
**stub**: in a `mktemp -d`, write a fake `codacy-cli` script that emits canned SARIF, `chmod +x`
it, and prepend the dir to `PATH` for that assertion.

1. Stub emits SARIF with one finding on the analyzed file → hook exits `2` and stderr contains
   the rule/message.
2. Stub emits SARIF with zero results → exits `0`, no findings printed.
3. `PATH` without any `codacy-cli` → exits `0` and stderr contains the install hint.
4. Malformed JSON on stdin → exits `0`.

## Definition of done

- [ ] All acceptance tests above pass via `bash test/run-tests.sh` (run from
      `claude-hooks-workshop/`), with the existing `tool_logger` test still green.
- [ ] The hook is a single self-contained file with its settings snippet in the header.
- [ ] Sanity check if `codacy-cli` is installed locally: piping
      `test/payloads/posttooluse-edit.json` against the lint-flagged `samples/messy.js`
      exits `2` with findings on stderr.

## Kickoff prompt

```text
cd into claude-hooks-workshop/ and read plans/codacy-analyze-on-save.md. Implement it
exactly: create hooks/codacy-analyze-on-save.sh and test/test_codacy_analyze_on_save.sh,
copying the pattern of hooks/tool-logger.sh and test/test_tool_logger.sh. Don't modify
any other files. Run `bash test/run-tests.sh` from claude-hooks-workshop/ and iterate
until every test passes before reporting done. Show me the final test output.
```
