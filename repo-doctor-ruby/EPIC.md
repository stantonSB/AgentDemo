# Repo Doctor — Analyzer Epic (Ruby)

This epic defines 8 independent analyzers to be built in parallel using Claude Code worktrees. Each analyzer extends `BaseAnalyzer`, uses only Ruby stdlib + Open3, and produces an `AnalyzerResult`.

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
- [ ] Parses Gemfile correctly
- [ ] Flags gems with old pinned versions
- [ ] Returns score 0-100
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
- [ ] Builds require graph from `require_relative` statements
- [ ] Correctly identifies dead files
- [ ] Returns score 0-100
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
- [ ] Finds TODO/FIXME/HACK/XXX comments
- [ ] Reports file, line number, and message
- [ ] Returns score 0-100
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
- [ ] Correctly maps lib files to spec files
- [ ] Flags files without corresponding specs
- [ ] Returns score 0-100
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
- No broken internal links
- Check for common sections (Getting Started, etc.)

### Output Shape
- Findings: one per issue (missing README = error, broken link = warning)
- Score: based on number of issues found

### Acceptance Criteria
- [ ] Detects missing README
- [ ] Finds broken relative links in markdown
- [ ] Returns score 0-100
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
- [ ] Detects common secret patterns
- [ ] Flags tracked .env files
- [ ] Checks .gitignore coverage
- [ ] Returns score 0-100
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
- [ ] Counts lines per file
- [ ] Counts methods per file
- [ ] Flags oversized files and methods
- [ ] Returns score 0-100
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
- Large files in history

### Output Shape
- Findings: one per issue found
- Score: based on severity and count of issues

### Acceptance Criteria
- [ ] Checks commit recency
- [ ] Detects conflict markers
- [ ] Returns score 0-100
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
