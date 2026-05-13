# AI Workshop: Parallel Workflows, Worktrees & Agent Teams

**Date**: 2026-05-13
**Duration**: 2.5 hours (45 min slides/demo + 1h45 hands-on)
**Audience**: Developers familiar with Claude Code and skills, new to parallel workflows
**Format**: Solo work, progressive reveal approach

---

## Part 1: Slideshow & Demo (45 min)

Demo tool: Agent Orchestrator

### Act 1 — "The Problem" (5 min)

Open with a relatable scenario: "You have 8 features to build. You open Claude Code. You do them one at a time. It takes all day."

Show a simple timeline diagram: sequential vs parallel execution of the same tasks.

Hook: "What if you could run 5 agents at once, each in its own isolated branch, and merge them all?"

### Act 2 — "Worktrees: The Foundation" (10 min)

Explain git worktrees — what they are, why they matter for agents. Each worktree is an isolated branch with its own working directory. No conflicts between agents because they're working on separate copies of the codebase.

Live demo in Agent Orchestrator:
- Create a session with `--worktree`
- Show it gets its own branch and directory
- Show the `.claude/worktrees/` directory structure
- Emphasise: this is just git — nothing magical, no special tooling required

### Act 3 — "Parallel Workflows" (15 min)

Live demo in Agent Orchestrator with a real repo:
- Spin up 3-4 sessions simultaneously, each given a different task
- Show the status indicators: Working, Idle, Finished
- Show the worktree branches in git: all independent, all mergeable
- Demonstrate merging one back into main

Key teaching moment: "The tasks must be independent. If feature B depends on feature A's output, they can't run in parallel."

Cover the practical workflow:
1. Decompose work into independent tasks
2. Create a worktree per task
3. Assign each task to an agent
4. Monitor progress
5. Review and merge

### Act 4 — "Agent Teams & When to Use What" (10 min)

Introduce agent teams as the next level: instead of manually managing parallel sessions, Claude Code coordinates a team lead + teammates with a shared task list and inter-agent messaging.

**Architecture:**
- Team lead creates the team, spawns teammates
- Each teammate gets its own context window
- Communication via mailboxes and shared task list
- Teammates can message each other directly (unlike subagents which only report back)

**Subagents vs Agent Teams:**

| | Subagents | Agent Teams |
|---|---|---|
| Context | Own window; results return to caller | Own window; fully independent |
| Communication | Report back to main agent only | Teammates message each other directly |
| Coordination | Main agent manages all work | Shared task list with self-coordination |
| Best for | Focused tasks where only the result matters | Complex work requiring discussion and collaboration |
| Token cost | Lower | Higher |

**Honest take from experience:**
- Agent teams are best used to get a plan built quicker — spin up teammates to research, explore, and validate different angles of a problem in parallel so you arrive at a solid plan faster
- For actual implementation, worktrees and parallel sessions are the go-to
- Agent teams struggle with higher-level orchestration across multiple features with dependencies
- They're still experimental: no session resumption with in-process teammates, task status can lag, one team at a time

**Best practices (from official docs):**
- 3-5 teammates
- 5-6 tasks per teammate
- Avoid file conflicts by giving each teammate ownership of different files
- Start with research/review if you're new to agent teams

**For higher-level orchestration**, point people to these frameworks worth exploring outside this session:
- **Gastown** — multi-agent orchestration framework for coordinating feature-level work across repos
- **Citadel** — agent coordination platform with dependency-aware task scheduling
- **Mission Control** — higher-level orchestration layer that manages agent teams across multiple features

**Transition**: "Today in the workshop, you'll use worktrees and parallel sessions to implement features independently. That's the foundation. Agent teams build on top of that — try them once you're comfortable with the parallel workflow."

### Buffer / Q&A (5 min)

---

## Part 2: Hands-On Workshop — Repo Doctor (1h45)

### The Project

A CLI tool called `repo-doctor` that analyzes any git repository and produces a beautiful standalone HTML report card with scores, findings, and recommendations.

```
repo-doctor /path/to/any/repo --output report.html
```

### Skeleton Repo

Two language versions provided: TypeScript (bun/yarn) and Ruby (bundler).

**Pre-built by facilitator (included in skeleton):**
- CLI entry point — argument parsing, config loading
- Analyzer plugin interface/base class — each analyzer implements: `name`, `run(repoPath)`, returns `{ findings: Finding[], score: number }`
- HTML report renderer — takes analyzer results, produces a styled HTML page with scores, colour-coded grades, and expandable finding sections
- Sample analyzer — a trivial "file count" analyzer as a reference implementation
- CLAUDE.md — project conventions, file structure, how to add a new analyzer
- EPIC.md — the full epic with all analyzers listed

### Analyzers

**Core (5 — everyone should complete):**

#### 1. Dependency Staleness Checker
- **Reads**: package.json + lock file (TS) / Gemfile + Gemfile.lock (Ruby)
- **Checks**: outdated dependencies, deprecated packages, known vulnerabilities
- **Output**: list of stale/vulnerable deps with severity, score based on % up-to-date
- **Acceptance criteria**: identifies at least outdated deps by comparing locked vs latest; flags any dep not updated in 12+ months

#### 2. Dead Code Detector
- **Reads**: all source files in src/ (or lib/ for Ruby)
- **Checks**: unused exports, unreferenced files, orphaned test files
- **Output**: list of likely-dead files/exports with confidence level, score based on % of codebase that's alive
- **Acceptance criteria**: identifies files that are never imported/required by any other file; flags test files whose subject file doesn't exist

#### 3. TODO/FIXME Debt Tracker
- **Reads**: all source files + git blame data
- **Checks**: TODO, FIXME, HACK, XXX comments
- **Output**: list of debt comments with file, line, age (from git blame), author; score based on volume and staleness
- **Acceptance criteria**: finds all marker comments, enriches with git blame age, sorts by staleness

#### 4. Test Coverage Analyzer
- **Reads**: source and test directories
- **Checks**: test-to-source file ratio, source files with no corresponding test, test files that import nothing
- **Output**: coverage map showing which source files have tests and which don't; score based on % covered
- **Acceptance criteria**: correctly maps test files to source files by naming convention; reports ratio and list of uncovered files

#### 5. Doc Health Checker
- **Reads**: all .md files, package.json scripts / Rakefile tasks
- **Checks**: broken links in markdown, README exists and isn't empty, documented scripts/tasks actually exist
- **Output**: list of broken links, missing docs, phantom scripts; score based on doc completeness
- **Acceptance criteria**: validates all relative links in markdown resolve to real files; checks every script in package.json has a corresponding entry

**Stretch (3 more — for participants who finish early):**

#### 6. Security Scanner
- **Reads**: all files, .gitignore, git history
- **Checks**: hardcoded secrets/API keys (regex patterns), .env files committed, permissive .gitignore missing common entries
- **Output**: list of potential secrets with file + line, missing .gitignore entries; score based on findings severity
- **Acceptance criteria**: catches common patterns (AWS keys, API tokens, passwords in config); flags committed .env files

#### 7. Complexity Analyzer
- **Reads**: all source files
- **Checks**: file sizes (lines), nesting depth, function/method count per file, flags outliers beyond configurable thresholds
- **Output**: ranked list of most complex files with metrics; score based on % of files within healthy thresholds
- **Acceptance criteria**: measures at least line count and function count; identifies top 10 most complex files

#### 8. Git Health Checker
- **Reads**: git log, branches, file sizes in history
- **Checks**: commit frequency, stale branches (no commits in 30+ days), large files in history, leftover merge conflict markers
- **Output**: branch health summary, large file warnings, conflict marker locations; score based on overall git hygiene
- **Acceptance criteria**: identifies stale branches, finds files over 1MB in history, detects `<<<<<<<` markers in current files

### Epic Document (EPIC.md)

For each analyzer, the epic includes:
- Description of what it checks
- Input (which files/data it reads)
- Output shape (`{ findings: Finding[], score: number }`)
- Acceptance criteria
- Parallelisation note: "This analyzer is independent — it can be built in its own worktree alongside any other analyzer"

### Launching Parallel Sessions (the core mechanic)

Participants use vanilla Claude Code with the `--worktree` flag. The concrete workflow:

1. Open a terminal tab, `cd` into the cloned repo
2. Run `claude --worktree` — this creates an isolated worktree with its own branch
3. Give it the task: "Implement the TODO/FIXME Debt Tracker analyzer per EPIC.md"
4. Open another terminal tab, `cd` into the same repo, run `claude --worktree` again
5. Give it a different task: "Implement the Dead Code Detector analyzer per EPIC.md"
6. Repeat for as many analyzers as you want to run in parallel (3-5 recommended)
7. Monitor each tab — when an agent finishes, review its work
8. Merge each worktree branch back into main: `git merge <worktree-branch>`
9. If a merge conflicts (unlikely if analyzers are self-contained), resolve manually or run `claude` on the conflicted files to let the agent help resolve

The EPIC.md and CLAUDE.md in the repo give each agent all the context it needs — no need to repeat project conventions in your prompt.

### Analyzer Registration

Analyzers are auto-discovered: any file in `src/analyzers/` (TS) or `lib/analyzers/` (Ruby) that exports/implements the analyzer interface is automatically picked up by the CLI. No central registry file to edit. This means worktree merges never conflict on a shared import file — each analyzer is a self-contained file that gets discovered at runtime.

### Verification

Each analyzer can be tested individually:

```
repo-doctor /path/to/repo --analyzer todo-debt
```

This runs a single analyzer and outputs its findings to the terminal (no HTML). Participants should verify each analyzer works before merging. The skeleton also includes a sample "patient repo" (`test-fixtures/unhealthy-repo/`) seeded with known issues for every core analyzer: outdated deps, dead code, TODO comments, missing tests, and broken doc links.

### Workshop Flow

| Time | Activity | Detail |
|------|----------|--------|
| 0:00-0:10 | Setup | Clone repo, install deps (`bun install` or `bundle install`), run skeleton to see sample analyzer + HTML report working against `test-fixtures/unhealthy-repo/` |
| 0:10-0:20 | Plan | Read EPIC.md, plan approach, open terminal tabs, launch `claude --worktree` sessions |
| 0:20-1:20 | Build | Implement analyzers — parallel agents running in separate worktrees, one analyzer per worktree. Start harder analyzers first (Dependency Staleness, Dead Code) to give them more wall-clock time |
| 1:20-1:25 | Merge Demo | Facilitator demonstrates merging a worktree branch back to main and running the full report |
| 1:25-1:35 | Participants Merge & Run | Merge worktree branches, run `repo-doctor test-fixtures/unhealthy-repo/ --output report.html`, open the HTML report |
| 1:35-1:45 | Show & Tell | Volunteers show their reports, discuss what worked and what didn't about the parallel workflow |

### Pre-workshop Setup Instructions (sent to participants ahead of time)

Participants must have installed before arriving:
- **Claude Code** (v2.1.32+)
- **Node.js 20+** and **bun** or **yarn** (for TypeScript track)
- **Ruby 3.2+** and **bundler** (for Ruby track)
- **Git** (obviously)
- A terminal they're comfortable with

### What Participants Take Home

- A working `repo-doctor` CLI they can point at any of their own repos
- Hands-on experience with worktrees and parallel agent workflows
- The muscle memory of: decompose, plan, parallelise, merge

---

## Key Design Decisions

1. **Two language tracks (TS + Ruby)**: participants pick their preferred language, reducing friction
2. **Pre-built skeleton**: CLI, plugin interface, and HTML renderer are done — participants focus on the analyzers (the parallelisable work), not plumbing
3. **Independent analyzers**: every analyzer reads from the repo and returns the same shape — zero dependencies between them, perfect for parallel worktrees
4. **Progressive scope**: 5 core + 3 stretch means fast workers aren't bored and slower workers still finish with something complete
5. **HTML report as payoff**: the visual output makes the result tangible and shareable — not just passing tests
6. **CLAUDE.md included**: teaches the pattern of giving agents project context, which reinforces the slides
7. **Agent Orchestrator for demo only**: participants use vanilla Claude Code with `--worktree` so the workshop isn't gated on installing a separate app
8. **Auto-discovery for analyzers**: analyzers are discovered by directory convention, not a central registry — this eliminates merge conflicts when combining worktree branches
9. **Test fixtures included**: a "patient repo" with known issues ships with the skeleton so participants can verify analyzers against predictable data
10. **Single-analyzer mode**: `--analyzer <name>` flag lets participants test one analyzer in isolation before merging

### Skeleton Repo Structure

```
repo-doctor/
  src/                          # (TS track)
    cli.ts                      # Entry point — argument parsing, config
    analyzers/
      base.ts                   # Analyzer interface + types
      file-count.ts             # Sample analyzer (reference implementation)
    renderer/
      html.ts                   # HTML report renderer
      template.html             # Report template
    types.ts                    # Shared types (Finding, AnalyzerResult, etc.)
  lib/                          # (Ruby track — mirrors src/ structure)
    cli.rb
    analyzers/
      base.rb
      file_count.rb
    renderer/
      html.rb
      template.html
  test-fixtures/
    unhealthy-repo/             # Sample repo seeded with known issues (TS)
      package.json              # Outdated deps
      bun.lockb                 # Lock file with pinned old versions
      src/
        dead-module.ts          # Never imported (dead code)
        utils.ts                # Has TODO/FIXME comments
        active-module.ts        # Imported and used
      tests/
        active-module.test.ts   # Exists — covered
                                # utils.test.ts missing — uncovered
      README.md                 # Contains broken links
    unhealthy-repo-ruby/        # Sample repo seeded with known issues (Ruby)
      Gemfile                   # Outdated gems
      Gemfile.lock              # Lock file with pinned old versions
      lib/
        dead_module.rb          # Never required
        utils.rb                # Has TODO/FIXME comments
        active_module.rb        # Required and used
      spec/
        active_module_spec.rb   # Exists — covered
                                # utils_spec.rb missing — uncovered
      README.md                 # Contains broken links
  CLAUDE.md                     # Project conventions for AI agents
  EPIC.md                       # The full epic with all analyzers
  package.json / Gemfile        # Dependencies
```

### CLAUDE.md Outline

The CLAUDE.md included in the skeleton should cover:
- Project purpose and how the CLI works
- Analyzer interface contract (`name`, `run(repoPath)`, return shape)
- How to add a new analyzer (create a file in `src/analyzers/`, implement the interface, it auto-registers)
- File naming convention (`kebab-case.ts` / `snake_case.rb`)
- How to test: `repo-doctor test-fixtures/unhealthy-repo/ --analyzer <name>`
- Code style: no external dependencies for analyzers (use Node/Ruby stdlib + git CLI only)

### Facilitator Notes

**Common failure modes and recovery:**
- **Merge conflicts**: shouldn't happen if analyzers are self-contained files, but if a participant edited shared files (cli.ts, types), help them resolve manually
- **Worktree cleanup**: `git worktree list` to see all worktrees, `git worktree remove <path>` to clean up
- **Agent goes off-track**: participant should interrupt the agent (`Ctrl+C`) and re-prompt with more specific instructions referencing EPIC.md
- **Rate limits**: if a participant hits API rate limits running 5+ agents, reduce to 3 parallel sessions
- **Solution branch**: maintain a `solutions` branch in the skeleton repo that the facilitator can cherry-pick from if a participant is stuck and blocking on merge
