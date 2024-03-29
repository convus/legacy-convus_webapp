require "rails_helper"

RSpec.describe AddToGithubContentJob do
  let(:subject) { described_class.new }
  context "citation" do
    let(:citation) { FactoryBot.create(:citation, creator: FactoryBot.create(:user)) }
    it "calls the github integration" do
      expect_any_instance_of(GithubIntegration).to receive(:create_citation_pull_request) { true }
      subject.perform("Citation", citation.id)
    end
    context "pull request present" do
      let!(:citation) { FactoryBot.create(:citation, pull_request_number: 332) }
      it "does nothing" do
        expect_any_instance_of(GithubIntegration).to_not receive(:client)
        subject.perform("Citation", citation.id)
      end
    end
  end
  context "explanation" do
    let(:explanation) { FactoryBot.create(:explanation, creator: FactoryBot.create(:user)) }
    it "calls the github integration" do
      expect_any_instance_of(GithubIntegration).to receive(:create_explanation_pull_request) { true }
      subject.perform("Explanation", explanation.id)
    end
    context "pull request present" do
      let!(:explanation) { FactoryBot.create(:explanation, pull_request_number: 332) }
      it "does nothing" do
        expect_any_instance_of(GithubIntegration).to_not receive(:client)
        subject.perform("Explanation", explanation.id)
      end
    end
  end
end
