# Repo Doctor Skeleton Repos Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build two skeleton repos (TypeScript + Ruby) for the workshop hands-on section. Each repo has a working CLI, analyzer plugin interface, HTML report renderer, sample analyzer, test fixtures, CLAUDE.md, and EPIC.md. Participants implement the analyzers — everything else is pre-built.

**Architecture:** Each repo is a standalone CLI tool. The CLI discovers analyzers via directory convention (glob `src/analyzers/*.ts` or `lib/analyzers/*.rb`), runs them against a target repo path, and renders results as a standalone HTML report. No external AI dependencies — analyzers use only stdlib + git CLI.

**Tech Stack:**
- TypeScript track: Bun, TypeScript, no runtime dependencies beyond Node stdlib + child_process for git
- Ruby track: Ruby 3.2+, Bundler, no gems beyond stdlib + Open3 for git

**Spec:** `docs/superpowers/specs/2026-05-13-ai-workshop-design.md` — Part 2

---

## File Structure

### TypeScript Track

```
repo-doctor-ts/
  package.json
  tsconfig.json
  bun.lockb
  .gitignore
  CLAUDE.md
  EPIC.md
  README.md
  src/
    cli.ts                        # Entry point: arg parsing, analyzer discovery, orchestration
    types.ts                      # Finding, AnalyzerResult, Analyzer interface, Severity enum
    analyzers/
      base.ts                     # Abstract base class (optional, for convenience)
      file-count.ts               # Sample analyzer — reference implementation
    renderer/
      html.ts                     # Takes AnalyzerResult[], produces HTML string
      template.html               # HTML report template with CSS
  test/
    cli.test.ts                   # CLI integration tests
    analyzers/
      file-count.test.ts          # Sample analyzer unit test
    renderer/
      html.test.ts                # Renderer unit test
  test-fixtures/
    unhealthy-repo/               # Git repo seeded with known issues
      .git/                       # Initialised git repo with history
      package.json                # Outdated deps (exact pinned old versions)
      .env                        # Contains fake API key (stretch: security-scanner)
      src/
        index.ts                  # Main entry, imports active-module
        active-module.ts          # Imported and used
        dead-module.ts            # Never imported
        utils.ts                  # Has TODO/FIXME/HACK comments
      tests/
        active-module.test.ts     # Exists
                                  # utils.test.ts intentionally missing
      README.md                   # Contains broken relative links + <<<<<<< conflict marker
```

### Ruby Track

```
repo-doctor-ruby/
  Gemfile
  Gemfile.lock
  .gitignore
  CLAUDE.md
  EPIC.md
  README.md
  lib/
    cli.rb                        # Entry point: arg parsing, analyzer discovery, orchestration
    types.rb                      # Finding, AnalyzerResult structs, Severity
    analyzers/
      base.rb                     # Base module/class
      file_count.rb               # Sample analyzer — reference implementation
    renderer/
      html.rb                     # Takes analyzer results, produces HTML string
      template.html               # HTML report template with CSS (shared with TS track)
  bin/
    repo-doctor                   # Executable entry point
  spec/
    cli_spec.rb                   # CLI integration tests
    analyzers/
      file_count_spec.rb          # Sample analyzer unit test
    renderer/
      html_spec.rb                # Renderer unit test
  test-fixtures/
    unhealthy-repo-ruby/          # Git repo seeded with known issues
      .git/                       # Initialised git repo with history
      Gemfile                     # Outdated gems (exact pinned old versions)
      .env                        # Contains fake API key (stretch: security-scanner)
      lib/
        main.rb                   # Requires active_module
        active_module.rb          # Required and used
        dead_module.rb            # Never required
        utils.rb                  # Has TODO/FIXME/HACK comments
      spec/
        active_module_spec.rb     # Exists
                                  # utils_spec.rb intentionally missing
      README.md                   # Contains broken relative links + <<<<<<< conflict marker
```

---

## Chunk 1: TypeScript Skeleton

### Task 1: Initialise the TypeScript project

**Files:**
- Create: `repo-doctor-ts/package.json`
- Create: `repo-doctor-ts/tsconfig.json`
- Create: `repo-doctor-ts/.gitignore`

- [ ] **Step 1: Create the project directory and initialise**

```bash
mkdir repo-doctor-ts && cd repo-doctor-ts
bun init -y
```

- [ ] **Step 2: Configure package.json**

Edit `package.json`:

```json
{
  "name": "repo-doctor",
  "version": "0.1.0",
  "type": "module",
  "bin": {
    "repo-doctor": "./src/cli.ts"
  },
  "scripts": {
    "doctor": "bun run src/cli.ts",
    "test": "bun test"
  },
  "devDependencies": {
    "@types/bun": "latest",
    "typescript": "^5.7"
  }
}
```

- [ ] **Step 3: Configure tsconfig.json**

```json
{
  "compilerOptions": {
    "target": "ESNext",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "strict": true,
    "esModuleInterop": true,
    "outDir": "./dist",
    "rootDir": "./src",
    "declaration": true,
    "types": ["bun-types"]
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "test-fixtures"]
}
```

- [ ] **Step 4: Create .gitignore**

```
node_modules/
dist/
*.tgz
```

- [ ] **Step 5: Install dependencies and verify**

```bash
bun install
```

- [ ] **Step 6: Commit**

```bash
git init
git add package.json tsconfig.json .gitignore bun.lockb
git commit -m "feat: initialise TypeScript project with Bun"
```

---

### Task 2: Define types and analyzer interface

**Files:**
- Create: `repo-doctor-ts/src/types.ts`
- Create: `repo-doctor-ts/src/analyzers/base.ts`

- [ ] **Step 1: Write the test for types**

Create `repo-doctor-ts/test/types.test.ts`:

```typescript
import { describe, expect, test } from "bun:test";
import type { Analyzer, AnalyzerResult, Finding } from "../src/types";

describe("types", () => {
  test("Finding has required shape", () => {
    const finding: Finding = {
      file: "src/index.ts",
      line: 10,
      message: "Unused import",
      severity: "warning",
    };
    expect(finding.file).toBe("src/index.ts");
    expect(finding.severity).toBe("warning");
  });

  test("AnalyzerResult has required shape", () => {
    const result: AnalyzerResult = {
      analyzer: "test-analyzer",
      findings: [],
      score: 85,
    };
    expect(result.score).toBeGreaterThanOrEqual(0);
    expect(result.score).toBeLessThanOrEqual(100);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

```bash
bun test test/types.test.ts
```

Expected: FAIL — cannot find module `../src/types`

- [ ] **Step 3: Implement types.ts**

Create `repo-doctor-ts/src/types.ts`:

```typescript
export type Severity = "info" | "warning" | "error";

export interface Finding {
  file: string;
  line?: number;
  message: string;
  severity: Severity;
}

export interface AnalyzerResult {
  analyzer: string;
  findings: Finding[];
  score: number; // 0-100
}

export interface Analyzer {
  name: string;
  description: string;
  run(repoPath: string): Promise<AnalyzerResult>;
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
bun test test/types.test.ts
```

Expected: PASS

- [ ] **Step 5: Create base.ts convenience class**

Create `repo-doctor-ts/src/analyzers/base.ts`:

```typescript
import type { Analyzer, AnalyzerResult, Finding, Severity } from "../types";

export abstract class BaseAnalyzer implements Analyzer {
  abstract name: string;
  abstract description: string;
  abstract run(repoPath: string): Promise<AnalyzerResult>;

  protected finding(
    file: string,
    message: string,
    severity: Severity = "warning",
    line?: number
  ): Finding {
    return { file, message, severity, line };
  }

  protected result(findings: Finding[], score: number): AnalyzerResult {
    return { analyzer: this.name, findings, score: Math.max(0, Math.min(100, score)) };
  }
}
```

- [ ] **Step 6: Commit**

```bash
git add src/types.ts src/analyzers/base.ts test/types.test.ts
git commit -m "feat: add types and base analyzer class"
```

---

### Task 3: Build the sample analyzer (file-count)

**Files:**
- Create: `repo-doctor-ts/src/analyzers/file-count.ts`
- Create: `repo-doctor-ts/test/analyzers/file-count.test.ts`

- [ ] **Step 1: Write the test**

Create `repo-doctor-ts/test/analyzers/file-count.test.ts`:

```typescript
import { describe, expect, test } from "bun:test";
import { FileCountAnalyzer } from "../../src/analyzers/file-count";

describe("FileCountAnalyzer", () => {
  test("has correct name", () => {
    const analyzer = new FileCountAnalyzer();
    expect(analyzer.name).toBe("file-count");
  });

  test("returns findings and score for a directory", async () => {
    const analyzer = new FileCountAnalyzer();
    // Run against the project's own src/ as a basic sanity check
    const result = await analyzer.run(process.cwd());
    expect(result.analyzer).toBe("file-count");
    expect(result.score).toBeGreaterThanOrEqual(0);
    expect(result.score).toBeLessThanOrEqual(100);
    expect(Array.isArray(result.findings)).toBe(true);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

```bash
bun test test/analyzers/file-count.test.ts
```

Expected: FAIL — cannot find module

- [ ] **Step 3: Implement file-count.ts**

Create `repo-doctor-ts/src/analyzers/file-count.ts`:

```typescript
import { BaseAnalyzer } from "./base";
import { readdir, stat } from "fs/promises";
import { join, extname } from "path";
import type { Finding } from "../types";

export class FileCountAnalyzer extends BaseAnalyzer {
  name = "file-count";
  description = "Counts files by type and flags repos with an unusually high file count";

  async run(repoPath: string) {
    const counts = new Map<string, number>();
    let totalFiles = 0;

    const walk = async (dir: string): Promise<void> => {
      const entries = await readdir(dir, { withFileTypes: true });
      for (const entry of entries) {
        if (entry.name.startsWith(".") || entry.name === "node_modules") continue;
        const fullPath = join(dir, entry.name);
        if (entry.isDirectory()) {
          await walk(fullPath);
        } else {
          totalFiles++;
          const ext = extname(entry.name) || "(no extension)";
          counts.set(ext, (counts.get(ext) || 0) + 1);
        }
      }
    };

    await walk(repoPath);

    const findings: Finding[] = [...counts.entries()]
      .sort((a, b) => b[1] - a[1])
      .map(([ext, count]) =>
        this.finding(repoPath, `${ext}: ${count} files`, "info")
      );

    // Score: 100 if under 500 files, decreasing linearly to 0 at 5000 files
    const score = Math.max(0, Math.round(100 - (totalFiles / 5000) * 100));

    return this.result(findings, score);
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
bun test test/analyzers/file-count.test.ts
```

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/analyzers/file-count.ts test/analyzers/file-count.test.ts
git commit -m "feat: add file-count sample analyzer as reference implementation"
```

---

### Task 4: Build the HTML report renderer

**Files:**
- Create: `repo-doctor-ts/src/renderer/html.ts`
- Create: `repo-doctor-ts/src/renderer/template.html`
- Create: `repo-doctor-ts/test/renderer/html.test.ts`

- [ ] **Step 1: Write the test**

Create `repo-doctor-ts/test/renderer/html.test.ts`:

```typescript
import { describe, expect, test } from "bun:test";
import { renderReport } from "../../src/renderer/html";
import type { AnalyzerResult } from "../../src/types";

describe("renderReport", () => {
  test("produces valid HTML with analyzer results", () => {
    const results: AnalyzerResult[] = [
      {
        analyzer: "test-analyzer",
        findings: [
          { file: "src/index.ts", message: "Test finding", severity: "warning" },
        ],
        score: 75,
      },
    ];
    const html = renderReport(results);
    expect(html).toContain("<!DOCTYPE html>");
    expect(html).toContain("test-analyzer");
    expect(html).toContain("75");
    expect(html).toContain("Test finding");
    expect(html).toContain("src/index.ts");
  });

  test("handles empty results", () => {
    const html = renderReport([]);
    expect(html).toContain("<!DOCTYPE html>");
    expect(html).toContain("No analyzers ran");
  });

  test("colour-codes scores", () => {
    const results: AnalyzerResult[] = [
      { analyzer: "good", findings: [], score: 90 },
      { analyzer: "ok", findings: [], score: 70 },
      { analyzer: "bad", findings: [], score: 30 },
    ];
    const html = renderReport(results);
    expect(html).toContain("grade-a"); // 90
    expect(html).toContain("grade-c"); // 70
    expect(html).toContain("grade-f"); // 30
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

```bash
bun test test/renderer/html.test.ts
```

Expected: FAIL

- [ ] **Step 3: Implement the HTML template**

Create `repo-doctor-ts/src/renderer/template.html`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>{{TITLE}}</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; background: #0d1117; color: #e6edf3; padding: 2rem; max-width: 900px; margin: 0 auto; }
    h1 { font-size: 2rem; margin-bottom: 0.5rem; }
    .overall-score { font-size: 3rem; font-weight: bold; margin: 1rem 0 2rem; }
    .grade-a { color: #3fb950; } .grade-b { color: #56d364; } .grade-c { color: #d29922; } .grade-d { color: #db6d28; } .grade-f { color: #f85149; }
    .analyzer { background: #161b22; border: 1px solid #30363d; border-radius: 8px; margin-bottom: 1rem; overflow: hidden; }
    .analyzer-header { display: flex; justify-content: space-between; align-items: center; padding: 1rem 1.5rem; cursor: pointer; user-select: none; }
    .analyzer-header:hover { background: #1c2128; }
    .analyzer-name { font-size: 1.1rem; font-weight: 600; }
    .score { font-size: 1.2rem; font-weight: bold; }
    .analyzer-body { display: none; padding: 0 1.5rem 1rem; border-top: 1px solid #30363d; }
    .analyzer.expanded .analyzer-body { display: block; }
    .findings { list-style: none; padding: 0.5rem 0; }
    .findings li { padding: 0.5rem 0; border-bottom: 1px solid #21262d; display: flex; gap: 0.75rem; align-items: baseline; font-size: 0.9rem; }
    .findings li:last-child { border-bottom: none; }
    .severity { padding: 2px 8px; border-radius: 4px; font-size: 0.75rem; font-weight: 600; text-transform: uppercase; }
    .severity.info { background: #1f6feb33; color: #58a6ff; } .severity.warning { background: #d2992233; color: #d29922; } .severity.error { background: #f8514933; color: #f85149; }
    .file { color: #58a6ff; font-family: monospace; font-size: 0.85rem; }
    .message { color: #8b949e; }
    .no-findings { color: #3fb950; padding: 0.5rem 0; }
    footer { margin-top: 2rem; color: #484f58; font-size: 0.8rem; text-align: center; }
  </style>
</head>
<body>
  <h1>{{TITLE}}</h1>
  <div class="overall-score">{{OVERALL_SCORE}}</div>
  <div class="analyzers">{{ANALYZERS}}</div>
  <footer>Generated {{TIMESTAMP}}</footer>
</body>
</html>
```

- [ ] **Step 4: Implement html.ts**

Create `repo-doctor-ts/src/renderer/html.ts`:

```typescript
import { readFileSync } from "fs";
import { join } from "path";
import type { AnalyzerResult } from "../types";

function gradeClass(score: number): string {
  if (score >= 90) return "grade-a";
  if (score >= 80) return "grade-b";
  if (score >= 70) return "grade-c";
  if (score >= 60) return "grade-d";
  return "grade-f";
}

function gradeLetter(score: number): string {
  if (score >= 90) return "A";
  if (score >= 80) return "B";
  if (score >= 70) return "C";
  if (score >= 60) return "D";
  return "F";
}

function renderAnalyzer(result: AnalyzerResult): string {
  const findings = result.findings.length === 0
    ? "<p class=\"no-findings\">No issues found</p>"
    : `<ul class="findings">${result.findings
        .map(f => `<li>
          <span class="severity ${f.severity}">${f.severity}</span>
          <span class="file">${f.file}${f.line ? `:${f.line}` : ""}</span>
          <span class="message">${f.message}</span>
        </li>`)
        .join("")}</ul>`;

  return `<section class="analyzer">
    <div class="analyzer-header" onclick="this.parentElement.classList.toggle('expanded')">
      <span class="analyzer-name">${result.analyzer}</span>
      <span class="score ${gradeClass(result.score)}">${gradeLetter(result.score)} (${result.score})</span>
    </div>
    <div class="analyzer-body">${findings}</div>
  </section>`;
}

export function renderReport(results: AnalyzerResult[]): string {
  const templatePath = join(import.meta.dir, "template.html");
  let template = readFileSync(templatePath, "utf-8");

  if (results.length === 0) {
    return template
      .replace("{{TITLE}}", "Repo Doctor Report")
      .replace("{{OVERALL_SCORE}}", "N/A")
      .replace("{{ANALYZERS}}", "<p>No analyzers ran</p>")
      .replace("{{TIMESTAMP}}", new Date().toISOString());
  }

  const overallScore = Math.round(
    results.reduce((sum, r) => sum + r.score, 0) / results.length
  );

  return template
    .replace("{{TITLE}}", "Repo Doctor Report")
    .replace("{{OVERALL_SCORE}}", `<span class="${gradeClass(overallScore)}">${gradeLetter(overallScore)} (${overallScore})</span>`)
    .replace("{{ANALYZERS}}", results.map(renderAnalyzer).join("\n"))
    .replace("{{TIMESTAMP}}", new Date().toISOString());
}
```

- [ ] **Step 5: Run test to verify it passes**

```bash
bun test test/renderer/html.test.ts
```

Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add src/renderer/html.ts src/renderer/template.html test/renderer/html.test.ts
git commit -m "feat: add HTML report renderer with grade-coded scores"
```

---

### Task 5: Build the CLI with analyzer auto-discovery

**Files:**
- Create: `repo-doctor-ts/src/cli.ts`
- Create: `repo-doctor-ts/test/cli.test.ts`

- [ ] **Step 1: Write the test**

Create `repo-doctor-ts/test/cli.test.ts`:

```typescript
import { describe, expect, test } from "bun:test";
import { discoverAnalyzers } from "../src/cli";

describe("CLI", () => {
  test("discovers analyzers from the analyzers directory", async () => {
    const analyzers = await discoverAnalyzers();
    expect(analyzers.length).toBeGreaterThanOrEqual(1);
    // Should find at least the file-count sample analyzer
    const names = analyzers.map((a) => a.name);
    expect(names).toContain("file-count");
  });

  test("does not discover base.ts as an analyzer", async () => {
    const analyzers = await discoverAnalyzers();
    const names = analyzers.map((a) => a.name);
    expect(names).not.toContain("base");
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

```bash
bun test test/cli.test.ts
```

Expected: FAIL

- [ ] **Step 3: Implement cli.ts**

Create `repo-doctor-ts/src/cli.ts` with shebang `#!/usr/bin/env bun`:

```typescript
#!/usr/bin/env bun

import { readdir } from "fs/promises";
import { join } from "path";
import { writeFileSync } from "fs";
import type { Analyzer, AnalyzerResult } from "./types";
import { renderReport } from "./renderer/html";

export async function discoverAnalyzers(): Promise<Analyzer[]> {
  const analyzersDir = join(import.meta.dir, "analyzers");
  const files = await readdir(analyzersDir);
  const analyzers: Analyzer[] = [];

  for (const file of files) {
    if (file === "base.ts" || !file.endsWith(".ts")) continue;
    const mod = await import(join(analyzersDir, file));
    // Find the exported class that implements Analyzer
    for (const key of Object.keys(mod)) {
      const ExportedClass = mod[key];
      if (typeof ExportedClass === "function" && ExportedClass.prototype?.run) {
        analyzers.push(new ExportedClass());
      }
    }
  }

  return analyzers;
}

async function main() {
  const args = process.argv.slice(2);

  if (args.length === 0 || args.includes("--help")) {
    console.log("Usage: repo-doctor <repo-path> [--output report.html] [--analyzer <name>]");
    process.exit(args.includes("--help") ? 0 : 1);
  }

  const repoPath = args[0];
  const outputIdx = args.indexOf("--output");
  const outputPath = outputIdx !== -1 ? args[outputIdx + 1] : null;
  const analyzerIdx = args.indexOf("--analyzer");
  const analyzerFilter = analyzerIdx !== -1 ? args[analyzerIdx + 1] : null;

  let analyzers = await discoverAnalyzers();

  if (analyzerFilter) {
    analyzers = analyzers.filter((a) => a.name === analyzerFilter);
    if (analyzers.length === 0) {
      console.error(`Unknown analyzer: ${analyzerFilter}`);
      process.exit(1);
    }
  }

  console.log(`Running ${analyzers.length} analyzer(s) against ${repoPath}...\n`);

  const results: AnalyzerResult[] = [];
  for (const analyzer of analyzers) {
    console.log(`  Running: ${analyzer.name}...`);
    const result = await analyzer.run(repoPath);
    results.push(result);
    console.log(`  ${analyzer.name}: score ${result.score}/100 (${result.findings.length} findings)`);
  }

  if (outputPath) {
    const html = renderReport(results);
    writeFileSync(outputPath, html);
    console.log(`\nReport written to ${outputPath}`);
  } else {
    // Terminal output mode
    console.log("\n--- Results ---\n");
    for (const result of results) {
      console.log(`${result.analyzer}: ${result.score}/100`);
      for (const f of result.findings) {
        console.log(`  [${f.severity}] ${f.file}${f.line ? `:${f.line}` : ""} — ${f.message}`);
      }
    }
  }
}

// Only run main when executed directly (not imported for testing)
if (import.meta.main) {
  main().catch((err) => {
    console.error(err);
    process.exit(1);
  });
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
bun test test/cli.test.ts
```

Expected: PASS

- [ ] **Step 5: Verify the CLI works end-to-end**

```bash
bun run doctor .
bun run doctor . --analyzer file-count
```

Expected: terminal output showing file-count results

- [ ] **Step 6: Commit**

```bash
git add src/cli.ts test/cli.test.ts
git commit -m "feat: add CLI with auto-discovery and single-analyzer mode"
```

---

### Task 6: Create the test fixtures (unhealthy-repo)

**Files:**
- Create: `repo-doctor-ts/test-fixtures/unhealthy-repo/` (entire directory)

- [ ] **Step 1: Create the unhealthy-repo as a git repo with history**

```bash
mkdir -p test-fixtures/unhealthy-repo
cd test-fixtures/unhealthy-repo
git init
```

- [ ] **Step 2: Create package.json with outdated deps**

Create `test-fixtures/unhealthy-repo/package.json`:

```json
{
  "name": "unhealthy-app",
  "version": "1.0.0",
  "scripts": {
    "start": "node src/index.ts",
    "build": "tsc",
    "phantom-script": "echo this script references a file that doesnt exist"
  },
  "dependencies": {
    "lodash": "4.17.15",
    "express": "4.17.1",
    "moment": "2.29.1"
  },
  "devDependencies": {
    "typescript": "4.5.0"
  }
}
```

- [ ] **Step 3: Create source files with known issues**

Create `test-fixtures/unhealthy-repo/src/index.ts`:
```typescript
import { greet } from "./active-module";
console.log(greet("world"));
```

Create `test-fixtures/unhealthy-repo/src/active-module.ts`:
```typescript
export function greet(name: string): string {
  return `Hello, ${name}!`;
}
```

Create `test-fixtures/unhealthy-repo/src/dead-module.ts`:
```typescript
// This module is never imported by anything
export function unusedFunction(): void {
  console.log("I am never called");
}

export function anotherUnusedFunction(): string {
  return "also unused";
}
```

Create `test-fixtures/unhealthy-repo/src/utils.ts`:
```typescript
// TODO: refactor this function to be more efficient
export function slowSort(arr: number[]): number[] {
  // FIXME: this is O(n^2), should use a better algorithm
  for (let i = 0; i < arr.length; i++) {
    for (let j = i + 1; j < arr.length; j++) {
      if (arr[i] > arr[j]) {
        [arr[i], arr[j]] = [arr[j], arr[i]];
      }
    }
  }
  return arr;
}

// HACK: temporary workaround for date parsing bug
export function parseDate(str: string): Date {
  return new Date(str);
}

// XXX: this needs proper error handling
export function divide(a: number, b: number): number {
  return a / b;
}
```

- [ ] **Step 4: Create test files (with intentional gaps)**

Create `test-fixtures/unhealthy-repo/tests/active-module.test.ts`:
```typescript
import { greet } from "../src/active-module";
// Basic test for active-module
console.assert(greet("world") === "Hello, world!");
```

Note: `utils.test.ts` is intentionally missing — this is what the Test Coverage Analyzer should flag.

- [ ] **Step 5: Create README with broken links and conflict markers**

Create `test-fixtures/unhealthy-repo/README.md`:
```markdown
# Unhealthy App

A sample app for testing repo-doctor.

## Docs

- [Architecture](./docs/architecture.md)
- [Contributing](./CONTRIBUTING.md)
- [API Reference](./docs/api.md)

## Getting Started

See [setup guide](./docs/setup.md) for details.

<<<<<<< HEAD
Old version of the readme
=======
New version of the readme
>>>>>>> feature-branch
```

All those doc links point to files that don't exist. The conflict markers are for the stretch git-health analyzer.

- [ ] **Step 5b: Create .env with fake secrets**

Create `test-fixtures/unhealthy-repo/.env`:
```
DATABASE_URL=postgres://localhost/myapp
SECRET_KEY=super_secret_key_12345
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
```

This is for the stretch security-scanner analyzer.

- [ ] **Step 6: Commit the fixture repo with git history**

```bash
cd test-fixtures/unhealthy-repo
git add -A
git commit -m "Initial commit: unhealthy app with known issues" --date="2024-06-15T10:00:00"
cd ../..
```

The old commit date ensures git blame shows aged TODO comments.

- [ ] **Step 7: Commit the fixtures to the main repo**

```bash
git add test-fixtures/
git commit -m "feat: add unhealthy-repo test fixtures with known issues"
```

---

### Task 7: Write CLAUDE.md

**Files:**
- Create: `repo-doctor-ts/CLAUDE.md`

- [ ] **Step 1: Write CLAUDE.md**

Create `repo-doctor-ts/CLAUDE.md`:

```markdown
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
```

- [ ] **Step 2: Commit**

```bash
git add CLAUDE.md
git commit -m "feat: add CLAUDE.md with project conventions for AI agents"
```

---

### Task 8: Write EPIC.md

**Files:**
- Create: `repo-doctor-ts/EPIC.md`

- [ ] **Step 1: Write EPIC.md**

Create `repo-doctor-ts/EPIC.md` with the full epic. For each of the 8 analyzers, include:

- Name and description
- What it reads (input files/data)
- What it checks
- Output shape: `{ analyzer: string, findings: Finding[], score: number }`
- Acceptance criteria
- Difficulty estimate (for prioritising parallel work)
- Independence note: "This analyzer is independent — it can be built in its own worktree alongside any other analyzer"

**Core Analyzers (implement these first):**

1. **dependency-staleness** — Reads package.json + lock file. Checks for outdated deps. Score = % up-to-date. Difficulty: Medium. Start this one early — it needs to shell out to `bun outdated` or parse the lock file.

2. **dead-code** — Reads all .ts files in src/. Builds an import graph. Flags files never imported. Score = % of files that are alive. Difficulty: Medium-Hard. Start early.

3. **todo-debt** — Reads all source files + runs `git blame`. Finds TODO/FIXME/HACK/XXX comments. Enriches with age from blame. Score = inverse of volume weighted by age. Difficulty: Easy-Medium.

4. **test-coverage** — Reads src/ and tests/ directories. Maps test files to source files by naming convention. Flags uncovered source files. Score = % covered. Difficulty: Easy.

5. **doc-health** — Reads all .md files. Checks relative links resolve to real files. Checks README exists. Checks package.json scripts have corresponding files. Score = % of checks passing. Difficulty: Easy-Medium.

**Stretch Analyzers (bonus):**

6. **security-scanner** — Scans for hardcoded secrets via regex. Checks .gitignore coverage. Difficulty: Medium.

7. **complexity** — Measures file line counts, function counts. Flags outliers. Difficulty: Easy-Medium.

8. **git-health** — Analyzes commit frequency, stale branches, large files in history, conflict markers. Difficulty: Medium.

Each analyzer entry should include a code skeleton showing the class structure participants will implement.

- [ ] **Step 2: Commit**

```bash
git add EPIC.md
git commit -m "feat: add EPIC.md with all 8 analyzer specs for workshop"
```

---

### Task 9: Write README.md and verify end-to-end

**Files:**
- Create: `repo-doctor-ts/README.md`

- [ ] **Step 1: Write README.md**

Short README covering:
- What this is (workshop repo)
- Prerequisites (Bun, Claude Code)
- Quick start (`bun install`, `bun run doctor test-fixtures/unhealthy-repo/`)
- Workshop instructions (read EPIC.md, use `claude --worktree` per analyzer)

- [ ] **Step 2: Run full end-to-end test**

```bash
bun test
bun run doctor test-fixtures/unhealthy-repo/
bun run doctor test-fixtures/unhealthy-repo/ --output /tmp/test-report.html
open /tmp/test-report.html
bun run doctor test-fixtures/unhealthy-repo/ --analyzer file-count
```

Verify:
- All tests pass
- Terminal output shows file-count results
- HTML report opens in browser with styled report card
- Single-analyzer mode works

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "feat: add README with workshop quick start"
```

---

## Chunk 2: Ruby Skeleton

### Task 10: Initialise the Ruby project

**Files:**
- Create: `repo-doctor-ruby/Gemfile`
- Create: `repo-doctor-ruby/.gitignore`
- Create: `repo-doctor-ruby/bin/repo-doctor`

- [ ] **Step 1: Create project structure**

```bash
mkdir -p repo-doctor-ruby/{lib/analyzers,lib/renderer,bin,spec/analyzers,spec/renderer,test-fixtures}
cd repo-doctor-ruby
```

- [ ] **Step 2: Create Gemfile**

```ruby
source "https://rubygems.org"

gem "rspec", "~> 3.13", group: :test
```

- [ ] **Step 3: Create .gitignore**

```
vendor/
.bundle/
```

- [ ] **Step 4: Create executable entry point**

Create `repo-doctor-ruby/bin/repo-doctor`:

```ruby
#!/usr/bin/env ruby
require_relative "../lib/cli"
RepoDoctorCLI.run(ARGV)
```

```bash
chmod +x bin/repo-doctor
```

- [ ] **Step 5: Create .rspec and spec_helper.rb**

Create `repo-doctor-ruby/.rspec`:
```
--format documentation
--color
--require spec_helper
```

Create `repo-doctor-ruby/spec/spec_helper.rb`:
```ruby
RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end
end
```

- [ ] **Step 6: Install and commit**

```bash
bundle install
git init
git add Gemfile Gemfile.lock .gitignore .rspec bin/repo-doctor spec/spec_helper.rb
git commit -m "feat: initialise Ruby project with Bundler and RSpec"
```

---

### Task 11: Define types and base analyzer (Ruby)

**Files:**
- Create: `repo-doctor-ruby/lib/types.rb`
- Create: `repo-doctor-ruby/lib/analyzers/base.rb`

- [ ] **Step 1: Write the spec**

Create `repo-doctor-ruby/spec/types_spec.rb`:

```ruby
require_relative "../lib/types"

RSpec.describe Finding do
  it "has required attributes" do
    finding = Finding.new(file: "src/index.rb", message: "Unused", severity: :warning)
    expect(finding.file).to eq("src/index.rb")
    expect(finding.severity).to eq(:warning)
  end
end

RSpec.describe AnalyzerResult do
  it "has required attributes" do
    result = AnalyzerResult.new(analyzer: "test", findings: [], score: 85)
    expect(result.score).to be_between(0, 100)
  end
end
```

- [ ] **Step 2: Run spec to verify it fails**

```bash
bundle exec rspec spec/types_spec.rb
```

Expected: FAIL

- [ ] **Step 3: Implement types.rb**

Create `repo-doctor-ruby/lib/types.rb`:

```ruby
Finding = Struct.new(:file, :message, :severity, :line, keyword_init: true) do
  def initialize(file:, message:, severity: :warning, line: nil)
    super(file: file, message: message, severity: severity, line: line)
  end
end

AnalyzerResult = Struct.new(:analyzer, :findings, :score, keyword_init: true)
```

- [ ] **Step 4: Implement base.rb**

Create `repo-doctor-ruby/lib/analyzers/base.rb`:

```ruby
require_relative "../types"

class BaseAnalyzer
  def name
    raise NotImplementedError
  end

  def description
    raise NotImplementedError
  end

  def run(repo_path)
    raise NotImplementedError
  end

  private

  def finding(file:, message:, severity: :warning, line: nil)
    Finding.new(file: file, message: message, severity: severity, line: line)
  end

  def result(findings:, score:)
    clamped = [[score, 0].max, 100].min
    AnalyzerResult.new(analyzer: name, findings: findings, score: clamped)
  end
end
```

- [ ] **Step 5: Run spec to verify it passes**

```bash
bundle exec rspec spec/types_spec.rb
```

Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/types.rb lib/analyzers/base.rb spec/types_spec.rb
git commit -m "feat: add types and base analyzer class"
```

---

### Task 12: Build the sample analyzer (Ruby)

**Files:**
- Create: `repo-doctor-ruby/lib/analyzers/file_count.rb`
- Create: `repo-doctor-ruby/spec/analyzers/file_count_spec.rb`

- [ ] **Step 1: Write the spec**

Create `repo-doctor-ruby/spec/analyzers/file_count_spec.rb`:

```ruby
require_relative "../../lib/analyzers/file_count"

RSpec.describe FileCountAnalyzer do
  subject { described_class.new }

  it "has correct name" do
    expect(subject.name).to eq("file-count")
  end

  it "returns findings and score" do
    result = subject.run(Dir.pwd)
    expect(result.analyzer).to eq("file-count")
    expect(result.score).to be_between(0, 100)
    expect(result.findings).to be_an(Array)
  end
end
```

- [ ] **Step 2: Run to verify it fails**

```bash
bundle exec rspec spec/analyzers/file_count_spec.rb
```

- [ ] **Step 3: Implement file_count.rb**

Create `repo-doctor-ruby/lib/analyzers/file_count.rb`:

```ruby
require_relative "base"

class FileCountAnalyzer < BaseAnalyzer
  def name = "file-count"
  def description = "Counts files by type and flags repos with high file count"

  def run(repo_path)
    counts = Hash.new(0)
    total = 0

    walk(repo_path) do |path|
      total += 1
      ext = File.extname(path).empty? ? "(no extension)" : File.extname(path)
      counts[ext] += 1
    end

    findings = counts.sort_by { |_, v| -v }.map do |ext, count|
      finding(file: repo_path, message: "#{ext}: #{count} files", severity: :info)
    end

    score = [0, (100 - (total.to_f / 5000 * 100)).round].max
    result(findings: findings, score: score)
  end

  private

  def walk(dir, &block)
    Dir.children(dir).each do |entry|
      next if entry.start_with?(".") || entry == "node_modules" || entry == "vendor"
      full_path = File.join(dir, entry)
      if File.directory?(full_path)
        walk(full_path, &block)
      else
        yield full_path
      end
    end
  end
end
```

- [ ] **Step 4: Run to verify it passes**

```bash
bundle exec rspec spec/analyzers/file_count_spec.rb
```

- [ ] **Step 5: Commit**

```bash
git add lib/analyzers/file_count.rb spec/analyzers/file_count_spec.rb
git commit -m "feat: add file-count sample analyzer"
```

---

### Task 13: Build the HTML renderer (Ruby)

**Files:**
- Create: `repo-doctor-ruby/lib/renderer/html.rb`
- Create: `repo-doctor-ruby/lib/renderer/template.html` (can reuse/adapt from TS track)
- Create: `repo-doctor-ruby/spec/renderer/html_spec.rb`

- [ ] **Step 1: Write the spec**

Create `repo-doctor-ruby/spec/renderer/html_spec.rb`:

```ruby
require_relative "../../lib/renderer/html"
require_relative "../../lib/types"

RSpec.describe ReportRenderer do
  describe ".render" do
    it "produces valid HTML with analyzer results" do
      results = [
        AnalyzerResult.new(
          analyzer: "test-analyzer",
          findings: [Finding.new(file: "src/index.rb", message: "Test finding", severity: :warning)],
          score: 75
        )
      ]
      html = described_class.render(results)
      expect(html).to include("<!DOCTYPE html>")
      expect(html).to include("test-analyzer")
      expect(html).to include("75")
      expect(html).to include("Test finding")
    end

    it "handles empty results" do
      html = described_class.render([])
      expect(html).to include("No analyzers ran")
    end
  end
end
```

- [ ] **Step 2: Run to verify it fails**

```bash
bundle exec rspec spec/renderer/html_spec.rb
```

- [ ] **Step 3: Implement html.rb**

Create `repo-doctor-ruby/lib/renderer/html.rb`:

```ruby
require_relative "../types"

class ReportRenderer
  TEMPLATE_PATH = File.join(__dir__, "template.html")

  GRADE_THRESHOLDS = { 90 => ["A", "grade-a"], 80 => ["B", "grade-b"], 70 => ["C", "grade-c"], 60 => ["D", "grade-d"] }.freeze

  def self.render(results)
    template = File.read(TEMPLATE_PATH)

    if results.empty?
      return template
        .sub("{{TITLE}}", "Repo Doctor Report")
        .sub("{{OVERALL_SCORE}}", "N/A")
        .sub("{{ANALYZERS}}", "<p>No analyzers ran</p>")
        .sub("{{TIMESTAMP}}", Time.now.iso8601)
    end

    overall = (results.sum(&:score).to_f / results.length).round
    letter, css = grade_for(overall)

    template
      .sub("{{TITLE}}", "Repo Doctor Report")
      .sub("{{OVERALL_SCORE}}", "<span class=\"#{css}\">#{letter} (#{overall})</span>")
      .sub("{{ANALYZERS}}", results.map { |r| render_analyzer(r) }.join("\n"))
      .sub("{{TIMESTAMP}}", Time.now.iso8601)
  end

  def self.grade_for(score)
    GRADE_THRESHOLDS.each { |threshold, val| return val if score >= threshold }
    ["F", "grade-f"]
  end

  def self.render_analyzer(result)
    letter, css = grade_for(result.score)
    findings_html = if result.findings.empty?
      '<p class="no-findings">No issues found</p>'
    else
      items = result.findings.map do |f|
        line_str = f.line ? ":#{f.line}" : ""
        "<li><span class=\"severity #{f.severity}\">#{f.severity}</span>" \
        "<span class=\"file\">#{f.file}#{line_str}</span>" \
        "<span class=\"message\">#{f.message}</span></li>"
      end.join
      "<ul class=\"findings\">#{items}</ul>"
    end

    <<~HTML
      <section class="analyzer">
        <div class="analyzer-header" onclick="this.parentElement.classList.toggle('expanded')">
          <span class="analyzer-name">#{result.analyzer}</span>
          <span class="score #{css}">#{letter} (#{result.score})</span>
        </div>
        <div class="analyzer-body">#{findings_html}</div>
      </section>
    HTML
  end

  private_class_method :grade_for, :render_analyzer
end
```

- [ ] **Step 4: Copy template.html from TypeScript track**

Copy `repo-doctor-ts/src/renderer/template.html` to `repo-doctor-ruby/lib/renderer/template.html`. The template is pure HTML/CSS with no language-specific content — identical file.

- [ ] **Step 5: Run to verify it passes**

```bash
bundle exec rspec spec/renderer/html_spec.rb
```

- [ ] **Step 6: Commit**

```bash
git add lib/renderer/html.rb lib/renderer/template.html spec/renderer/html_spec.rb
git commit -m "feat: add HTML report renderer"
```

---

### Task 14: Build the CLI with auto-discovery (Ruby)

**Files:**
- Create: `repo-doctor-ruby/lib/cli.rb`
- Create: `repo-doctor-ruby/spec/cli_spec.rb`

- [ ] **Step 1: Write the spec**

Create `repo-doctor-ruby/spec/cli_spec.rb`:

```ruby
require_relative "../lib/cli"

RSpec.describe RepoDoctorCLI do
  describe ".discover_analyzers" do
    it "finds the file-count analyzer" do
      analyzers = described_class.discover_analyzers
      names = analyzers.map(&:name)
      expect(names).to include("file-count")
    end

    it "does not include base as an analyzer" do
      analyzers = described_class.discover_analyzers
      names = analyzers.map(&:name)
      expect(names).not_to include("base")
    end
  end
end
```

- [ ] **Step 2: Run to verify it fails**

```bash
bundle exec rspec spec/cli_spec.rb
```

- [ ] **Step 3: Implement cli.rb**

Create `repo-doctor-ruby/lib/cli.rb`:

```ruby
require_relative "types"
require_relative "renderer/html"

class RepoDoctorCLI
  ANALYZERS_DIR = File.join(__dir__, "analyzers")

  def self.discover_analyzers
    Dir.glob(File.join(ANALYZERS_DIR, "*.rb")).filter_map do |file|
      next if File.basename(file) == "base.rb"
      require file
      # Find the analyzer class defined in this file
      basename = File.basename(file, ".rb")
      class_name = basename.split("_").map(&:capitalize).join + "Analyzer"
      klass = Object.const_get(class_name) rescue nil
      klass&.new
    end
  end

  def self.run(args)
    if args.empty? || args.include?("--help")
      puts "Usage: repo-doctor <repo-path> [--output report.html] [--analyzer <name>]"
      exit(args.include?("--help") ? 0 : 1)
    end

    repo_path = args[0]
    output_idx = args.index("--output")
    output_path = output_idx ? args[output_idx + 1] : nil
    analyzer_idx = args.index("--analyzer")
    analyzer_filter = analyzer_idx ? args[analyzer_idx + 1] : nil

    analyzers = discover_analyzers

    if analyzer_filter
      analyzers = analyzers.select { |a| a.name == analyzer_filter }
      if analyzers.empty?
        $stderr.puts "Unknown analyzer: #{analyzer_filter}"
        exit 1
      end
    end

    puts "Running #{analyzers.length} analyzer(s) against #{repo_path}...\n\n"

    results = analyzers.map do |analyzer|
      puts "  Running: #{analyzer.name}..."
      result = analyzer.run(repo_path)
      puts "  #{analyzer.name}: score #{result.score}/100 (#{result.findings.length} findings)"
      result
    end

    if output_path
      html = ReportRenderer.render(results)
      File.write(output_path, html)
      puts "\nReport written to #{output_path}"
    else
      puts "\n--- Results ---\n\n"
      results.each do |r|
        puts "#{r.analyzer}: #{r.score}/100"
        r.findings.each do |f|
          line_str = f.line ? ":#{f.line}" : ""
          puts "  [#{f.severity}] #{f.file}#{line_str} — #{f.message}"
        end
      end
    end
  end
end
```

- [ ] **Step 4: Run to verify it passes**

```bash
bundle exec rspec spec/cli_spec.rb
```

- [ ] **Step 5: Commit**

```bash
git add lib/cli.rb spec/cli_spec.rb
git commit -m "feat: add CLI with auto-discovery and single-analyzer mode"
```

---

### Task 15: Create Ruby test fixtures (unhealthy-repo-ruby)

**Files:**
- Create: `repo-doctor-ruby/test-fixtures/unhealthy-repo-ruby/` (entire directory)

- [ ] **Step 1: Create the fixture directory and init git**

```bash
mkdir -p test-fixtures/unhealthy-repo-ruby/{lib,spec}
cd test-fixtures/unhealthy-repo-ruby
git init
```

- [ ] **Step 2: Create Gemfile with outdated gems**

Create `test-fixtures/unhealthy-repo-ruby/Gemfile`:

```ruby
source "https://rubygems.org"

gem "rails", "6.0.0"
gem "nokogiri", "1.12.0"
gem "puma", "5.0.0"
gem "pg", "1.2.0"
```

- [ ] **Step 3: Create source files with known issues**

Create `test-fixtures/unhealthy-repo-ruby/lib/main.rb`:
```ruby
require_relative "active_module"
puts ActiveModule.greet("world")
```

Create `test-fixtures/unhealthy-repo-ruby/lib/active_module.rb`:
```ruby
module ActiveModule
  def self.greet(name)
    "Hello, #{name}!"
  end
end
```

Create `test-fixtures/unhealthy-repo-ruby/lib/dead_module.rb`:
```ruby
# This module is never required by anything
module DeadModule
  def self.unused_method
    "I am never called"
  end

  def self.another_unused_method
    "also unused"
  end
end
```

Create `test-fixtures/unhealthy-repo-ruby/lib/utils.rb`:
```ruby
# TODO: refactor this method to be more efficient
def slow_sort(arr)
  # FIXME: this is O(n^2), should use a better algorithm
  arr.each_index do |i|
    ((i + 1)...arr.length).each do |j|
      arr[i], arr[j] = arr[j], arr[i] if arr[i] > arr[j]
    end
  end
  arr
end

# HACK: temporary workaround for date parsing bug
def parse_date(str)
  Date.parse(str)
end

# XXX: this needs proper error handling
def divide(a, b)
  a / b
end
```

- [ ] **Step 4: Create spec files (with intentional gaps)**

Create `test-fixtures/unhealthy-repo-ruby/spec/active_module_spec.rb`:
```ruby
require_relative "../lib/active_module"
RSpec.describe ActiveModule do
  it "greets" do
    expect(ActiveModule.greet("world")).to eq("Hello, world!")
  end
end
```

Note: `utils_spec.rb` is intentionally missing.

- [ ] **Step 5: Create README with broken links and .env with fake secret**

Create `test-fixtures/unhealthy-repo-ruby/README.md`:
```markdown
# Unhealthy Ruby App

A sample app for testing repo-doctor.

## Docs

- [Architecture](./docs/architecture.md)
- [Contributing](./CONTRIBUTING.md)
- [API Reference](./docs/api.md)

## Getting Started

See [setup guide](./docs/setup.md) for details.

<<<<<<< HEAD
Old version of the readme
=======
New version of the readme
>>>>>>> feature-branch
```

Create `test-fixtures/unhealthy-repo-ruby/.env`:
```
DATABASE_URL=postgres://localhost/myapp
SECRET_KEY_BASE=fake_secret_key_12345
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
```

- [ ] **Step 6: Commit fixture with old date**

```bash
cd test-fixtures/unhealthy-repo-ruby
git add -A
git commit -m "Initial commit: unhealthy ruby app" --date="2024-06-15T10:00:00"
cd ../..
```

- [ ] **Step 7: Commit to main repo**

```bash
git add test-fixtures/
git commit -m "feat: add unhealthy-repo-ruby test fixtures"
```

---

### Task 16: Write Ruby CLAUDE.md

**Files:**
- Create: `repo-doctor-ruby/CLAUDE.md`

- [ ] **Step 1: Write CLAUDE.md**

Create `repo-doctor-ruby/CLAUDE.md`:

```markdown
# Repo Doctor

A CLI tool that analyzes git repositories and produces HTML health reports.

## Quick Reference

\`\`\`bash
bundle exec bin/repo-doctor <repo-path>                          # Run all analyzers, terminal output
bundle exec bin/repo-doctor <repo-path> --output report.html     # Generate HTML report
bundle exec bin/repo-doctor <repo-path> --analyzer <name>        # Run single analyzer
bundle exec rspec                                                 # Run tests
\`\`\`

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

\`\`\`ruby
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
\`\`\`

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

\`\`\`
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
\`\`\`
```

- [ ] **Step 2: Commit**

```bash
git add CLAUDE.md
git commit -m "feat: add CLAUDE.md with project conventions for AI agents"
```

---

### Task 17: Write Ruby EPIC.md and README.md

**Files:**
- Create: `repo-doctor-ruby/EPIC.md`
- Create: `repo-doctor-ruby/README.md`

- [ ] **Step 1: Write EPIC.md**

Create `repo-doctor-ruby/EPIC.md`. This is the same content as the TypeScript EPIC.md (Task 8) but with Ruby code skeletons. For each analyzer, replace the TypeScript class skeleton with a Ruby equivalent:

```ruby
# Example skeleton for each analyzer entry in EPIC.md:
require_relative "base"

class DependencyStalenessAnalyzer < BaseAnalyzer
  def name = "dependency-staleness"
  def description = "Checks for outdated dependencies"

  def run(repo_path)
    findings = []
    # YOUR IMPLEMENTATION HERE
    # Read Gemfile, check versions, compare against latest
    score = 100
    result(findings: findings, score: score)
  end
end
```

Include the same 8 analyzers with the same descriptions, inputs, outputs, acceptance criteria, and difficulty estimates as the TS EPIC.md. The only differences are:
- Ruby class syntax instead of TypeScript
- `Gemfile` instead of `package.json`
- `lib/` instead of `src/`
- `spec/` instead of `tests/`
- `:info`/`:warning`/`:error` symbols instead of string literals
- `Open3.capture2("git ...")` instead of `execSync("git ...")`

- [ ] **Step 2: Write README.md**

Create `repo-doctor-ruby/README.md`:

```markdown
# Repo Doctor (Ruby)

Workshop repo for the AI Parallel Workflows workshop. Build health analyzers using parallel Claude Code sessions with git worktrees.

## Prerequisites

- Ruby 3.2+
- Bundler
- Claude Code (v2.1.32+)
- Git

## Quick Start

\`\`\`bash
git clone <repo-url>
cd repo-doctor-ruby
bundle install
bundle exec bin/repo-doctor test-fixtures/unhealthy-repo-ruby/
\`\`\`

## Workshop Instructions

1. Read `EPIC.md` for the full list of analyzers to implement
2. Open multiple terminal tabs
3. In each tab, run `claude --worktree` and assign it an analyzer from the epic
4. Monitor progress, review completed work
5. Merge worktree branches back to main
6. Run `bundle exec bin/repo-doctor test-fixtures/unhealthy-repo-ruby/ --output report.html`
7. Open `report.html` and admire your work
```

- [ ] **Step 3: Verify end-to-end**

```bash
bundle exec rspec
bundle exec bin/repo-doctor test-fixtures/unhealthy-repo-ruby/
bundle exec bin/repo-doctor test-fixtures/unhealthy-repo-ruby/ --output /tmp/test-report.html
open /tmp/test-report.html
bundle exec bin/repo-doctor test-fixtures/unhealthy-repo-ruby/ --analyzer file-count
```

- [ ] **Step 4: Commit**

```bash
git add EPIC.md README.md
git commit -m "feat: add EPIC.md and README with workshop instructions"
```

---

### Task 18: Create the solutions branch (TypeScript)

**Files:**
- Create: `repo-doctor-ts/src/analyzers/dependency-staleness.ts`
- Create: `repo-doctor-ts/src/analyzers/dead-code.ts`
- Create: `repo-doctor-ts/src/analyzers/todo-debt.ts`
- Create: `repo-doctor-ts/src/analyzers/test-coverage.ts`
- Create: `repo-doctor-ts/src/analyzers/doc-health.ts`
- Create: `repo-doctor-ts/src/analyzers/security-scanner.ts`
- Create: `repo-doctor-ts/src/analyzers/complexity.ts`
- Create: `repo-doctor-ts/src/analyzers/git-health.ts`
- Create: corresponding test files in `test/analyzers/`

- [ ] **Step 1: Create solutions branch**

```bash
cd repo-doctor-ts
git checkout -b solutions
```

- [ ] **Step 2: Implement and commit dependency-staleness analyzer**

Create `src/analyzers/dependency-staleness.ts` — reads `package.json`, parses pinned versions, flags deps with major versions behind. Create corresponding test. Commit:

```bash
git add src/analyzers/dependency-staleness.ts test/analyzers/dependency-staleness.test.ts
git commit -m "solution: dependency-staleness analyzer"
```

- [ ] **Step 3: Implement and commit dead-code analyzer**

Create `src/analyzers/dead-code.ts` — scans all `.ts` files in `src/`, builds import graph via regex, flags files never imported. Commit:

```bash
git add src/analyzers/dead-code.ts test/analyzers/dead-code.test.ts
git commit -m "solution: dead-code analyzer"
```

- [ ] **Step 4: Implement and commit todo-debt analyzer**

Create `src/analyzers/todo-debt.ts` — greps for TODO/FIXME/HACK/XXX, runs `git blame` per file, enriches with age. Commit:

```bash
git add src/analyzers/todo-debt.ts test/analyzers/todo-debt.test.ts
git commit -m "solution: todo-debt analyzer"
```

- [ ] **Step 5: Implement and commit test-coverage analyzer**

Create `src/analyzers/test-coverage.ts` — maps `tests/*.test.ts` to `src/*.ts` by naming convention, flags uncovered. Commit:

```bash
git add src/analyzers/test-coverage.ts test/analyzers/test-coverage.test.ts
git commit -m "solution: test-coverage analyzer"
```

- [ ] **Step 6: Implement and commit doc-health analyzer**

Create `src/analyzers/doc-health.ts` — parses markdown links, checks they resolve, checks README exists, checks package.json scripts. Commit:

```bash
git add src/analyzers/doc-health.ts test/analyzers/doc-health.test.ts
git commit -m "solution: doc-health analyzer"
```

- [ ] **Step 7: Implement and commit security-scanner analyzer**

Create `src/analyzers/security-scanner.ts` — regex for API keys/secrets, checks for .env files, checks .gitignore. Commit:

```bash
git add src/analyzers/security-scanner.ts test/analyzers/security-scanner.test.ts
git commit -m "solution: security-scanner analyzer"
```

- [ ] **Step 8: Implement and commit complexity analyzer**

Create `src/analyzers/complexity.ts` — measures line counts, function counts per file, flags outliers. Commit:

```bash
git add src/analyzers/complexity.ts test/analyzers/complexity.test.ts
git commit -m "solution: complexity analyzer"
```

- [ ] **Step 9: Implement and commit git-health analyzer**

Create `src/analyzers/git-health.ts` — checks stale branches, large files in history, conflict markers. Commit:

```bash
git add src/analyzers/git-health.ts test/analyzers/git-health.test.ts
git commit -m "solution: git-health analyzer"
```

- [ ] **Step 10: Switch back to main**

```bash
git checkout main
```

---

### Task 19: Create the solutions branch (Ruby)

**Files:**
- Create: `repo-doctor-ruby/lib/analyzers/dependency_staleness.rb` (and 7 more)
- Create: corresponding spec files in `spec/analyzers/`

- [ ] **Step 1: Create solutions branch**

```bash
cd repo-doctor-ruby
git checkout -b solutions
```

- [ ] **Step 2: Implement and commit each analyzer (one commit per analyzer)**

For each of the 8 analyzers, create the Ruby equivalent following the same pattern as the TS solutions. File naming convention: `snake_case.rb` with class `CamelCaseAnalyzer`.

| File | Class | Commit message |
|------|-------|----------------|
| `lib/analyzers/dependency_staleness.rb` | `DependencyStalenessAnalyzer` | `solution: dependency-staleness analyzer` |
| `lib/analyzers/dead_code.rb` | `DeadCodeAnalyzer` | `solution: dead-code analyzer` |
| `lib/analyzers/todo_debt.rb` | `TodoDebtAnalyzer` | `solution: todo-debt analyzer` |
| `lib/analyzers/test_coverage.rb` | `TestCoverageAnalyzer` | `solution: test-coverage analyzer` |
| `lib/analyzers/doc_health.rb` | `DocHealthAnalyzer` | `solution: doc-health analyzer` |
| `lib/analyzers/security_scanner.rb` | `SecurityScannerAnalyzer` | `solution: security-scanner analyzer` |
| `lib/analyzers/complexity.rb` | `ComplexityAnalyzer` | `solution: complexity analyzer` |
| `lib/analyzers/git_health.rb` | `GitHealthAnalyzer` | `solution: git-health analyzer` |

Each analyzer should:
- Extend `BaseAnalyzer`
- Use only Ruby stdlib + `Open3` for git commands
- Include a corresponding `spec/analyzers/<name>_spec.rb`
- Be committed independently for cherry-pick support

- [ ] **Step 3: Switch back to main**

```bash
git checkout main
```

- [ ] **Step 4: Verify solutions branches exist in both repos**

```bash
cd repo-doctor-ts && git branch | grep solutions
cd ../repo-doctor-ruby && git branch | grep solutions
```
