require 'rails_helper'

RSpec.describe CitationChallenge, type: :model do
  it_behaves_like "GithubSubmittable"

  describe "factory" do
    it "is valid" do
      citation_challenge = FactoryBot.create(:citation_challenge)
      expect(citation_challenge.hypothesis_citation).to be_present
      expect(citation_challenge.citation).to be_present
    end
    context "passed citation and hypothesis" do
      let(:hypothesis) { FactoryBot.create(:hypothesis) }
      let(:citation) { FactoryBot.create(:citation) }
      it "is valid" do
        citation_challenge = FactoryBot.create(:citation_challenge, hypothesis: hypothesis, citation: citation)
        expect(citation_challenge.hypothesis_citation).to be_present
        expect(citation_challenge.citation&.id).to eq citation.id
        expect(citation_challenge.hypothesis&.id).to eq hypothesis.id
      end
    end
  end
end
