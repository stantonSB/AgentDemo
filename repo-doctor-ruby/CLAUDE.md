# Repo Doctor

A CLI tool that analyzes git repositories and produces HTML health reports.

## Quick Reference

```bash
bundle exec bin/repo-doctor <repo-path>                          # Run all analyzers, terminal output
bundle exec bin/repo-doctor <repo-path> --output report.html     # Generate HTML report
bundle exec bin/repo-doctor <repo-path> --analyzer <name>        # Run single analyzer
bundle exec rspec                                                 # Run tests
```

## Architecture

The CLI discovers analyzers at runtime by globbing `lib/analyzers/*.rb` (excluding `base.rb`). Each analyzer extends `BaseAnalyzer` from `lib/analyzers/base.rb`.

## How to Add a New Analyzer

1. Create a new file in `lib/analyzers/` (e.g., `my_analyzer.rb`)
2. Define a class that extends `BaseAnalyzer`
3. Class name MUST be the camelized filename + "Analyzer" (e.g., `my_analyzer.rb` -> `MyAnalyzerAnalyzer`)
4. Implement `name`, `description`, and `run(repo_path)`
5. `run()` must return an `AnalyzerResult` with `analyzer`, `findings`, and `score` (0-100)
6. The CLI auto-discovers your analyzer — no registration needed

### Example:

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

## File Naming

- Analyzer files: `snake_case.rb` (e.g., `dead_code.rb`, `todo_debt.rb`)
- One analyzer per file
- Class name = camelized filename + "Analyzer"

## Conventions

- Analyzers use only Ruby stdlib + Open3 for git commands
- No external gem dependencies in analyzers
- Scores are 0-100 (higher = healthier)
- Findings have severity: :info, :warning, or :error
- Test against the fixture repo: `bundle exec bin/repo-doctor test-fixtures/unhealthy-repo-ruby/ --analyzer <name>`

## Project Structure

```
lib/
  cli.rb              # Entry point, arg parsing, orchestration
  types.rb            # Finding, AnalyzerResult structs
  analyzers/
    base.rb           # BaseAnalyzer class
    file_count.rb     # Sample analyzer (reference)
  renderer/
    html.rb           # HTML report generator
    template.html     # Report template
bin/
  repo-doctor         # Executable entry point
spec/                 # Tests mirror lib/ structure
test-fixtures/
  unhealthy-repo-ruby/  # Sample repo with known issues for testing
```
