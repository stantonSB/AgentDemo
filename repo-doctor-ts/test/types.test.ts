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
