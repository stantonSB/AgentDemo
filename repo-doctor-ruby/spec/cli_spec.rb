require_relative "../lib/cli"

RSpec.describe RepoDoctorCLI do
  describe ".discover_analyzers" do
    it "finds the file-count analyzer" do
      analyzers = described_class.discover_analyzers
      names = analyzers.map(&:name)
      expect(names).to include("file-count")
    end

    it "does not include base as an analyzer" do
      analyzers = described_class.discover_analyzers
      names = analyzers.map(&:name)
      expect(names).not_to include("base")
    end
  end
end
