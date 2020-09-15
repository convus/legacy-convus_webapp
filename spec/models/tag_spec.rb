require "rails_helper"

RSpec.describe Tag, type: :model do
  it_behaves_like "TitleSluggable"

  # This is definitely not wild, but... we do want to make sure
  it "destroys hypothesis tag" do
    FactoryBot.create(:hypothesis, tags_string: "some tag")
    tag = Tag.friendly_find "some tag"
    expect(HypothesisTag.count).to eq 1
    tag.destroy
    expect(HypothesisTag.count).to eq 0
  end
end
