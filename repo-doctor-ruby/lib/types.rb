Finding = Struct.new(:file, :message, :severity, :line, keyword_init: true) do
  def initialize(file:, message:, severity: :warning, line: nil)
    super(file: file, message: message, severity: severity, line: line)
  end
end

AnalyzerResult = Struct.new(:analyzer, :findings, :score, keyword_init: true)
