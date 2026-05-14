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
    console.log("\n--- Results ---\n");
    for (const result of results) {
      console.log(`${result.analyzer}: ${result.score}/100`);
      for (const f of result.findings) {
        console.log(`  [${f.severity}] ${f.file}${f.line ? `:${f.line}` : ""} — ${f.message}`);
      }
    }
  }
}

if (import.meta.main) {
  main().catch((err) => {
    console.error(err);
    process.exit(1);
  });
}
