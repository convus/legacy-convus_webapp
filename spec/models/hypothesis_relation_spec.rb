require 'rails_helper'

RSpec.describe HypothesisRelation, type: :model do
  describe "factory" do
    let(:hypothesis_relation) { FactoryBot.create(:hypothesis_relation) }
    let(:hypothesis_earlier) { hypothesis_relation.hypothesis_earlier }
    let(:hypothesis_later) { hypothesis_relation.hypothesis_later }
    it "is valid" do
      expect(hypothesis_relation.hypothesis_earlier).to be_present
      expect(hypothesis_relation.hypothesis_later).to be_present
      expect(hypothesis_relation.explanation_quote).to be_blank
      expect(hypothesis_relation.citation).to be_blank
      expect(hypothesis_relation.kind).to eq "hypothesis_conflict"
      expect(hypothesis_relation).to be_valid
      expect(hypothesis_earlier.hypothesis_relations.pluck(:id)).to eq([hypothesis_relation.id])
      expect(hypothesis_earlier.conflicting_hypotheses.pluck(:id)).to eq([hypothesis_later.id])
      expect(hypothesis_later.hypothesis_relations.pluck(:id)).to eq([hypothesis_relation.id])
      expect(hypothesis_later.conflicting_hypotheses.pluck(:id)).to eq([hypothesis_earlier.id])
    end
    context "with a later conflict" do
      let!(:hypothesis_relation2) { FactoryBot.create(:hypothesis_relation, hypothesis_earlier: hypothesis_later) }
      it "is valid" do
        hypothesis_later_later = hypothesis_relation2.hypothesis_later
        expect(hypothesis_earlier.hypothesis_relations.pluck(:id)).to eq([hypothesis_relation.id])
        expect(hypothesis_earlier.conflicting_hypotheses.pluck(:id)).to eq([hypothesis_later.id])
        expect(hypothesis_later.hypothesis_relations.pluck(:id)).to match_array([hypothesis_relation.id, hypothesis_relation2.id])
        expect(hypothesis_later.conflicting_hypotheses.pluck(:id)).to match_array([hypothesis_earlier.id, hypothesis_later_later.id])
      end
    end
    # context "citation_conflict" do
    #   let(:hypothesis_relation) { FactoryBot.create(:hypothesis_relation_citation_conflict) }
    #   it "is valid" do
    #     expect(hypothesis_relation.earlier_hypothesis).to be_present
    #     expect(hypothesis_relation.later_hypothesis).to be_present
    #     expect(hypothesis_relation.explanation_quote).to be_present
    #     expect(hypothesis_relation.kind).to eq "challenge"
    #     expect(hypothesis_relation).to be_valid
    #     earlier_hypothesis = hypothesis_relation.earlier_hypothesis
    #     later_hypothesis = hypothesis_relation.later_hypothesis
    #     expect(hypothesis.pluck(:id)).to eq([hypothesis_relation.challenged_hypothesis_id])
    #     expect(challenged_hypothesis.challenges.pluck(:id)).to eq([hypothesis_relation.hypothesis_id])
    #     (challenged_hypothesis.explanation_quotes.first.hypothesis_relations.pluck(:id)).to eq([hypothesis_relation.id])
    #   end
    # end
  end
end
