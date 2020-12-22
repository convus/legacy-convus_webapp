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

  describe "matching_tag_ids_and_non_tags" do
    let!(:tag1) { FactoryBot.create(:tag_approved, title: "Environment") }
    let!(:tag2) { FactoryBot.create(:tag_approved, title: "Police") }
    it "returns two arrays" do
      expect(Tag.matching_tag_ids("environment \n")).to eq([tag1.id])
      expect(Tag.matching_tag_ids_and_non_tags("environment")).to eq({tag_ids: [tag1.id], non_tags: []})
      expect(Tag.matching_tag_ids_and_non_tags("environment,,police\n")).to eq({tag_ids: [tag1.id, tag2.id], non_tags: []})
      expect(Tag.matching_tag_ids_and_non_tags(["Cool thingS", "police"])).to eq({tag_ids: [tag2.id], non_tags: ["Cool thingS"]})
      expect(Tag.matching_tag_ids_and_non_tags("Cool,police,   environment\n Other stuff   ")).to eq({tag_ids: [tag2.id, tag1.id], non_tags: ["Cool", "Other stuff"]})
    end
  end
end
