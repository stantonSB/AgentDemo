require_relative "../../lib/analyzers/file_count"

RSpec.describe FileCountAnalyzer do
  subject { described_class.new }

  it "has correct name" do
    expect(subject.name).to eq("file-count")
  end

  it "returns findings and score" do
    result = subject.run(Dir.pwd)
    expect(result.analyzer).to eq("file-count")
    expect(result.score).to be_between(0, 100)
    expect(result.findings).to be_an(Array)
  end
end
