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

    const score = Math.max(0, Math.round(100 - (totalFiles / 5000) * 100));
    return this.result(findings, score);
  }
}
