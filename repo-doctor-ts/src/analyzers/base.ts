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
