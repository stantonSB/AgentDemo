# Repo Doctor (TypeScript)

Workshop repo for the AI Parallel Workflows workshop. Build health analyzers using parallel Claude Code sessions with git worktrees.

## Prerequisites

- Bun (v1.0+)
- Claude Code (v2.1.32+)
- Git

## Quick Start

```bash
git clone <repo-url>
cd repo-doctor-ts
bun install
bun run doctor test-fixtures/unhealthy-repo/
```

## Workshop Instructions

1. Read `EPIC.md` for the full list of analyzers to implement
2. Open multiple terminal tabs
3. In each tab, run `claude --worktree` and assign it an analyzer from the epic
4. Monitor progress, review completed work
5. Merge worktree branches back to main
6. Run `bun run doctor test-fixtures/unhealthy-repo/ --output report.html`
7. Open `report.html` and admire your work
