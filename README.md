# Repo Doctor — AI Parallel Workflows Workshop

A hands-on workshop for building a **repository health checker** using parallel Claude Code sessions with git worktrees. Participants implement independent analyzers concurrently, then merge them into a unified CLI tool that generates HTML health reports.

## Choose Your Track

| Track | Directory | Runtime | Guide |
|-------|-----------|---------|-------|
| TypeScript | `repo-doctor-ts/` | Bun | [Setup Guide](docs/setup-typescript.md) |
| Ruby | `repo-doctor-ruby/` | Ruby + Bundler | [Setup Guide](docs/setup-ruby.md) |

Both tracks produce the same result — a CLI that scans a git repo and outputs a scored health report. Pick whichever language you're most comfortable with.

## How the Workshop Works

1. **Read the epic** — Each track has an `EPIC.md` listing 8 independent analyzers to build
2. **Spin up parallel sessions** — Open multiple terminals and run `claude --worktree` in each
3. **Assign analyzers** — Give each Claude session a different analyzer from the epic
4. **Monitor and review** — Watch progress, review code as branches complete
5. **Merge and run** — Merge worktree branches back to main, run the full tool
6. **View your report** — Open the generated HTML report in a browser

## Project Structure

```
.
├── README.md                  # You are here
├── docs/
│   ├── setup-typescript.md    # TypeScript track setup guide
│   └── setup-ruby.md         # Ruby track setup guide
├── repo-doctor-ts/            # TypeScript track
│   ├── EPIC.md                # Analyzer specifications
│   ├── CLAUDE.md              # Claude Code project context
│   └── src/                   # Source code
├── repo-doctor-ruby/          # Ruby track
│   ├── EPIC.md                # Analyzer specifications
│   ├── CLAUDE.md              # Claude Code project context
│   └── lib/                   # Source code
└── workshop-slides/           # Presentation slides
```

## Prerequisites (All Tracks)

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) v2.1.32+
- Git 2.15+ (worktree support)

Track-specific prerequisites are listed in each setup guide.
