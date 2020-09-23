require "rails_helper"

RSpec.describe ReconcileTaskOutputChecker do
  let(:subject) { described_class }

  it "returns true" do
    expect(described_class.success?("\n\n\nEverything up-to-date \n")).to be_truthy
  end
  context "all up to date" do
    it "returns true" do
      expect(described_class.success?("already up to date ")).to be_truthy
    end
  end
end
