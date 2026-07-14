#!/usr/bin/env bash
# test_codacy_analyze_on_save.sh — tests for the PostToolUse Codacy hook.
# codacy-cli may be missing or slow, so we stub it: a fake codacy-cli that emits
# canned SARIF, on a PATH we control per assertion.
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
. "$ROOT/test/lib/assert.sh"

HOOK="$ROOT/hooks/codacy-analyze-on-save.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# A real file for the hook's file-exists guard to pass; the stub ignores its content.
target="$tmp/messy.js"
printf 'var unused = 1\n' > "$target"
payload="$(printf '{"hook_event_name":"PostToolUse","tool_name":"Edit","tool_input":{"file_path":"%s"}}' "$target")"

# 1) Stub emits SARIF with one finding → hook exits 2 with the rule/message on stderr.
stub1="$tmp/bin1"
mkdir -p "$stub1"
cat > "$stub1/codacy-cli" <<'STUB'
#!/usr/bin/env bash
cat <<'SARIF'
{ "runs": [ { "results": [
  { "ruleId": "no-unused-vars",
    "message": { "text": "'unused' is assigned a value but never used" },
    "locations": [ { "physicalLocation": { "region": { "startLine": 1 } } } ] } ] } ] }
SARIF
STUB
chmod +x "$stub1/codacy-cli"

out="$(printf '%s' "$payload" | PATH="$stub1:$PATH" "$HOOK" 2>&1; echo "rc=$?")"
assert_contains "$out" "rc=2" "findings → exit 2"
assert_contains "$out" "no-unused-vars" "stderr contains the rule id"
assert_contains "$out" "never used" "stderr contains the message text"

# 2) Stub emits SARIF with zero results → exit 0 and no output.
stub2="$tmp/bin2"
mkdir -p "$stub2"
cat > "$stub2/codacy-cli" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' '{ "runs": [ { "results": [] } ] }'
STUB
chmod +x "$stub2/codacy-cli"

out="$(printf '%s' "$payload" | PATH="$stub2:$PATH" "$HOOK" 2>&1; echo "rc=$?")"
assert_eq "rc=0" "$out" "clean file → exit 0 with no output"

# 3) PATH without any codacy-cli → exit 0 with the install hint on stderr.
# Minimal PATH (jq + cat only) so codacy-cli is guaranteed absent regardless of host.
minbin="$tmp/minbin"
mkdir -p "$minbin"
ln -s "$(command -v jq)" "$minbin/jq"
ln -s "$(command -v cat)" "$minbin/cat"
out="$(printf '%s' "$payload" | PATH="$minbin" "$(command -v bash)" "$HOOK" 2>&1; echo "rc=$?")"
assert_contains "$out" "rc=0" "missing codacy-cli → exit 0"
assert_contains "$out" "codacy-cli not found" "stderr contains the install hint"

# 4) Malformed JSON on stdin → exit 0 (hook must not hard-fail on a bad payload).
out="$(printf '%s' '{not json' | "$HOOK" 2>&1; echo "rc=$?")"
assert_contains "$out" "rc=0" "malformed JSON → exit 0"

echo "PASS: codacy_analyze_on_save"
