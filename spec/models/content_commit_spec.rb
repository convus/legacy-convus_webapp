require 'rails_helper'

RSpec.describe ContentCommit, type: :model do
  describe "factory" do
    it "is valid" do
      expect(FactoryBot.create(:content_commit)).to be_valid
    end
  end
end
