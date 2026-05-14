# TypeScript Track — Setup Guide

## Prerequisites

- **Bun** v1.0+ — [Install Bun](https://bun.sh)
- **Git** 2.15+
- **Claude Code** v2.1.32+ — [Install Claude Code](https://docs.anthropic.com/en/docs/claude-code)

## Installation

```bash
# Clone the repo (if you haven't already)
git clone <repo-url>
cd repo-doctor-ts

# Install dependencies
bun install
```

## Verify It Works

Run the included sample analyzer against the test fixture repo:

```bash
bun run doctor test-fixtures/unhealthy-repo/
```

You should see output like:

```
Running 1 analyzer(s) against test-fixtures/unhealthy-repo/...

  Running: file-count...
  file-count: score 90/100 (1 findings)

--- Results ---

file-count: 90/100
  [info] . — Repository contains 8 files
```

## Running Tests

```bash
bun test
```

## CLI Usage

```bash
# Run all analyzers (terminal output)
bun run doctor <repo-path>

# Generate an HTML report
bun run doctor <repo-path> --output report.html

# Run a single analyzer by name
bun run doctor <repo-path> --analyzer <name>
```

## Adding a New Analyzer

1. Create a file in `src/analyzers/` (e.g., `my-analyzer.ts`)
2. Export a class extending `BaseAnalyzer` from `./base`
3. Implement `name`, `description`, and `run(repoPath: string)`
4. The CLI auto-discovers it — no registration needed

```typescript
import { BaseAnalyzer } from "./base";
import type { Finding } from "../types";

export class MyAnalyzer extends BaseAnalyzer {
  name = "my-analyzer";
  description = "Checks something useful";

  async run(repoPath: string) {
    const findings: Finding[] = [];
    // ... analyze the repo ...
    const score = 85;
    return this.result(findings, score);
  }
}
```

Naming conventions:
- Files: `kebab-case.ts` (e.g., `dead-code.ts`, `todo-debt.ts`)
- One analyzer per file
- File name should match the analyzer's `name` property

## Workshop Flow

1. Open the analyzer epic: `cat EPIC.md`
2. Open multiple terminal tabs
3. In each tab, from the `repo-doctor-ts/` directory, run:
   ```bash
   claude --worktree
   ```
4. Assign each session an analyzer (e.g., "Implement the dead-code analyzer from EPIC.md")
5. Monitor progress across terminals
6. When a worktree branch is ready, merge it:
   ```bash
   git merge <worktree-branch>
   ```
7. Run the full suite and generate a report:
   ```bash
   bun run doctor test-fixtures/unhealthy-repo/ --output report.html
   ```
8. Open `report.html` in your browser

## Project Layout

```
repo-doctor-ts/
├── package.json
├── tsconfig.json
├── EPIC.md                 # Full list of analyzers to build
├── CLAUDE.md               # Claude Code context for this project
├── src/
│   ├── cli.ts              # Entry point, arg parsing, orchestration
│   ├── types.ts            # Analyzer, Finding, AnalyzerResult interfaces
│   ├── analyzers/
│   │   ├── base.ts         # BaseAnalyzer abstract class
│   │   └── file-count.ts   # Sample analyzer (reference implementation)
│   └── renderer/
│       ├── html.ts         # HTML report generator
│       └── template.html   # Report template
├── test/                   # Tests mirror src/ structure
└── test-fixtures/
    └── unhealthy-repo/     # Sample repo with known issues for testing
```
