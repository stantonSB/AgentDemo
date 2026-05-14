# Repo Doctor — Analyzer Epic (TypeScript)

## Overview

### Vision

Repo Doctor is a CLI tool that performs automated health checks on any git repository and produces a scored HTML report. Think of it as a doctor's check-up for your codebase — it examines dependencies, code quality, documentation, security, complexity, and git hygiene, then gives each dimension a score from 0–100 and an overall grade.

> **Note:** None of the analyzers use AI or LLMs at runtime. Every check is deterministic — regex pattern matching, file system traversal, import graph parsing, git commands, and naming convention checks. The AI aspect of this project is in **how it's built** (parallel Claude Code sessions in git worktrees), not in what the tool itself does.

### What We're Building

A single command — `bun run doctor <repo-path>` — that:

1. **Discovers** all analyzers at runtime by globbing `src/analyzers/*.ts`
2. **Runs** each analyzer against the target repository in sequence
3. **Collects** findings (file, line, message, severity) and a 0–100 score from each
4. **Renders** the results as either terminal output or a standalone HTML report with letter grades (A–F)

The tool ships with 8 independent analyzers spanning dependency health, code quality, documentation, security, complexity, and git hygiene. Each analyzer is a self-contained TypeScript class extending `BaseAnalyzer` — no shared state, no cross-dependencies.

### How We Build It

Each analyzer is implemented in its own git worktree using a parallel Claude Code session. This means:

- **No merge conflicts** — each analyzer lives in its own file under `src/analyzers/`
- **No coordination required** — auto-discovery means no central registration
- **Independent testing** — each analyzer has its own test file and can be run in isolation via `--analyzer <name>`
- **Parallel development** — all 8 analyzers can be built simultaneously

### Architecture

```
CLI (src/cli.ts)
  ├── discovers analyzers via glob
  ├── instantiates each analyzer class
  ├── calls run(repoPath) on each
  ├── collects AnalyzerResult[]
  └── passes results to renderer

Analyzer (src/analyzers/*.ts)
  ├── extends BaseAnalyzer
  ├── implements name, description, run()
  ├── returns { analyzer, findings[], score }
  └── uses only stdlib + child_process

Renderer (src/renderer/)
  ├── reads template.html
  ├── calculates letter grades
  └── produces standalone HTML report
```

### Type System

- **Finding** — `{ file, line?, message, severity }` where severity is `"info" | "warning" | "error"`
- **AnalyzerResult** — `{ analyzer, findings[], score }` where score is 0–100
- **Analyzer** — `{ name, description, run(repoPath): Promise<AnalyzerResult> }`

---

## Project-Level Acceptance Criteria

These criteria apply to Repo Doctor as a whole, not to any individual analyzer.

### CLI

- [ ] `bun run doctor <repo-path>` runs all discovered analyzers and prints results to the terminal
- [ ] `bun run doctor <repo-path> --output report.html` generates a standalone HTML report
- [ ] `bun run doctor <repo-path> --analyzer <name>` runs only the named analyzer
- [ ] `bun run doctor --help` prints usage information
- [ ] Exit code is 0 on success, 1 on error
- [ ] Gracefully handles missing or invalid repo paths with a clear error message

### Auto-Discovery

- [ ] Any `.ts` file added to `src/analyzers/` (other than `base.ts`) is automatically picked up — no registration needed
- [ ] Removing an analyzer file cleanly removes it from the output — no errors

### Scoring & Grading

- [ ] Each analyzer returns a score clamped to 0–100
- [ ] The overall score is the average of all analyzer scores
- [ ] Letter grades: A (90–100), B (80–89), C (70–79), D (60–69), F (0–59)

### HTML Report

- [ ] Report is a single self-contained HTML file (no external dependencies)
- [ ] Shows overall score and grade
- [ ] Lists each analyzer with its individual score, grade, and findings
- [ ] Findings are collapsible and show file, line number (if available), severity, and message
- [ ] Includes a timestamp of when the report was generated

### Testing

- [ ] `bun test` passes with no failures
- [ ] Each analyzer has a corresponding test file in `test/analyzers/`
- [ ] Tests run against `test-fixtures/unhealthy-repo/` to validate expected findings
- [ ] Tests verify score ranges, not exact scores (to avoid brittleness)

### End-to-End

- [ ] Running all 8 analyzers against `test-fixtures/unhealthy-repo/` produces a report with all expected issues flagged
- [ ] Running against a healthy repo produces high scores across the board
- [ ] The tool completes within a reasonable time (< 30 seconds for a typical repository)

---

## Core Analyzers

### 1. dependency-staleness

**Name:** `dependency-staleness`
**Description:** Reads package.json and lock file. Checks for outdated or pinned dependencies. Score = percentage of dependencies considered up-to-date.
**Difficulty:** Medium

**What it reads:**
- `package.json` (dependencies, devDependencies)
- `package-lock.json` or `bun.lock` if present

**What it checks:**
- Dependencies pinned to very old major versions
- Dependencies using exact versions vs ranges
- Known deprecated packages (e.g., `moment`, `request`)
- Whether a lock file exists

**Output shape:**
- Finding per outdated/problematic dependency (severity: warning or error)
- Finding for missing lock file (severity: error)
- Score: percentage of deps without issues

**Acceptance criteria:**
- Running against `test-fixtures/unhealthy-repo/` should flag `moment` as deprecated, flag old pinned versions
- Score should be < 100 for the unhealthy repo
- Score should be reasonable (0-100) for any repo with a package.json

**Independence note:** This analyzer is independent — it can be built in its own worktree alongside any other analyzer.

**Code skeleton:**
```typescript
import { BaseAnalyzer } from "./base";
import { readFile } from "fs/promises";
import { join } from "path";
import type { Finding } from "../types";

export class DependencyStalenessAnalyzer extends BaseAnalyzer {
  name = "dependency-staleness";
  description = "Checks for outdated, pinned, or deprecated dependencies";

  private readonly deprecatedPackages = new Set([
    "moment", "request", "querystring", "url", "punycode"
  ]);

  async run(repoPath: string) {
    const findings: Finding[] = [];
    // Read package.json
    // Check each dependency for staleness signals
    // Check for lock file existence
    // Calculate score
    const score = 100; // placeholder
    return this.result(findings, score);
  }
}
```

---

### 2. dead-code

**Name:** `dead-code`
**Description:** Scans all .ts files in src/. Builds an import graph via regex. Flags files that are never imported by any other file. Score = percentage of files that are alive (imported or entry points).
**Difficulty:** Medium-Hard

**What it reads:**
- All `.ts` / `.js` files in `src/` directory recursively

**What it checks:**
- Builds import graph by parsing `import ... from "..."` and `require("...")` statements
- Identifies entry points (files matching common patterns like `index.ts`, `cli.ts`, `main.ts`)
- Flags files that are never imported by any other file and are not entry points

**Output shape:**
- Finding per dead file (severity: warning)
- Score: percentage of source files that are alive

**Acceptance criteria:**
- Running against `test-fixtures/unhealthy-repo/` should flag `dead-module.ts`
- Should NOT flag `index.ts` (entry point) or `active-module.ts` (imported by index)
- `utils.ts` may or may not be flagged depending on whether it's imported

**Independence note:** This analyzer is independent — it can be built in its own worktree alongside any other analyzer.

**Code skeleton:**
```typescript
import { BaseAnalyzer } from "./base";
import { readdir, readFile } from "fs/promises";
import { join, relative, basename } from "path";
import type { Finding } from "../types";

export class DeadCodeAnalyzer extends BaseAnalyzer {
  name = "dead-code";
  description = "Detects source files that are never imported";

  private readonly entryPatterns = ["index", "main", "cli", "server", "app"];

  async run(repoPath: string) {
    const findings: Finding[] = [];
    // Walk src/ to find all .ts/.js files
    // Parse imports from each file
    // Build set of imported files
    // Flag files not in the imported set and not entry points
    const score = 100; // placeholder
    return this.result(findings, score);
  }
}
```

---

### 3. todo-debt

**Name:** `todo-debt`
**Description:** Greps all source files for TODO/FIXME/HACK/XXX comments. Enriches findings with age from git blame. Score = inverse of volume weighted by age.
**Difficulty:** Easy-Medium

**What it reads:**
- All source files (`.ts`, `.js`, `.tsx`, `.jsx`)
- Runs `git blame` on files with matches

**What it checks:**
- Lines containing `TODO`, `FIXME`, `HACK`, or `XXX` (case-insensitive)
- Age of each comment via git blame
- Volume of tech debt comments

**Output shape:**
- Finding per TODO/FIXME/HACK/XXX comment with file, line number, and age (severity: info for recent, warning for old, error for very old)
- Score: starts at 100, loses points per comment (more for older ones)

**Acceptance criteria:**
- Running against `test-fixtures/unhealthy-repo/` should find TODO, FIXME, HACK, and XXX in `utils.ts`
- Findings should include line numbers
- Score should be < 100

**Independence note:** This analyzer is independent — it can be built in its own worktree alongside any other analyzer.

**Code skeleton:**
```typescript
import { BaseAnalyzer } from "./base";
import { readdir, readFile } from "fs/promises";
import { join, relative } from "path";
import { execSync } from "child_process";
import type { Finding } from "../types";

export class TodoDebtAnalyzer extends BaseAnalyzer {
  name = "todo-debt";
  description = "Finds TODO/FIXME/HACK/XXX comments and enriches with git blame age";

  private readonly pattern = /\b(TODO|FIXME|HACK|XXX)\b/i;

  async run(repoPath: string) {
    const findings: Finding[] = [];
    // Walk source files
    // Grep for TODO/FIXME/HACK/XXX
    // Run git blame for age enrichment
    // Score based on volume and age
    const score = 100; // placeholder
    return this.result(findings, score);
  }
}
```

---

### 4. test-coverage

**Name:** `test-coverage`
**Description:** Maps test files to source files by naming convention. Flags source files without corresponding test files. Score = percentage of source files with tests.
**Difficulty:** Easy

**What it reads:**
- `src/` directory for source files
- `test/` or `tests/` directory for test files

**What it checks:**
- For each source file `src/foo.ts`, looks for `test/foo.test.ts`, `tests/foo.test.ts`, `test/foo.spec.ts`, etc.
- Flags source files with no matching test file

**Output shape:**
- Finding per uncovered source file (severity: warning)
- Finding for missing test directory (severity: error)
- Score: percentage of source files with corresponding tests

**Acceptance criteria:**
- Running against `test-fixtures/unhealthy-repo/` should flag `utils.ts`, `dead-module.ts`, and `index.ts` as uncovered
- Should recognize `active-module.test.ts` as covering `active-module.ts`
- Score should be 25% (1 of 4 source files covered)

**Independence note:** This analyzer is independent — it can be built in its own worktree alongside any other analyzer.

**Code skeleton:**
```typescript
import { BaseAnalyzer } from "./base";
import { readdir } from "fs/promises";
import { join, basename, extname } from "path";
import type { Finding } from "../types";

export class TestCoverageAnalyzer extends BaseAnalyzer {
  name = "test-coverage";
  description = "Checks that source files have corresponding test files";

  async run(repoPath: string) {
    const findings: Finding[] = [];
    // Find all source files in src/
    // Find all test files in test/ or tests/
    // Map test files to source files by naming convention
    // Flag uncovered source files
    const score = 100; // placeholder
    return this.result(findings, score);
  }
}
```

---

### 5. doc-health

**Name:** `doc-health`
**Description:** Reads all markdown files. Checks that relative links resolve to real files. Checks README exists. Checks package.json scripts reference existing files. Score = percentage of checks passing.
**Difficulty:** Easy-Medium

**What it reads:**
- All `.md` files in the repo
- `package.json` for script references
- File system to verify link targets exist

**What it checks:**
- README.md exists
- Relative links in markdown files (`[text](./path)`) resolve to actual files
- No merge conflict markers in markdown files
- Package.json scripts don't reference non-existent files

**Output shape:**
- Finding per broken link (severity: warning)
- Finding for missing README (severity: error)
- Finding for merge conflict markers (severity: error)
- Score: percentage of checks that pass

**Acceptance criteria:**
- Running against `test-fixtures/unhealthy-repo/` should flag broken links to `docs/architecture.md`, `CONTRIBUTING.md`, `docs/api.md`, `docs/setup.md`
- Should flag merge conflict markers in README
- Score should be low due to multiple broken links

**Independence note:** This analyzer is independent — it can be built in its own worktree alongside any other analyzer.

**Code skeleton:**
```typescript
import { BaseAnalyzer } from "./base";
import { readdir, readFile, access } from "fs/promises";
import { join, dirname } from "path";
import type { Finding } from "../types";

export class DocHealthAnalyzer extends BaseAnalyzer {
  name = "doc-health";
  description = "Checks markdown links, README existence, and doc completeness";

  async run(repoPath: string) {
    const findings: Finding[] = [];
    // Check README exists
    // Find all .md files
    // Parse relative links and verify targets exist
    // Check for merge conflict markers
    // Check package.json script references
    const score = 100; // placeholder
    return this.result(findings, score);
  }
}
```

---

## Stretch Analyzers

### 6. security-scanner

**Name:** `security-scanner`
**Description:** Scans for hardcoded secrets via regex patterns. Checks .gitignore coverage for sensitive files. Flags .env files committed to the repo.
**Difficulty:** Medium

**What it reads:**
- All source files for secret patterns
- `.gitignore` file
- Checks for `.env` files in repo

**What it checks:**
- Regex patterns for API keys, passwords, tokens (e.g., `AKIA...`, `password\s*=`, `Bearer ...`)
- `.env` files that should be gitignored
- `.gitignore` exists and covers common sensitive patterns

**Output shape:**
- Finding per potential secret (severity: error)
- Finding for unignored .env files (severity: error)
- Finding for missing .gitignore patterns (severity: warning)
- Score: 100 minus penalties per finding

**Acceptance criteria:**
- Running against `test-fixtures/unhealthy-repo/` should flag the `.env` file with secrets
- Should detect `AWS_ACCESS_KEY_ID`, `SECRET_KEY`, and `DATABASE_URL`
- Score should be very low due to committed secrets

**Independence note:** This analyzer is independent — it can be built in its own worktree alongside any other analyzer.

**Code skeleton:**
```typescript
import { BaseAnalyzer } from "./base";
import { readdir, readFile, access } from "fs/promises";
import { join, relative } from "path";
import type { Finding } from "../types";

export class SecurityScannerAnalyzer extends BaseAnalyzer {
  name = "security-scanner";
  description = "Scans for hardcoded secrets and checks .gitignore coverage";

  private readonly secretPatterns = [
    { name: "AWS Access Key", pattern: /AKIA[0-9A-Z]{16}/ },
    { name: "Generic Secret", pattern: /(?:secret|password|token|key)\s*[=:]\s*['"][^'"]{8,}['"]/i },
    { name: "Database URL", pattern: /(?:postgres|mysql|mongodb):\/\/[^\s]+/ },
  ];

  async run(repoPath: string) {
    const findings: Finding[] = [];
    // Check for .env files
    // Check .gitignore coverage
    // Scan source files for secret patterns
    const score = 100; // placeholder
    return this.result(findings, score);
  }
}
```

---

### 7. complexity

**Name:** `complexity`
**Description:** Measures file line counts and function counts per file. Flags files that are outliers (too long, too many functions). Score = percentage of files within healthy thresholds.
**Difficulty:** Easy-Medium

**What it reads:**
- All `.ts` / `.js` files in `src/`

**What it checks:**
- File line count (flag if > 300 lines)
- Function/method count per file (flag if > 15)
- Average function length (flag if > 50 lines)

**Output shape:**
- Finding per file exceeding thresholds (severity: warning for moderate, error for extreme)
- Score: percentage of files within all thresholds

**Acceptance criteria:**
- Running against a small repo should score high (files are short)
- Should correctly count functions using regex for `function`, arrow functions, and class methods
- Score should be 0-100

**Independence note:** This analyzer is independent — it can be built in its own worktree alongside any other analyzer.

**Code skeleton:**
```typescript
import { BaseAnalyzer } from "./base";
import { readdir, readFile } from "fs/promises";
import { join, relative } from "path";
import type { Finding } from "../types";

export class ComplexityAnalyzer extends BaseAnalyzer {
  name = "complexity";
  description = "Measures file and function complexity, flags outliers";

  private readonly maxFileLines = 300;
  private readonly maxFunctionsPerFile = 15;

  async run(repoPath: string) {
    const findings: Finding[] = [];
    // Walk source files
    // Count lines per file
    // Count functions per file
    // Flag outliers
    const score = 100; // placeholder
    return this.result(findings, score);
  }
}
```

---

### 8. git-health

**Name:** `git-health`
**Description:** Analyzes git repository health including commit frequency, stale branches, large files in history, and conflict markers in tracked files.
**Difficulty:** Medium

**What it reads:**
- Git log (via `git log` command)
- Git branches (via `git branch` command)
- Tracked files for conflict markers
- Git objects for large files

**What it checks:**
- Commit frequency (warn if no commits in last 30 days)
- Stale branches (branches with no commits in 90+ days)
- Conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`) in tracked files
- Uncommitted changes

**Output shape:**
- Finding per issue (severity varies)
- Score: starts at 100, penalties per issue

**Acceptance criteria:**
- Running against `test-fixtures/unhealthy-repo/` should flag conflict markers in README.md
- Should detect stale commit history (last commit is from 2024)
- Score should be < 100

**Independence note:** This analyzer is independent — it can be built in its own worktree alongside any other analyzer.

**Code skeleton:**
```typescript
import { BaseAnalyzer } from "./base";
import { readdir, readFile } from "fs/promises";
import { join } from "path";
import { execSync } from "child_process";
import type { Finding } from "../types";

export class GitHealthAnalyzer extends BaseAnalyzer {
  name = "git-health";
  description = "Analyzes git commit history, branches, and repo hygiene";

  async run(repoPath: string) {
    const findings: Finding[] = [];
    // Check commit frequency
    // Check for stale branches
    // Check for conflict markers in tracked files
    // Check for uncommitted changes
    const score = 100; // placeholder
    return this.result(findings, score);
  }
}
```
