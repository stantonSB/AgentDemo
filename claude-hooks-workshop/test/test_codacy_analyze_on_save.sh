#!/usr/bin/env bash
# test_codacy_analyze_on_save.sh — tests for the codacy-analyze-on-save PostToolUse hook.
# codacy-cli may be missing or slow, so the suite is made deterministic with a stub codacy-cli
# that emits canned SARIF on a mktemp PATH.
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
. "$ROOT/test/lib/assert.sh"

HOOK="$ROOT/hooks/codacy-analyze-on-save.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# A real file for the hook's existence guard to accept (the stub ignores its contents).
target="$tmp/target.js"
printf 'var unused = 1\n' > "$target"

stubdir="$tmp/bin"
mkdir -p "$stubdir"

# make_stub <sarif-json> — write an executable codacy-cli that prints the given SARIF verbatim.
make_stub() {
  cat > "$stubdir/codacy-cli" <<EOF
#!/usr/bin/env bash
cat <<'SARIF'
$1
SARIF
EOF
  chmod +x "$stubdir/codacy-cli"
}

payload() { # <file_path> — emit a PostToolUse Edit payload for the given path
  jq -n --arg f "$1" '{hook_event_name:"PostToolUse",tool_name:"Edit",tool_input:{file_path:$f}}'
}

# 1) SARIF with one finding -> exit 2 with rule + message on stderr
make_stub '{"runs":[{"results":[{"ruleId":"ESLint_no-unused-vars","message":{"text":"'"'"'unused'"'"' is assigned a value but never used."},"locations":[{"physicalLocation":{"artifactLocation":{"uri":"target.js"},"region":{"startLine":1}}}]}]}]}'
out="$(payload "$target" | PATH="$stubdir:$PATH" "$HOOK" 2>&1; echo "rc=$?")"
assert_contains "$out" "rc=2" "one finding exits 2"
assert_contains "$out" "ESLint_no-unused-vars" "stderr names the rule"
assert_contains "$out" "never used" "stderr carries the message"
assert_contains "$out" "line 1" "stderr carries the line number"

# 2) SARIF with zero results -> exit 0, nothing printed
make_stub '{"runs":[{"results":[]}]}'
out="$(payload "$target" | PATH="$stubdir:$PATH" "$HOOK" 2>&1; echo "rc=$?")"
assert_eq "rc=0" "$out" "clean file exits 0 with no output"

# 3) codacy-cli absent from PATH -> exit 0 with an install hint
out="$(payload "$target" | PATH="/usr/bin:/bin" "$HOOK" 2>&1; echo "rc=$?")"
assert_contains "$out" "rc=0" "missing codacy-cli exits 0"
assert_contains "$out" "codacy-cli not found" "missing codacy-cli prints a hint"

# 4) Malformed JSON on stdin -> exit 0, nothing printed
out="$(printf '%s' '{not json' | PATH="$stubdir:$PATH" "$HOOK" 2>&1; echo "rc=$?")"
assert_eq "rc=0" "$out" "malformed JSON exits 0 with no output"

# 5) Missing file_path -> exit 0
out="$(printf '%s' '{"hook_event_name":"PostToolUse","tool_input":{}}' | PATH="$stubdir:$PATH" "$HOOK" 2>&1; echo "rc=$?")"
assert_eq "rc=0" "$out" "missing file_path exits 0 with no output"

echo "PASS: codacy_analyze_on_save"
