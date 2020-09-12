require "rails_helper"

RSpec.describe Hypothesis, type: :model do
  it_behaves_like "TitleSluggable"

  it "has a valid factory" do
    hypothesis = FactoryBot.create(:hypothesis)
    expect(hypothesis.id).to be_present
    hypothesis.reload
    expect(hypothesis.family_tag).to eq Tag.uncategorized
    expect(hypothesis.tags.pluck(:id)).to eq([])
  end

  describe "with non-uncategorized" do
    let(:tag) { FactoryBot.create(:tag) }
    let(:hypothesis) { FactoryBot.create(:hypothesis, family_tag: tag) }
    it "adds the tag" do
      expect(hypothesis.id).to be_present
      hypothesis.reload
      expect(hypothesis.family_tag).to eq tag
      expect(hypothesis.tags.pluck(:id)).to eq([tag.id])
    end
  end
end
