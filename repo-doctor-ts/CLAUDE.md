# Repo Doctor

A CLI tool that analyzes git repositories and produces HTML health reports.

## Quick Reference

```bash
bun run doctor <repo-path>                          # Run all analyzers, terminal output
bun run doctor <repo-path> --output report.html     # Generate HTML report
bun run doctor <repo-path> --analyzer <name>        # Run single analyzer
bun test                                             # Run tests
```

## Architecture

The CLI discovers analyzers at runtime by globbing `src/analyzers/*.ts` (excluding `base.ts`). Each analyzer implements the `Analyzer` interface from `src/types.ts`.

## How to Add a New Analyzer

1. Create a new file in `src/analyzers/` (e.g., `my-analyzer.ts`)
2. Export a class that extends `BaseAnalyzer` from `./base`
3. Implement `name`, `description`, and `run(repoPath: string)`
4. `run()` must return `Promise<AnalyzerResult>` with `{ analyzer: string, findings: Finding[], score: number }`
5. The CLI auto-discovers your analyzer — no registration needed

### Example:

```typescript
import { BaseAnalyzer } from "./base";

export class MyAnalyzer extends BaseAnalyzer {
  name = "my-analyzer";
  description = "Checks something useful";

  async run(repoPath: string) {
    const findings = [];
    // ... analyze the repo ...
    const score = 85;
    return this.result(findings, score);
  }
}
```

## File Naming

- Analyzer files: `kebab-case.ts` (e.g., `dead-code.ts`, `todo-debt.ts`)
- One analyzer per file
- File name should match the analyzer's `name` property

## Conventions

- Analyzers use only Node/Bun stdlib + child_process for git commands
- No external npm dependencies in analyzers
- Scores are 0-100 (higher = healthier)
- Findings have severity: "info", "warning", or "error"
- Test against the fixture repo: `bun run doctor test-fixtures/unhealthy-repo/ --analyzer <name>`

## Project Structure

```
src/
  cli.ts              # Entry point, arg parsing, orchestration
  types.ts            # Analyzer, Finding, AnalyzerResult interfaces
  analyzers/
    base.ts           # BaseAnalyzer abstract class
    file-count.ts     # Sample analyzer (reference)
  renderer/
    html.ts           # HTML report generator
    template.html     # Report template
test/                 # Tests mirror src/ structure
test-fixtures/
  unhealthy-repo/     # Sample repo with known issues for testing
```
