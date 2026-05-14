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
