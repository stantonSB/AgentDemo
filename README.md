# Worktrees, Agents & Hooks — Workshop

A hands-on workshop on parallel Claude Code workflows. You'll learn git worktrees and agent
patterns, then practise building **three useful Claude Code hooks in parallel worktrees** and copy
the ones you like into your own `~/.claude`.

## Contents

| Path | What |
|------|------|
| `workshop-slides/index.html` | The slide deck (presenter) |
| `workshop-slides/speaker.html` | Same deck with always-visible speaker notes |
| `claude-hooks-workshop/` | The hands-on scaffold — build three hooks in parallel |
| `docs/setup-hooks-workshop.md` | Prerequisites & one-time setup |

## How the hands-on works

1. Read `claude-hooks-workshop/EPIC.md` — three hook specs + a worked example.
2. `claude --worktree` once per hook — build each in its own worktree, in parallel.
3. Test each hook locally.
4. Keep the ones you like by copying them into `~/.claude` (no merge or installer required).

## Prerequisites

- [Claude Code](https://code.claude.com/docs) v2.1.32+
- Git 2.15+ (worktree support)
- `jq`, and `codacy-cli` for the Codacy hook — see `docs/setup-hooks-workshop.md`.
