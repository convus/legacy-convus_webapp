require 'rails_helper'

RSpec.describe Refutation, type: :model do
  describe "factory" do
    let(:hypothesis_refuted) { FactoryBot.create(:hypothesis_refuted) }
    it "creates a refuted hypothesis" do
      hypothesis_refuted.reload
      expect(hypothesis_refuted.refuted?).to be_truthy
      expect(hypothesis_refuted.refuted_by_hypotheses.count).to eq 1
      hypothesis_refuter = hypothesis_refuted.refuted_by_hypotheses.first
      expect(hypothesis_refuter.refutes_hypotheses.pluck(:id)).to eq([hypothesis_refuted.id])
    end
    context "passed refuter" do
      let(:hypothesis_refuter) { FactoryBot.create(:hypothesis) }
      let(:hypothesis_refuted) { FactoryBot.create(:hypothesis_refuted, refuting_hypothesis: hypothesis_refuter) }
      it "creates a refuted hypothesis" do
        hypothesis_refuted.reload
        expect(hypothesis_refuted.refuted?).to be_truthy
        expect(hypothesis_refuted.refuted_by_hypotheses.pluck(:id)).to eq([hypothesis_refuter.id])
        expect(hypothesis_refuter.refutes_hypotheses.pluck(:id)).to eq([hypothesis_refuted.id])
      end
    end
  end

  describe "refuted_by_hypotheses_str" do
    let!(:hypothesis_refuted) { FactoryBot.create(:hypothesis) }
    let(:hypothesis_refuting) { FactoryBot.create(:hypothesis) }
    it "creates refuting_hypotheses" do
      expect(hypothesis_refuted.refuted?).to be_falsey
      hypothesis_refuted.update(refuted_by_hypotheses_str: hypothesis_refuting.id)
      hypothesis_refuted.reload
      expect(hypothesis_refuted.refuted?).to be_truthy
      expect(hypothesis_refuted.refuted_by_hypotheses.pluck(:id)).to eq([hypothesis_refuting.id])
      # And it removes, if removed
      hypothesis_refuted.update(refuted_by_hypotheses_str: [])
      hypothesis_refuted.reload
      expect(hypothesis_refuted.refuted?).to be_falsey
      expect(hypothesis_refuted.refuted_by_hypotheses.pluck(:id)).to eq([])
    end
    context "unknown" do
      it "ignores" do
        expect(hypothesis_refuted.refuted?).to be_falsey
        hypothesis_refuted.update(refuted_by_hypotheses_str: "cx89asdfa89sdff")
        hypothesis_refuted.reload
        expect(hypothesis_refuted.refuted?).to be_falsey
        expect(hypothesis_refuted.refuted_by_hypotheses.pluck(:id)).to eq([])
      end
    end
    context "multiple" do
      let(:hypothesis_refuting2) { FactoryBot.create(:hypothesis) }
      it "creates refuting_hypotheses" do
        expect(hypothesis_refuted.refuted?).to be_falsey
        hypothesis_refuted.update(refuted_by_hypotheses_str: [hypothesis_refuting.slug, hypothesis_refuting2.title])
        hypothesis_refuted.reload
        expect(hypothesis_refuted.refuted?).to be_truthy
        expect(hypothesis_refuted.refuted_by_hypotheses.pluck(:id)).to match_array([hypothesis_refuting.id, hypothesis_refuting2.id])
        # And it removes just one, if removed
        hypothesis_refuted.update(refuted_by_hypotheses_str: hypothesis_refuting2.title)
        hypothesis_refuted.reload
        expect(hypothesis_refuted.refuted?).to be_truthy
        expect(hypothesis_refuted.refuted_by_hypotheses.pluck(:id)).to eq([hypothesis_refuting2.id])
      end
    end
  end
end
