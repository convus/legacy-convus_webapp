
require "rails_helper"

RSpec.describe AddHypothesisToGithubContentJob do
  let(:subject) { described_class.new }
  let(:hypothesis) { FactoryBot.create(:hypothesis) }
  it "calls the github integration" do
    expect_any_instance_of(GithubIntegration).to receive(:create_hypothesis_pull_request) { true }
    subject.perform(hypothesis.id)
  end
  context "pull request present" do
    let!(:hypothesis) { FactoryBot.create(:hypothesis, pull_request_number: 332) }
    it "does nothing" do
      expect_any_instance_of(GithubIntegration).to_not receive(:client)
      subject.perform(hypothesis.id)
    end
  end
end
