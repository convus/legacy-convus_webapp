require 'rails_helper'

RSpec.describe HypothesisQuote, type: :model do
  it "has a valid factory" do
    expect(FactoryBot.create(:hypothesis_quote)).to be_valid
  end
end
