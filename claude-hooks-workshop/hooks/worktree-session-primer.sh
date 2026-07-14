#!/usr/bin/env bash
# Example hook (SessionStart): give a new session instant situational awareness — branch,
# worktree-vs-main, dirty-state — and fix the missing-.env worktree gotcha by copying the
# main repo's .env into a fresh worktree.
# Demonstrates the SessionStart contract: read stdin JSON, derive context from cwd, emit
# {"hookSpecificOutput":{"additionalContext":"..."}} on stdout, exit 0. Never break start.
#
# To keep this hook: copy it into ~/.claude/hooks/ and add to ~/.claude/settings.json:
#   "SessionStart": [ { "matcher": "", "hooks": [
#     { "type": "command", "command": "${HOME}/.claude/hooks/worktree-session-primer.sh" } ] } ]
set -euo pipefail

payload="$(cat)"
cwd="$(printf '%s' "$payload" | jq -r '.cwd // empty' 2>/dev/null || true)"

# Is cwd inside a .claude/worktrees/<name> path? The main repo root is the part before it.
is_worktree=0
main_root=""
wt_name=""
case "$cwd" in
  */.claude/worktrees/*)
    is_worktree=1
    main_root="${cwd%%/.claude/worktrees/*}"
    wt_name="${cwd##*/.claude/worktrees/}"
    wt_name="${wt_name%%/*}"
    ;;
esac

# Fix the classic worktree gotcha: a fresh worktree is missing the untracked .env.
env_note=""
if [ "$is_worktree" = "1" ] && [ -n "$main_root" ] \
   && [ -f "$main_root/.env" ] && [ ! -f "$cwd/.env" ]; then
  if cp "$main_root/.env" "$cwd/.env" 2>/dev/null; then
    env_note=" Copied .env from the main repo root into this worktree."
  fi
fi

# Gather git state defensively — a git error must never break session start.
in_git="$(git -C "$cwd" rev-parse --is-inside-work-tree 2>/dev/null || true)"

if [ "$in_git" = "true" ]; then
  branch="$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
  dirty="$( { git -C "$cwd" status --porcelain 2>/dev/null || true; } | grep -c '' || true)"
  if [ "$is_worktree" = "1" ]; then
    location="worktree '${wt_name}' (main repo at ${main_root})"
  else
    location="main checkout"
  fi
  context="Session primer — branch: ${branch:-unknown}; location: ${location}; working tree: ${dirty} uncommitted change(s).${env_note}"
else
  context="Session primer — not inside a git repository (${cwd:-unknown cwd})."
fi

jq -n --arg ctx "$context" '{hookSpecificOutput:{additionalContext:$ctx}}'

exit 0
