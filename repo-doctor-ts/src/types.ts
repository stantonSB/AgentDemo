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
