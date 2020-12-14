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

  # describe "refuted_by_hypotheses_str" do
  #   let!(:hypothesis) { FactoryBot.create(:hypothesis) }
  #   let!(:hypothesis_refuting) { FactoryBot.create(:hypothesis) }
  #   it "creates refuting_hypotheses" do
  #     expect(hypothesis.)
  #   end
  # end
end
