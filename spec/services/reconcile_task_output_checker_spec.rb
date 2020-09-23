require "rails_helper"

RSpec.describe ReconcileTaskOutputChecker do
  let(:subject) { described_class }

  it "returns true" do
    expect(described_class.success?("\n\n\nEverything up-to-date \n")).to be_truthy
  end
  context "all up to date" do
    it "returns true" do
      expect(described_class.success?("already up to date ")).to be_truthy
      expect(described_class.success?("Already up to date.")).to be_truthy
      multiline = "HEAD is now at 4f6e4b1 remove duped citations again\nAlready up to date.\n[main 24fc419] reconciliation\n1 file changed, 3 deletions(-)"
      expect(described_class.success?(multiline)).to be_truthy
    end
  end
end
