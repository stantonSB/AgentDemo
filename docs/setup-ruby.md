# Ruby Track — Setup Guide

## Prerequisites

- **Ruby** 3.2+ — [Install Ruby](https://www.ruby-lang.org/en/documentation/installation/)
- **Bundler** — comes with Ruby, or `gem install bundler`
- **Git** 2.15+
- **Claude Code** v2.1.32+ — [Install Claude Code](https://docs.anthropic.com/en/docs/claude-code)

## Installation

```bash
# Clone the repo (if you haven't already)
git clone <repo-url>
cd repo-doctor-ruby

# Install dependencies
bundle install
```

## Verify It Works

Run the included sample analyzer against the test fixture repo:

```bash
bundle exec bin/repo-doctor test-fixtures/unhealthy-repo-ruby/
```

You should see output like:

```
Running 1 analyzer(s) against test-fixtures/unhealthy-repo-ruby/...

  Running: file-count...
  file-count: score 90/100 (1 findings)

--- Results ---

file-count: 90/100
  [info] . — Repository contains N files
```

## Running Tests

```bash
bundle exec rspec
```

## CLI Usage

```bash
# Run all analyzers (terminal output)
bundle exec bin/repo-doctor <repo-path>

# Generate an HTML report
bundle exec bin/repo-doctor <repo-path> --output report.html

# Run a single analyzer by name
bundle exec bin/repo-doctor <repo-path> --analyzer <name>
```

## Adding a New Analyzer

1. Create a file in `lib/analyzers/` (e.g., `my_analyzer.rb`)
2. Define a class extending `BaseAnalyzer`
3. Class name must be the camelized filename + `Analyzer` (e.g., `my_analyzer.rb` → `MyAnalyzerAnalyzer`)
4. Implement `name`, `description`, and `run(repo_path)`
5. The CLI auto-discovers it — no registration needed

```ruby
require_relative "base"

class MyAnalyzerAnalyzer < BaseAnalyzer
  def name = "my-analyzer"
  def description = "Checks something useful"

  def run(repo_path)
    findings = []
    # ... analyze the repo ...
    score = 85
    result(findings: findings, score: score)
  end
end
```

Naming conventions:
- Files: `snake_case.rb` (e.g., `dead_code.rb`, `todo_debt.rb`)
- One analyzer per file
- Class name = camelized filename + `Analyzer`

## Workshop Flow

1. Open the analyzer epic: `cat EPIC.md`
2. Open multiple terminal tabs
3. In each tab, from the `repo-doctor-ruby/` directory, run:
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
   bundle exec bin/repo-doctor test-fixtures/unhealthy-repo-ruby/ --output report.html
   ```
8. Open `report.html` in your browser

## Project Layout

```
repo-doctor-ruby/
├── Gemfile
├── Gemfile.lock
├── EPIC.md                     # Full list of analyzers to build
├── CLAUDE.md                   # Claude Code context for this project
├── bin/
│   └── repo-doctor             # Executable entry point
├── lib/
│   ├── cli.rb                  # Entry point, arg parsing, orchestration
│   ├── types.rb                # Finding, AnalyzerResult structs
│   ├── analyzers/
│   │   ├── base.rb             # BaseAnalyzer class
│   │   └── file_count.rb       # Sample analyzer (reference implementation)
│   └── renderer/
│       ├── html.rb             # HTML report generator
│       └── template.html       # Report template
├── spec/                       # Tests mirror lib/ structure
└── test-fixtures/
    └── unhealthy-repo-ruby/    # Sample repo with known issues for testing
```
