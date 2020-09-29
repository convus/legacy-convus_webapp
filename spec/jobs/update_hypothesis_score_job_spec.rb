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
    before { hypothesis.update_column :score, 22 }
    it "updates the score" do
      instance.perform(hypothesis.id)
      hypothesis.reload
      expect(hypothesis.score).to eq 0
    end
  end
end
