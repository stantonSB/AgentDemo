require_relative "../../lib/renderer/html"
require_relative "../../lib/types"

RSpec.describe ReportRenderer do
  describe ".render" do
    it "produces valid HTML with analyzer results" do
      results = [
        AnalyzerResult.new(
          analyzer: "test-analyzer",
          findings: [Finding.new(file: "src/index.rb", message: "Test finding", severity: :warning)],
          score: 75
        )
      ]
      html = described_class.render(results)
      expect(html).to include("<!DOCTYPE html>")
      expect(html).to include("test-analyzer")
      expect(html).to include("75")
      expect(html).to include("Test finding")
    end

    it "handles empty results" do
      html = described_class.render([])
      expect(html).to include("No analyzers ran")
    end
  end
end
