require "rails_helper"

RSpec.describe Quote, type: :model do
  it "has a valid factory" do
    expect(FactoryBot.create(:quote)).to be_valid
  end

  it "doesn't permit creating duplicates or empty quotes" do
    citation1 = FactoryBot.create(:citation)
    quote1 = Quote.create(citation: citation1, text: "Some quote here")
    expect(quote1).to be_valid
    quote1_duplicate = Quote.create(citation: citation1, text: "\nSome quote here ")
    expect(quote1_duplicate).to_not be_valid
    citation2 = FactoryBot.create(:citation)
    quote2 = Quote.create(citation: citation2, text: " Some quote here")
    expect(quote2).to be_valid
    expect(quote2.text).to eq quote1.text
  end

  describe "friendly_find_quote" do
    let(:quote1) { FactoryBot.create(:quote, text: "some cool quote") }
    let(:quote2) { FactoryBot.create(:quote, text: "some cool quote") }
    it "finds the quotes" do
      expect(quote1).to be_valid
      expect(quote2).to be_valid
      expect(Quote.friendly_find("some cool quote")&.id).to eq quote1.id
      # Ensure scoping works
      expect(Quote.where(citation_id: quote2.citation_id).friendly_find("some cool quote")&.id).to eq quote2.id
    end
  end
end
