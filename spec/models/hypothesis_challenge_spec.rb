require 'rails_helper'

RSpec.describe HypothesisChallenge, type: :model do
  describe "factory" do
    let(:hypothesis_challenge) { FactoryBot.create(:hypothesis_challenge) }
    it "is valid" do
      expect(hypothesis_challenge.hypothesis).to be_present
      expect(hypothesis_challenge.challenged_hypothesis).to be_present
      expect(hypothesis_challenge.challenged_explanation_quote).to be_blank
      expect(hypothesis_challenge.kind).to eq "challenge"
      expect(hypothesis_challenge).to be_valid
      hypothesis = hypothesis_challenge.hypothesis
      challenged_hypothesis = hypothesis_challenge.challenged_hypothesis
      expect(hypothesis.pluck(:id)).to eq([hypothesis_challenge.challenged_hypothesis_id])
      expect(challenged_hypothesis.challenges.pluck(:id)).to eq([hypothesis_challenge.hypothesis_id])
    end
    context "challenge_citation" do
      let(:hypothesis_challenge) { FactoryBot.create(:hypothesis_challenge_citation) }
      it "is valid" do
        expect(hypothesis_challenge.hypothesis).to be_present
        expect(hypothesis_challenge.challenged_hypothesis).to be_present
        expect(hypothesis_challenge.challenged_explanation_quote).to be_present
        expect(hypothesis_challenge.kind).to eq "challenge"
        expect(hypothesis_challenge).to be_valid
        hypothesis = hypothesis_challenge.hypothesis
        challenged_hypothesis = hypothesis_challenge.challenged_hypothesis
        expect(hypothesis.pluck(:id)).to eq([hypothesis_challenge.challenged_hypothesis_id])
        expect(challenged_hypothesis.challenges.pluck(:id)).to eq([hypothesis_challenge.hypothesis_id])
        (challenged_hypothesis.explanation_quotes.first.hypothesis_challenges.pluck(:id)).to eq([hypothesis_challenge.id])
      end
    end
    context "challenge_explanation_quote" do
      let(:hypothesis_challenge) { FactoryBot.create(:hypothesis_challenge_explanation_quote) }
      it "is valid" do
        expect(hypothesis_challenge.hypothesis).to be_present
        expect(hypothesis_challenge.challenged_hypothesis).to be_present
        expect(hypothesis_challenge.challenged_explanation_quote).to be_present
        expect(hypothesis_challenge.kind).to eq "challenge"
        expect(hypothesis_challenge).to be_valid
        hypothesis = hypothesis_challenge.hypothesis
        challenged_hypothesis = hypothesis_challenge.challenged_hypothesis
        expect(hypothesis.pluck(:id)).to eq([hypothesis_challenge.challenged_hypothesis_id])
        expect(challenged_hypothesis.challenges.pluck(:id)).to eq([hypothesis_challenge.hypothesis_id])
        (challenged_hypothesis.citations.first.hypothesis_challenges.pluck(:id)).to eq([hypothesis_challenge.id])
      end
    end
  end
end
