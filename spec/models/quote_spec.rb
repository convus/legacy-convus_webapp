require "rails_helper"

RSpec.describe Quote, type: :model do
  it "is valid" do
    expect(FactoryBot.create(:quote)).to be_valid
  end
end
