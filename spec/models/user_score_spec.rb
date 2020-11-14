require "rails_helper"

RSpec.describe UserScore, type: :model do
  describe "factory" do
    let(:user_score) { FactoryBot.create(:user_score, score: -10) }
    it "is valid" do
      expect(user_score).to be_valid
      expect(user_score.score).to eq 0
    end
  end

  describe "expire previous" do
    let(:user_score) { FactoryBot.create(:user_score, score: 7) }
    let(:user) { user_score.user }
    let(:hypothesis) { user_score.hypothesis }
    let(:user_score2) { FactoryBot.create(:user_score, score: 8, user: user, hypothesis: hypothesis) }
    let(:user_score3) { FactoryBot.create(:user_score, score: 9, user: user, hypothesis: hypothesis) }
    it "expires on create, not update" do
      expect(UserScore.current_score).to be_blank
      expect(user_score.expired?).to be_falsey
      expect(user_score2.expired?).to be_falsey
      user_score.reload
      expect(user_score.expired?).to be_truthy
      # Manually update, whatever
      user_score.update(expired: false)
      expect(user_score.expired?).to be_falsey
      user_score2.reload
      expect(user_score2.expired?).to be_falsey
      expect(UserScore.current_score).to eq 7.5
      # and both are updated
      expect(user_score3.expired?).to be_falsey
      user_score.reload
      expect(user_score.expired?).to be_truthy
      user_score2.reload
      expect(user_score2.expired?).to be_truthy
      expect(UserScore.current_score).to eq 9
    end
  end
end
