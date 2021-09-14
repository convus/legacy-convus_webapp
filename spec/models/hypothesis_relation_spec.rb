require "rails_helper"

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
    context "citation_conflict" do
      # I don't know how this will actually work yet, so I'm skipping it until I've built things
    end
  end

  describe "find_or_create_for" do
    let!(:hypothesis1) { FactoryBot.create(:hypothesis) }
    let!(:hypothesis2) { FactoryBot.create(:hypothesis) }
    it "creates" do
      hypothesis_relation = HypothesisRelation.find_or_create_for(kind: "hypothesis_conflict", hypotheses: [hypothesis1, hypothesis2])
      expect(hypothesis_relation.hypothesis_earlier_id).to eq hypothesis1.id
      expect(hypothesis_relation.hypothesis_later_id).to eq hypothesis2.id
      expect(hypothesis_relation.kind).to eq "hypothesis_conflict"
      expect(hypothesis1.reload.conflicting_hypotheses.pluck(:id)).to eq([hypothesis2.id])
      # And doing it again doesn't create more
      expect(HypothesisRelation.find_or_create_for(kind: "hypothesis_conflict", hypotheses: [hypothesis1, hypothesis2])&.id).to eq hypothesis_relation.id
      expect(HypothesisRelation.find_or_create_for(kind: "hypothesis_conflict", hypotheses: [hypothesis2, hypothesis1])&.id).to eq hypothesis_relation.id
    end
  end
end
