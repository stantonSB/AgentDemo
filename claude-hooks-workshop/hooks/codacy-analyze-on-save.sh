#!/usr/bin/env bash
# Example hook (PostToolUse): run Codacy static analysis on each edited file and
# surface any findings back to Claude so it can fix them.
# Demonstrates the standard contract: read stdin JSON, extract a field, run a tool,
# report via stderr + exit code (2 = surface stderr to Claude on PostToolUse).
#
# To keep this hook: copy it into ~/.claude/hooks/ and add to ~/.claude/settings.json:
#   "PostToolUse": [ { "matcher": "Edit|Write", "hooks": [
#     { "type": "command", "command": "${HOME}/.claude/hooks/codacy-analyze-on-save.sh" } ] } ]
set -euo pipefail

payload="$(cat)"
file="$(printf '%s' "$payload" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)"

# No file_path (or malformed JSON), or the file no longer exists → nothing to do.
[ -n "$file" ] || exit 0
[ -f "$file" ] || exit 0

# Never hard-block on missing tooling — just hint how to install it and proceed.
if ! command -v codacy-cli >/dev/null 2>&1; then
  printf 'codacy-analyze-on-save: codacy-cli not found; install it to enable analysis (https://github.com/codacy/codacy-cli-v2)\n' >&2
  exit 0
fi

# Linters exit non-zero when they find issues, so tolerate that and keep the SARIF.
sarif="$(codacy-cli analyze --format sarif "$file" 2>/dev/null || true)"

# One readable line per finding: rule, line, message.
findings="$(printf '%s' "$sarif" | jq -r '
  .runs[]?.results[]?
  | "  [\(.ruleId // "?")] line \(.locations[0].physicalLocation.region.startLine // "?"): \(.message.text // "")"
' 2>/dev/null || true)"

# Clean file → say nothing, exit 0.
[ -n "$findings" ] || exit 0

count=0
while IFS= read -r line; do
  [ -n "$line" ] && count=$((count + 1))
done <<EOF
$findings
EOF

# Findings exist → report to stderr and exit 2 so Claude follows up.
printf 'Codacy found %s issue(s) in %s:\n' "$count" "$file" >&2
printf '%s\n' "$findings" >&2
exit 2
