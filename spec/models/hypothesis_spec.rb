require "rails_helper"

RSpec.describe Hypothesis, type: :model do
  it_behaves_like "TitleSluggable"

  it "has a valid factory" do
    hypothesis = FactoryBot.create(:hypothesis)
    expect(hypothesis.id).to be_present
    expect(hypothesis.family_tag).to eq Tag.family_uncategorized
  end
end
