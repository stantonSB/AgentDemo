#!/usr/bin/env bash
# codacy-analyze-on-save (PostToolUse): run Codacy static analysis on the file Claude just
# edited and surface any findings back to Claude so it can fix them.
#
# Contract:
#   - Findings exist -> print them (rule, line, message) to stderr and exit 2. On PostToolUse,
#     exit 2 surfaces stderr to Claude so it follows up.
#   - Clean file -> exit 0, no output.
#   - codacy-cli not installed -> one-line install hint on stderr, exit 0 (never hard-block).
#   - Empty/missing file_path, missing file, or malformed JSON -> exit 0.
#
# To keep this hook: copy it into ~/.claude/hooks/ and add to ~/.claude/settings.json
# (merge into any existing PostToolUse array — do not add a second PostToolUse key):
#   "PostToolUse": [ { "matcher": "Edit|Write", "hooks": [
#     { "type": "command", "command": "${HOME}/.claude/hooks/codacy-analyze-on-save.sh" } ] } ]
set -euo pipefail

payload="$(cat)"
file="$(printf '%s' "$payload" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)"

# No file to analyze, or it no longer exists — nothing to do.
[ -n "$file" ] || exit 0
[ -f "$file" ] || exit 0

# Missing tooling is not a hard failure — hint once and move on.
if ! command -v codacy-cli >/dev/null 2>&1; then
  printf 'codacy-analyze-on-save: codacy-cli not found; install it to enable analyze-on-save (https://github.com/codacy/codacy-cli-v2).\n' >&2
  exit 0
fi

# Analyze just this file and pull findings out of the SARIF report. Any error from codacy-cli
# or jq degrades to "no findings" rather than blocking Claude.
sarif="$(codacy-cli analyze --format sarif "$file" 2>/dev/null || true)"
findings="$(printf '%s' "$sarif" | jq -r '
  .runs[]?.results[]?
  | "  [\(.ruleId // "unknown")] line \(.locations[0].physicalLocation.region.startLine // "?"): \(.message.text // "")"
' 2>/dev/null || true)"

if [ -n "$findings" ]; then
  count="$(printf '%s\n' "$findings" | grep -c .)"
  printf 'Codacy found %s issue(s) in %s:\n' "$count" "$file" >&2
  printf '%s\n' "$findings" >&2
  exit 2
fi

exit 0
