#!/usr/bin/env bash
# test_worktree_session_primer.sh — tests for the SessionStart worktree-primer hook
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
. "$ROOT/test/lib/assert.sh"

HOOK="$ROOT/hooks/worktree-session-primer.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# Build a throwaway repo with one commit and a worktree under .claude/worktrees/<name>, so the
# hook sees exactly the layout it detects. Everything is driven by the payload's cwd.
make_repo() { # <repo-dir>
  local repo="$1"
  mkdir -p "$repo"
  git -C "$repo" init -q
  git -C "$repo" config user.email test@example.com
  git -C "$repo" config user.name "Test Runner"
  printf 'hello\n' > "$repo/README.md"
  git -C "$repo" add -A
  git -C "$repo" commit -qm "init"
}

payload_for() { # <cwd> -> SessionStart payload JSON on stdout
  jq -n --arg cwd "$1" '{hook_event_name:"SessionStart",source:"startup",cwd:$cwd}'
}

# --- 1. Worktree case: branch is named, context says worktree, exit 0 ---------------------
repo="$tmp/repo1"
make_repo "$repo"
wt="$repo/.claude/worktrees/clever-fox-123"
git -C "$repo" worktree add -q -b feature/demo "$wt"

payload_for "$wt" | "$HOOK" >"$tmp/wt.json" 2>"$tmp/wt.err"; rc=$?
assert_eq "0" "$rc" "worktree case exits 0"
assert_eq "" "$(cat "$tmp/wt.err")" "worktree case writes nothing to stderr"
jq -e . <"$tmp/wt.json" >/dev/null 2>&1 || { echo "FAIL: worktree case emits invalid JSON" >&2; exit 1; }
wt_ctx="$(jq -r '.hookSpecificOutput.additionalContext' <"$tmp/wt.json" 2>/dev/null || true)"
assert_contains "$wt_ctx" "feature/demo" "context names the branch"
assert_contains "$wt_ctx" "worktree" "context states it is a worktree"

# --- 2b. Main-checkout case: context says main checkout, exit 0 (DoD: "on main") ----------
payload_for "$repo" | "$HOOK" >"$tmp/main.json" 2>/dev/null; rc=$?
assert_eq "0" "$rc" "main checkout exits 0"
main_ctx="$(jq -r '.hookSpecificOutput.additionalContext' <"$tmp/main.json" 2>/dev/null || true)"
assert_contains "$main_ctx" "main checkout" "context states it is the main checkout"

# --- 2. .env copy: seeded when missing, never overwritten when present --------------------
repo2="$tmp/repo2"
make_repo "$repo2"
wt2="$repo2/.claude/worktrees/tidy-owl-456"
git -C "$repo2" worktree add -q -b feature/env "$wt2"

printf 'SECRET=1\n' > "$repo2/.env"   # .env at the main repo root, none in the worktree yet
[ -f "$wt2/.env" ] && { echo "FAIL: worktree unexpectedly already has .env" >&2; exit 1; }
payload_for "$wt2" | "$HOOK" >/dev/null 2>&1
assert_file_exists "$wt2/.env" ".env is seeded into the worktree"
assert_contains "$(cat "$wt2/.env")" "SECRET=1" "seeded .env matches the main repo root"

printf 'ROOT=2\n' > "$repo2/.env"     # change the root .env; the worktree already has its own
printf 'KEEP=me\n' > "$wt2/.env"
payload_for "$wt2" | "$HOOK" >/dev/null 2>&1
assert_contains "$(cat "$wt2/.env")" "KEEP=me" "existing worktree .env is not overwritten"

# --- 3. Outside a git repo: exit 0, minimal valid context, no error output ----------------
plain="$tmp/plain"
mkdir -p "$plain"
payload_for "$plain" | "$HOOK" >"$tmp/plain.json" 2>"$tmp/plain.err"; rc=$?
assert_eq "0" "$rc" "outside-git case exits 0"
assert_eq "" "$(cat "$tmp/plain.err")" "outside-git case writes nothing to stderr"
jq -e . <"$tmp/plain.json" >/dev/null 2>&1 || { echo "FAIL: outside-git case emits invalid JSON" >&2; exit 1; }
plain_ctx="$(jq -r '.hookSpecificOutput.additionalContext' <"$tmp/plain.json" 2>/dev/null || true)"
assert_contains "$plain_ctx" "Not inside a git repository" "outside-git context is minimal"

# --- 4. Smoke test: committed payload whose cwd does not exist still exits 0 + valid JSON --
"$HOOK" <"$ROOT/test/payloads/sessionstart-worktree.json" >"$tmp/smoke.json" 2>/dev/null; rc=$?
assert_eq "0" "$rc" "committed smoke payload exits 0"
jq -e . <"$tmp/smoke.json" >/dev/null 2>&1 || { echo "FAIL: smoke payload emits invalid JSON" >&2; exit 1; }

# --- 5. Malformed JSON still exits 0 (hook must not hard-fail on a bad payload) ------------
out="$(printf '%s' '{not json' | "$HOOK"; echo "rc=$?")"
assert_contains "$out" "rc=0" "worktree-session-primer exits 0 on malformed JSON"

echo "PASS: worktree_session_primer"
