#!/usr/bin/env bash
# Example hook (SessionStart): prime a new session with git situational awareness — which
# branch it's on, whether it's a worktree or the main checkout, and how dirty the tree is —
# and fix the classic missing-.env worktree gotcha by seeding .env from the main repo root.
# Everything is derived from the payload's `cwd`, so it stays testable and side-effect-light.
#
# To keep this hook: copy it into ~/.claude/hooks/ and add to ~/.claude/settings.json:
#   "SessionStart": [ { "matcher": "", "hooks": [
#     { "type": "command", "command": "${HOME}/.claude/hooks/worktree-session-primer.sh" } ] } ]
set -euo pipefail

payload="$(cat)"
cwd="$(printf '%s' "$payload" | jq -r '.cwd // empty' 2>/dev/null || true)"
[ -n "$cwd" ] || cwd="$PWD"

# 1. Worktree detection by path string match. The main repo root is the part before the
#    /.claude/worktrees/ marker; anything else is treated as a plain checkout.
is_worktree=0
main_root=""
case "$cwd" in
  */.claude/worktrees/*)
    is_worktree=1
    main_root="${cwd%%/.claude/worktrees/*}"
    ;;
esac

# 2. Current branch + dirty-state summary. A git error (bad cwd, not a repo) must never break
#    session start, so tolerate failure everywhere and fall back to "not a git repo".
in_git="$(git -C "$cwd" rev-parse --is-inside-work-tree 2>/dev/null || true)"
branch=""
dirty="0"
if [ "$in_git" = "true" ]; then
  branch="$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
  dirty="$(git -C "$cwd" status --porcelain 2>/dev/null | wc -l | tr -d ' ' || true)"
fi

# 3. Worktree .env gotcha: if this is a worktree and the main repo root has a .env that the
#    worktree lacks, copy it in. Never overwrite an existing worktree .env.
env_note=""
if [ "$is_worktree" -eq 1 ] && [ -n "$main_root" ] \
   && [ -f "$main_root/.env" ] && [ ! -f "$cwd/.env" ]; then
  if cp "$main_root/.env" "$cwd/.env" 2>/dev/null; then
    env_note=" Seeded .env from the main repo root into this worktree."
  fi
fi

# Build the situational-awareness context string.
if [ -n "$branch" ]; then
  if [ "$is_worktree" -eq 1 ]; then
    location="a git worktree (main repo at ${main_root})"
  else
    location="the main checkout"
  fi
  context="On branch '${branch}' in ${location}. ${dirty} uncommitted change(s).${env_note}"
else
  context="Not inside a git repository (cwd: ${cwd}).${env_note}"
fi

# Emit valid JSON on stdout no matter what, and always exit 0 so session start never breaks.
out="$(jq -n --arg ctx "$context" \
  '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $ctx}}' \
  2>/dev/null || true)"
[ -n "$out" ] || out='{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"session started"}}'
printf '%s\n' "$out"

exit 0
