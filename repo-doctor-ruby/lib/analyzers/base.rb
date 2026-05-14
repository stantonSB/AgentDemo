require_relative "../types"

class BaseAnalyzer
  def name
    raise NotImplementedError
  end

  def description
    raise NotImplementedError
  end

  def run(repo_path)
    raise NotImplementedError
  end

  private

  def finding(file:, message:, severity: :warning, line: nil)
    Finding.new(file: file, message: message, severity: severity, line: line)
  end

  def result(findings:, score:)
    clamped = [[score, 0].max, 100].min
    AnalyzerResult.new(analyzer: name, findings: findings, score: clamped)
  end
end
