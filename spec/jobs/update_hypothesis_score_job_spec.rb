require "rails_helper"

RSpec.describe UpdateHypothesisScoreJob do
  let(:instance) { described_class.new }
  let!(:hypothesis) { FactoryBot.create(:hypothesis_approved) }

  it "enqueues without args" do
    expect {
      instance.perform
    }.to change(UpdateHypothesisScoreJob.jobs, :count).by 1
  end

  describe "individual" do
    let(:updated_at) { Time.current - 3.hours }
    before { hypothesis.update_columns(score: 2, updated_at: updated_at) }
    context "score changed" do
      it "updates the score" do
        instance.perform(hypothesis.id)
        hypothesis.reload
        expect(hypothesis.score).to eq 0
        expect(hypothesis.updated_at).to be_within(5).of Time.current
      end
    end
    context "with citation" do
      let(:citation) { FactoryBot.create(:citation_approved, randomized_controlled_trial: true) }
      let(:hypothesis) { FactoryBot.create(:hypothesis_approved) }
      let!(:hypothesis_citation) { FactoryBot.create(:hypothesis_citation, hypothesis: hypothesis, url: citation.url) }
      it "does not bump" do
        hypothesis.reload
        expect(citation.calculated_score).to eq 2
        expect(hypothesis.calculated_score).to eq 2
        expect(citation.score).to eq 2
        instance.perform(hypothesis.id)
        hypothesis.reload
        expect(hypothesis.score).to eq 2
        expect(hypothesis.updated_at).to be_within(2).of updated_at
      end
      context "citation score changed" do
        before { citation.update_columns(score: 12) }
        it "updates" do
          expect(hypothesis.calculated_score).to eq 2
          expect(citation.score).to eq 12
          expect(citation.calculated_score).to eq 2
          instance.perform(hypothesis.id)
          hypothesis.reload
          expect(hypothesis.score).to eq 2
          expect(hypothesis.updated_at).to be_within(5).of updated_at

          citation.reload
          expect(citation.score).to eq 2
          expect(hypothesis.calculated_score).to eq 2
        end
      end
    end
  end
end
