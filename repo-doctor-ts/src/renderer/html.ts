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
