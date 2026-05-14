# Repo Doctor — Analyzer Epic (Ruby)

## Overview

### Vision

Repo Doctor is a CLI tool that performs automated health checks on any git repository and produces a scored HTML report. Think of it as a doctor's check-up for your codebase — it examines dependencies, code quality, documentation, security, complexity, and git hygiene, then gives each dimension a score from 0–100 and an overall grade.

> **Note:** None of the analyzers use AI or LLMs at runtime. Every check is deterministic — regex pattern matching, file system traversal, import graph parsing, git commands, and naming convention checks. The AI aspect of this project is in **how it's built** (parallel Claude Code sessions in git worktrees), not in what the tool itself does.

### What We're Building

A single command — `bundle exec bin/repo-doctor <repo-path>` — that:

1. **Discovers** all analyzers at runtime by globbing `lib/analyzers/*.rb`
2. **Runs** each analyzer against the target repository in sequence
3. **Collects** findings (file, line, message, severity) and a 0–100 score from each
4. **Renders** the results as either terminal output or a standalone HTML report with letter grades (A–F)

The tool ships with 8 independent analyzers spanning dependency health, code quality, documentation, security, complexity, and git hygiene. Each analyzer is a self-contained Ruby class extending `BaseAnalyzer` — no shared state, no cross-dependencies.

### How We Build It

Each analyzer is implemented in its own git worktree using a parallel Claude Code session. This means:

- **No merge conflicts** — each analyzer lives in its own file under `lib/analyzers/`
- **No coordination required** — auto-discovery means no central registration
- **Independent testing** — each analyzer has its own spec file and can be run in isolation via `--analyzer <name>`
- **Parallel development** — all 8 analyzers can be built simultaneously

### Architecture

```
CLI (lib/cli.rb)
  ├── discovers analyzers via glob
  ├── requires each file, camelizes class name
  ├── calls run(repo_path) on each
  ├── collects AnalyzerResult[]
  └── passes results to renderer

Analyzer (lib/analyzers/*.rb)
  ├── extends BaseAnalyzer
  ├── implements name, description, run()
  ├── returns AnalyzerResult(analyzer:, findings:, score:)
  └── uses only Ruby stdlib + Open3

Renderer (lib/renderer/)
  ├── reads template.html
  ├── calculates letter grades
  └── produces standalone HTML report
```

### Type System

- **Finding** — `Struct(file:, message:, severity:, line:)` where severity is `:info`, `:warning`, or `:error`
- **AnalyzerResult** — `Struct(analyzer:, findings:, score:)` where score is 0–100

---

## Project-Level Acceptance Criteria

These criteria apply to Repo Doctor as a whole, not to any individual analyzer.

### CLI

- [ ] `bundle exec bin/repo-doctor <repo-path>` runs all discovered analyzers and prints results to the terminal
- [ ] `bundle exec bin/repo-doctor <repo-path> --output report.html` generates a standalone HTML report
- [ ] `bundle exec bin/repo-doctor <repo-path> --analyzer <name>` runs only the named analyzer
- [ ] `bundle exec bin/repo-doctor --help` prints usage information
- [ ] Exit code is 0 on success, 1 on error
- [ ] Gracefully handles missing or invalid repo paths with a clear error message

### Auto-Discovery

- [ ] Any `.rb` file added to `lib/analyzers/` (other than `base.rb`) is automatically picked up — no registration needed
- [ ] Class name is derived from filename: `snake_case.rb` → `SnakeCaseAnalyzer`
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

- [ ] `bundle exec rspec` passes with no failures
- [ ] Each analyzer has a corresponding spec file in `spec/analyzers/`
- [ ] Specs run against `test-fixtures/unhealthy-repo-ruby/` to validate expected findings
- [ ] Specs verify score ranges, not exact scores (to avoid brittleness)

### End-to-End

- [ ] Running all 8 analyzers against `test-fixtures/unhealthy-repo-ruby/` produces a report with all expected issues flagged
- [ ] Running against a healthy repo produces high scores across the board
- [ ] The tool completes within a reasonable time (< 30 seconds for a typical repository)
- [ ] Analyzers use only Ruby stdlib + Open3 — no external gem dependencies

---

## 1. dependency-staleness

**Description:** Reads `Gemfile` and checks for outdated gem versions. Score = percentage of gems considered up-to-date.

**Difficulty:** Medium

**File:** `lib/analyzers/dependency_staleness.rb`
**Class:** `DependencyStalenessAnalyzer`
**Test:** `spec/analyzers/dependency_staleness_spec.rb`

### Inputs
- `Gemfile` in repo root

### Checks
- Parse gem declarations from Gemfile
- Flag gems with pinned old versions (compare against a known-good list or check version age)
- Flag gems without version constraints

### Output Shape
- Findings: one per outdated/unpinned gem
- Score: percentage of gems that are reasonably up-to-date (0-100)

### Acceptance Criteria
- [ ] Parses `Gemfile` and extracts gem names with version constraints
- [ ] Flags gems pinned to known-old versions (e.g., `rails` < 7.0, `nokogiri` < 1.14)
- [ ] Flags gems with no version constraint at all (severity: warning)
- [ ] Flags known deprecated gems (severity: error)
- [ ] Running against `test-fixtures/unhealthy-repo-ruby/` flags old pinned versions in Gemfile
- [ ] Score is < 100 for the unhealthy repo fixture
- [ ] Score is 0–100 for any repo with a Gemfile
- [ ] Returns gracefully (score 100, no findings) if no Gemfile is present
- [ ] Has passing specs

### Independence Note
This analyzer has no dependencies on other analyzers. It can be built in complete isolation.

### Code Skeleton
```ruby
require_relative "base"

class DependencyStalenessAnalyzer < BaseAnalyzer
  def name = "dependency-staleness"
  def description = "Checks Gemfile for outdated or unpinned dependencies"

  def run(repo_path)
    findings = []
    # Parse Gemfile, check versions
    score = 100
    result(findings: findings, score: score)
  end
end
```

---

## 2. dead-code

**Description:** Reads all `.rb` files in `lib/`. Builds a require graph from `require_relative` statements. Flags files never required by any other file.

**Difficulty:** Medium-Hard

**File:** `lib/analyzers/dead_code.rb`
**Class:** `DeadCodeAnalyzer`
**Test:** `spec/analyzers/dead_code_spec.rb`

### Inputs
- All `.rb` files under `lib/`

### Checks
- Scan for `require_relative` statements to build dependency graph
- Identify entry points (files in `bin/` or with `if __FILE__ == $0`)
- Flag `.rb` files that are never required

### Output Shape
- Findings: one per unreferenced file (severity: :warning)
- Score: percentage of files that are referenced (0-100)

### Acceptance Criteria
- [ ] Builds require graph by parsing `require_relative` statements from all `.rb` files
- [ ] Identifies entry points (files in `bin/`, files with `if __FILE__ == $0`)
- [ ] Running against `test-fixtures/unhealthy-repo-ruby/` flags `dead_module.rb` as dead code
- [ ] Does NOT flag `main.rb` (entry point) or `active_module.rb` (required by main)
- [ ] Score reflects percentage of live files (should be < 100 for unhealthy repo)
- [ ] Returns gracefully if no `lib/` directory exists
- [ ] Has passing specs

### Independence Note
This analyzer has no dependencies on other analyzers. It can be built in complete isolation.

### Code Skeleton
```ruby
require_relative "base"

class DeadCodeAnalyzer < BaseAnalyzer
  def name = "dead-code"
  def description = "Detects .rb files never required by any other file"

  def run(repo_path)
    findings = []
    # Build require graph, find unreferenced files
    score = 100
    result(findings: findings, score: score)
  end
end
```

---

## 3. todo-debt

**Description:** Greps for TODO/FIXME/HACK/XXX comments across all source files. Uses `git blame` to determine age.

**Difficulty:** Easy-Medium

**File:** `lib/analyzers/todo_debt.rb`
**Class:** `TodoDebtAnalyzer`
**Test:** `spec/analyzers/todo_debt_spec.rb`

### Inputs
- All text files in the repo (excluding vendor/, node_modules/, .git/)

### Checks
- Regex scan for TODO, FIXME, HACK, XXX (case-insensitive)
- Use `git blame` to get date of each match
- Flag old TODOs (> 90 days) as warnings, very old (> 365 days) as errors

### Output Shape
- Findings: one per TODO/FIXME/HACK/XXX comment
- Score: 100 - (number of TODOs * 5), clamped to 0-100

### Acceptance Criteria
- [ ] Finds TODO, FIXME, HACK, and XXX comments (case-insensitive)
- [ ] Running against `test-fixtures/unhealthy-repo-ruby/` finds all 4 markers in `lib/utils.rb`
- [ ] Each finding includes the file path, line number, and the matched comment text
- [ ] Severity escalates with age: `:info` for recent, `:warning` for > 90 days, `:error` for > 365 days
- [ ] Score is < 100 for the unhealthy repo fixture
- [ ] Excludes files in `vendor/`, `node_modules/`, and `.git/` directories
- [ ] Gracefully handles repos that are not git repositories (skips blame enrichment)
- [ ] Has passing specs

### Independence Note
This analyzer has no dependencies on other analyzers. It can be built in complete isolation.

### Code Skeleton
```ruby
require_relative "base"
require "open3"

class TodoDebtAnalyzer < BaseAnalyzer
  def name = "todo-debt"
  def description = "Finds TODO/FIXME/HACK/XXX comments and checks their age"

  def run(repo_path)
    findings = []
    # Grep for TODO/FIXME/HACK/XXX, use git blame for age
    score = 100
    result(findings: findings, score: score)
  end
end
```

---

## 4. test-coverage

**Description:** Maps spec files to lib files by naming convention. Flags lib files without a corresponding spec.

**Difficulty:** Easy

**File:** `lib/analyzers/test_coverage.rb`
**Class:** `TestCoverageAnalyzer`
**Test:** `spec/analyzers/test_coverage_spec.rb`

### Inputs
- Files in `lib/` and `spec/` directories

### Checks
- For each `.rb` file in `lib/`, check if a corresponding `_spec.rb` exists in `spec/`
- Mapping: `lib/foo.rb` -> `spec/foo_spec.rb`, `lib/bar/baz.rb` -> `spec/bar/baz_spec.rb`
- Flag uncovered files

### Output Shape
- Findings: one per uncovered lib file (severity: :warning)
- Score: percentage of lib files with specs (0-100)

### Acceptance Criteria
- [ ] Maps `lib/*.rb` files to `spec/*_spec.rb` by naming convention
- [ ] Handles nested directories: `lib/bar/baz.rb` → `spec/bar/baz_spec.rb`
- [ ] Running against `test-fixtures/unhealthy-repo-ruby/` flags `utils.rb`, `dead_module.rb`, and `main.rb` as uncovered
- [ ] Recognises `active_module_spec.rb` as covering `active_module.rb`
- [ ] Score reflects percentage of covered files (should be 25% for unhealthy repo — 1 of 4 files)
- [ ] Reports a finding with severity `:error` if no `spec/` directory exists at all
- [ ] Has passing specs

### Independence Note
This analyzer has no dependencies on other analyzers. It can be built in complete isolation.

### Code Skeleton
```ruby
require_relative "base"

class TestCoverageAnalyzer < BaseAnalyzer
  def name = "test-coverage"
  def description = "Checks for spec files matching lib files by naming convention"

  def run(repo_path)
    findings = []
    # Map lib/*.rb -> spec/*_spec.rb
    score = 100
    result(findings: findings, score: score)
  end
end
```

---

## 5. doc-health

**Description:** Checks that README exists, markdown links resolve, and basic documentation standards are met.

**Difficulty:** Easy-Medium

**File:** `lib/analyzers/doc_health.rb`
**Class:** `DocHealthAnalyzer`
**Test:** `spec/analyzers/doc_health_spec.rb`

### Inputs
- README.md and other markdown files
- File system for link resolution

### Checks
- README.md exists
- Markdown relative links resolve to existing files
- No merge conflict markers in markdown files
- No broken internal links

### Output Shape
- Findings: one per issue (missing README = error, broken link = warning, conflict markers = error)
- Score: based on number of issues found

### Acceptance Criteria
- [ ] Detects missing README.md (severity: `:error`)
- [ ] Parses relative markdown links (`[text](./path)`) and verifies targets exist on disk
- [ ] Running against `test-fixtures/unhealthy-repo-ruby/` flags broken links and merge conflict markers in README
- [ ] Detects merge conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`) in any `.md` file (severity: `:error`)
- [ ] Score is low for the unhealthy repo fixture due to multiple broken links and conflict markers
- [ ] Does not flag external URLs (http/https links) — only checks relative paths
- [ ] Has passing specs

### Independence Note
This analyzer has no dependencies on other analyzers. It can be built in complete isolation.

### Code Skeleton
```ruby
require_relative "base"

class DocHealthAnalyzer < BaseAnalyzer
  def name = "doc-health"
  def description = "Checks README and markdown link health"

  def run(repo_path)
    findings = []
    # Check README, validate links
    score = 100
    result(findings: findings, score: score)
  end
end
```

---

## 6. security-scanner

**Description:** Scans for hardcoded secrets, .env files committed, and missing .gitignore patterns.

**Difficulty:** Medium

**File:** `lib/analyzers/security_scanner.rb`
**Class:** `SecurityScannerAnalyzer`
**Test:** `spec/analyzers/security_scanner_spec.rb`

### Inputs
- All tracked files
- .gitignore contents

### Checks
- Regex for API keys, secrets, passwords in source files
- Check if .env files are tracked by git
- Verify .gitignore includes common sensitive patterns (.env, *.pem, etc.)

### Output Shape
- Findings: one per potential secret or missing gitignore rule (severity: :error for secrets, :warning for gitignore)
- Score: 100 - (errors * 20 + warnings * 5), clamped to 0-100

### Acceptance Criteria
- [ ] Detects common secret patterns via regex (AWS keys, passwords, tokens, database URLs)
- [ ] Running against `test-fixtures/unhealthy-repo-ruby/` flags the `.env` file with `AWS_ACCESS_KEY_ID`, `SECRET_KEY`, and `DATABASE_URL`
- [ ] Flags `.env` files that are tracked by git (severity: `:error`)
- [ ] Checks `.gitignore` exists and covers common sensitive patterns (`.env`, `*.pem`, `*.key`)
- [ ] Score is very low for the unhealthy repo fixture due to committed secrets
- [ ] Does not scan binary files or `.git/` directory
- [ ] Has passing specs

### Independence Note
This analyzer has no dependencies on other analyzers. It can be built in complete isolation.

### Code Skeleton
```ruby
require_relative "base"
require "open3"

class SecurityScannerAnalyzer < BaseAnalyzer
  def name = "security-scanner"
  def description = "Scans for hardcoded secrets and missing .gitignore rules"

  def run(repo_path)
    findings = []
    # Regex for secrets, check .gitignore
    score = 100
    result(findings: findings, score: score)
  end
end
```

---

## 7. complexity

**Description:** Analyzes file and method sizes. Flags outliers with excessive line counts or method counts.

**Difficulty:** Easy-Medium

**File:** `lib/analyzers/complexity.rb`
**Class:** `ComplexityAnalyzer`
**Test:** `spec/analyzers/complexity_spec.rb`

### Inputs
- All `.rb` files in the repo

### Checks
- Count lines per file (flag > 200 lines)
- Count methods per file (flag > 15 methods)
- Identify longest methods (flag > 30 lines)

### Output Shape
- Findings: one per file/method exceeding thresholds
- Score: percentage of files within acceptable limits (0-100)

### Acceptance Criteria
- [ ] Counts lines per `.rb` file and flags those exceeding 200 lines (severity: `:warning`)
- [ ] Counts `def` methods per file and flags those exceeding 15 methods (severity: `:warning`)
- [ ] Identifies individual methods exceeding 30 lines (severity: `:warning`)
- [ ] Uses `:error` severity for extreme outliers (e.g., > 500 lines or > 30 methods)
- [ ] Running against a small repo scores high (files are short)
- [ ] Correctly counts methods using `def`/`end` patterns, including class methods
- [ ] Score is 0–100 and reflects the percentage of files within all thresholds
- [ ] Excludes `vendor/`, `.git/`, and other non-project directories
- [ ] Has passing specs

### Independence Note
This analyzer has no dependencies on other analyzers. It can be built in complete isolation.

### Code Skeleton
```ruby
require_relative "base"

class ComplexityAnalyzer < BaseAnalyzer
  def name = "complexity"
  def description = "Flags files and methods that exceed complexity thresholds"

  def run(repo_path)
    findings = []
    # Count lines, methods, flag outliers
    score = 100
    result(findings: findings, score: score)
  end
end
```

---

## 8. git-health

**Description:** Analyzes git history for commit frequency, stale branches, and conflict markers.

**Difficulty:** Medium

**File:** `lib/analyzers/git_health.rb`
**Class:** `GitHealthAnalyzer`
**Test:** `spec/analyzers/git_health_spec.rb`

### Inputs
- Git history (via `git log`, `git branch`)
- Source files (for conflict markers)

### Checks
- Recent commit frequency (warn if no commits in 30+ days)
- Stale branches (branches with no recent commits)
- Conflict markers in tracked files (`<<<<<<<`, `=======`, `>>>>>>>`)
- Uncommitted changes

### Output Shape
- Findings: one per issue found
- Score: starts at 100, penalties per issue

### Acceptance Criteria
- [ ] Checks commit recency via `git log` and warns if no commits in the last 30 days
- [ ] Detects stale branches (no commits in 90+ days) via `git branch` and `git log`
- [ ] Running against `test-fixtures/unhealthy-repo-ruby/` flags conflict markers in README.md
- [ ] Detects merge conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`) in all tracked files (severity: `:error`)
- [ ] Score is < 100 for the unhealthy repo fixture
- [ ] Gracefully handles repos with no branches or minimal history
- [ ] Uses `Open3` for all git commands (no backticks or `system()`)
- [ ] Has passing specs

### Independence Note
This analyzer has no dependencies on other analyzers. It can be built in complete isolation.

### Code Skeleton
```ruby
require_relative "base"
require "open3"

class GitHealthAnalyzer < BaseAnalyzer
  def name = "git-health"
  def description = "Analyzes git history, branches, and conflict markers"

  def run(repo_path)
    findings = []
    # Check commit frequency, conflict markers, stale branches
    score = 100
    result(findings: findings, score: score)
  end
end
```
