require "rails_helper"

RSpec.describe Quote, type: :model do
  it "has a valid factory" do
    expect(FactoryBot.create(:quote)).to be_valid
  end
end
