require "rails_helper"

RSpec.describe Hypothesis, type: :model do
  it_behaves_like "TitleSluggable"

  it "has a valid factory" do
    hypothesis = FactoryBot.create(:hypothesis)
    expect(hypothesis.id).to be_present
    hypothesis.reload
    expect(hypothesis.tags.pluck(:id)).to eq([])
  end

  describe "tags_string" do
    let(:hypothesis) { FactoryBot.create(:hypothesis) }
    it "assigns an array" do
      hypothesis.tags_string = ["Space"]
      hypothesis.save
      hypothesis.reload
      expect(hypothesis.tags_string).to eq("Space")
    end
    context "assigning a string" do
      let!(:tag) { FactoryBot.create(:tag, title: "SOME existing title") }
      let(:hypothesis) { FactoryBot.create(:hypothesis, tags_string: "some  existing titlé  ,") }
      it "assigns based on the string, adds removes" do
        hypothesis.reload
        expect(hypothesis.tags.pluck(:id)).to eq([tag.id])
        hypothesis.update(tags_string: "a new tag,Something\n environmenT")
        hypothesis.reload
        expect(hypothesis.tags.count).to eq 3
        expect(hypothesis.tags.pluck(:id)).to_not include(tag.id)
        expect(hypothesis.tags_string).to eq("a new tag, environmenT, Something")
      end
    end
  end

  describe "citation_urls" do
    let!(:citation) { FactoryBot.create(:citation, title: "some citation", url: "https://bikeindex.org/about") }
    let(:hypothesis) { FactoryBot.create(:hypothesis, title: "hypothesis-1") }
    it "assigns" do
      hypothesis.update(citation_urls: "bikeindex.org/about")
      expect(hypothesis.citations.pluck(:id)).to eq([citation.id])
    end
    context "new url" do
      it "assigns both" do
        hypothesis.update(citation_urls: ["https://bikeindex.org/about", "https://bikeindex.org/serials"])
        expect(hypothesis.citations.pluck(:id)).to include(citation.id)
        expect(hypothesis.citation_urls).to match_array(["https://bikeindex.org/about", "https://bikeindex.org/serials"])
      end
    end
  end
end
