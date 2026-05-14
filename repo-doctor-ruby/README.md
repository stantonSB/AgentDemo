# Repo Doctor (Ruby)

Workshop repo for the AI Parallel Workflows workshop. Build health analyzers using parallel Claude Code sessions with git worktrees.

## Prerequisites

- Ruby 3.2+
- Bundler
- Claude Code (v2.1.32+)
- Git

## Quick Start

```bash
git clone <repo-url>
cd repo-doctor-ruby
bundle install
bundle exec bin/repo-doctor test-fixtures/unhealthy-repo-ruby/
```

## Workshop Instructions

1. Read `EPIC.md` for the full list of analyzers to implement
2. Open multiple terminal tabs
3. In each tab, run `claude --worktree` and assign it an analyzer from the epic
4. Monitor progress, review completed work
5. Merge worktree branches back to main
6. Run `bundle exec bin/repo-doctor test-fixtures/unhealthy-repo-ruby/ --output report.html`
7. Open `report.html` and admire your work
