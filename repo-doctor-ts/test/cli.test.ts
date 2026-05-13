import { describe, expect, test } from "bun:test";
import { discoverAnalyzers } from "../src/cli";

describe("CLI", () => {
  test("discovers analyzers from the analyzers directory", async () => {
    const analyzers = await discoverAnalyzers();
    expect(analyzers.length).toBeGreaterThanOrEqual(1);
    const names = analyzers.map((a) => a.name);
    expect(names).toContain("file-count");
  });

  test("does not discover base.ts as an analyzer", async () => {
    const analyzers = await discoverAnalyzers();
    const names = analyzers.map((a) => a.name);
    expect(names).not.toContain("base");
  });
});
