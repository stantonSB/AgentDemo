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
    expect(html).toContain("grade-a");
    expect(html).toContain("grade-c");
    expect(html).toContain("grade-f");
  });
});
