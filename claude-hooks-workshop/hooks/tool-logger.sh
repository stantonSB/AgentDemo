#!/usr/bin/env bash
# Example hook (PreToolUse): append each tool invocation to a log file.
# Demonstrates the standard contract: read stdin JSON, extract a field, side effect, exit 0.
#
# To keep this hook: copy it into ~/.claude/hooks/ and add to ~/.claude/settings.json:
#   "PreToolUse": [ { "matcher": "", "hooks": [
#     { "type": "command", "command": "${HOME}/.claude/hooks/tool-logger.sh" } ] } ]
set -euo pipefail

payload="$(cat)"
tool="$(printf '%s' "$payload" | jq -r '.tool_name // empty' 2>/dev/null || true)"

log="${CLAUDE_TOOL_LOG:-$HOME/.claude/logs/tool-usage.log}"
mkdir -p "$(dirname "$log")"
printf '%s\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${tool:-unknown}" >> "$log"

exit 0
