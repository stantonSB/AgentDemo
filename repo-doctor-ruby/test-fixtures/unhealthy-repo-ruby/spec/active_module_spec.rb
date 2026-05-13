require_relative "../lib/active_module"
RSpec.describe ActiveModule do
  it "greets" do
    expect(ActiveModule.greet("world")).to eq("Hello, world!")
  end
end
