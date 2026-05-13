require_relative "../lib/types"

RSpec.describe Finding do
  it "has required attributes" do
    finding = Finding.new(file: "src/index.rb", message: "Unused", severity: :warning)
    expect(finding.file).to eq("src/index.rb")
    expect(finding.severity).to eq(:warning)
  end
end

RSpec.describe AnalyzerResult do
  it "has required attributes" do
    result = AnalyzerResult.new(analyzer: "test", findings: [], score: 85)
    expect(result.score).to be_between(0, 100)
  end
end
