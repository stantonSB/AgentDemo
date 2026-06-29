#!/usr/bin/env bash
# test_tool_logger.sh — tests for the worked-example PreToolUse hook
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
. "$ROOT/test/lib/assert.sh"

tmp="$(mktemp -d)"
export CLAUDE_TOOL_LOG="$tmp/usage.log"

# Appends the tool name to the log and exits 0
out="$(cat "$ROOT/test/payloads/pretooluse-bash.json" | "$ROOT/hooks/tool-logger.sh"; echo "rc=$?")"
assert_contains "$out" "rc=0" "tool-logger exits 0"
assert_file_exists "$CLAUDE_TOOL_LOG" "log file is created"
assert_contains "$(cat "$CLAUDE_TOOL_LOG")" "Bash" "log line contains the tool name"

# A second invocation appends rather than truncates
cat "$ROOT/test/payloads/pretooluse-bash.json" | "$ROOT/hooks/tool-logger.sh" >/dev/null
lines="$(wc -l < "$CLAUDE_TOOL_LOG" | tr -d ' ')"
assert_eq "2" "$lines" "second invocation appends a line"

rm -rf "$tmp"
echo "PASS: tool_logger"
