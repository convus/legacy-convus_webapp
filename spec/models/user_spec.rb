require "rails_helper"

RSpec.describe User, type: :model do
  describe "trustedness" do
    let(:user) { FactoryBot.create(:user) }
    let!(:hypothesis1) { FactoryBot.create(:hypothesis, creator: user) }
    let!(:hypothesis2) { FactoryBot.create(:hypothesis_approved, creator: user, created_at: Time.current - 6.months) }
    let!(:hypothesis2) { FactoryBot.create(:hypothesis_approved, creator: user) }
    it "is based on the recentness of the hypothesis" do
      expect(user.recent_approved_hypotheses.count).to eq 1
      expect(user.trustedness).to eq 10
    end
  end
end
