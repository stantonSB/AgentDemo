#!/usr/bin/env bash
# test_worktree_session_primer.sh — tests for the SessionStart worktree-primer hook
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
. "$ROOT/test/lib/assert.sh"

HOOK="$ROOT/hooks/worktree-session-primer.sh"

tmp="$(mktemp -d)"
trap 'git -C "$tmp/repo" worktree prune 2>/dev/null || true; rm -rf "$tmp"' EXIT

# Build the world the hook inspects: a throwaway repo with one commit, plus a real worktree
# under <repo>/.claude/worktrees/<name> on its own branch.
repo="$tmp/repo"
mkdir -p "$repo"
git -C "$repo" init -q 2>/dev/null
git -C "$repo" config user.email test@example.com
git -C "$repo" config user.name "Test"
printf 'hello\n' > "$repo/README.md"
git -C "$repo" add README.md
git -C "$repo" commit -qm "initial" 2>/dev/null
wt="$repo/.claude/worktrees/feature-x"
mkdir -p "$repo/.claude/worktrees"
git -C "$repo" worktree add -q -b feature-branch "$wt" 2>/dev/null

# Payload whose cwd points at the worktree.
payload="$(jq -n --arg cwd "$wt" '{hook_event_name:"SessionStart", source:"startup", cwd:$cwd}')"

# Worktree case: exits 0, valid JSON, context names the branch and says it's a worktree (not main)
out="$(printf '%s' "$payload" | "$HOOK")"; rc=$?
assert_eq "0" "$rc" "primer exits 0 in a worktree"
ctx="$(printf '%s' "$out" | jq -r '.hookSpecificOutput.additionalContext' 2>/dev/null)"
assert_contains "$ctx" "feature-branch" "context names the current branch"
assert_contains "$ctx" "worktree" "context states it is a worktree"

# .env copy: repo root has .env, worktree has none → hook copies it in
printf 'SECRET=abc\n' > "$repo/.env"
assert_eq "no" "$([ -f "$wt/.env" ] && echo yes || echo no)" ".env absent in worktree before hook"
printf '%s' "$payload" | "$HOOK" >/dev/null
assert_file_exists "$wt/.env" ".env is copied into the worktree"
assert_contains "$(cat "$wt/.env")" "SECRET=abc" "copied .env has the main repo contents"

# An existing worktree .env is not overwritten
printf 'LOCAL=override\n' > "$wt/.env"
printf '%s' "$payload" | "$HOOK" >/dev/null
assert_contains "$(cat "$wt/.env")" "LOCAL=override" "existing worktree .env is not overwritten"

# Outside a git repo: exits 0, minimal context, no error output
plain="$tmp/plain"
mkdir -p "$plain"
payload_plain="$(jq -n --arg cwd "$plain" '{hook_event_name:"SessionStart", cwd:$cwd}')"
out="$(printf '%s' "$payload_plain" | "$HOOK" 2>"$tmp/err")"; rc=$?
assert_eq "0" "$rc" "primer exits 0 outside a git repo"
ctx="$(printf '%s' "$out" | jq -r '.hookSpecificOutput.additionalContext' 2>/dev/null)"
assert_contains "$ctx" "not inside a git repository" "minimal context outside git"
assert_eq "" "$(cat "$tmp/err")" "no error output outside git"

# Smoke test: the committed payload's cwd does not exist, but the hook must still exit 0 with valid JSON
out="$(cat "$ROOT/test/payloads/sessionstart-worktree.json" | "$HOOK")"; rc=$?
assert_eq "0" "$rc" "primer exits 0 on the committed worktree payload"
printf '%s' "$out" | jq -e . >/dev/null 2>&1; assert_eq "0" "$?" "primer emits valid JSON on the committed payload"

echo "PASS: worktree_session_primer"
