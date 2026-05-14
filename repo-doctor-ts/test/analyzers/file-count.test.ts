import { describe, expect, test } from "bun:test";
import { FileCountAnalyzer } from "../../src/analyzers/file-count";

describe("FileCountAnalyzer", () => {
  test("has correct name", () => {
    const analyzer = new FileCountAnalyzer();
    expect(analyzer.name).toBe("file-count");
  });

  test("returns findings and score for a directory", async () => {
    const analyzer = new FileCountAnalyzer();
    const result = await analyzer.run(process.cwd());
    expect(result.analyzer).toBe("file-count");
    expect(result.score).toBeGreaterThanOrEqual(0);
    expect(result.score).toBeLessThanOrEqual(100);
    expect(Array.isArray(result.findings)).toBe(true);
  });
});
