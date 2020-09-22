
require "rails_helper"

RSpec.describe AddCitationToGithubContentJob do
  let(:subject) { described_class.new }
  let(:citation) { FactoryBot.create(:citation, creator: FactoryBot.create(:user)) }
  it "calls the github integration" do
    expect_any_instance_of(GithubIntegration).to receive(:create_citation_pull_request) { true }
    subject.perform(citation.id)
  end
  context "pull request present" do
    let!(:citation) { FactoryBot.create(:citation, pull_request_number: 332) }
    it "does nothing" do
      expect_any_instance_of(GithubIntegration).to_not receive(:client)
      subject.perform(citation.id)
    end
  end
end
