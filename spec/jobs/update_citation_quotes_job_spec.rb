require "rails_helper"

RSpec.describe UpdateCitationQuotesJob do
  let(:instance) { described_class.new }
  let(:citation) { FactoryBot.create(:citation) }
  let(:hypothesis_quote) { FactoryBot.create(:hypothesis_quote, citation: citation) }

  describe "individual" do
    let(:quote) { FactoryBot.create(:quote, citation: citation) }
    let!(:hypothesis_quote2) { FactoryBot.create(:hypothesis_quote, citation: citation) }
    it "removes the unused quote" do
      hypothesis_quote.update_column :score, 3
      hypothesis_quote.reload
      HypothesisQuote.update_all(updated_at: Time.current - 1.minute)
      expect(hypothesis_quote.score).to eq 3
      expect(hypothesis_quote.calculated_score).to eq 50
      expect(hypothesis_quote.citation&.id).to eq citation.id
      expect(quote.citation&.id).to eq citation.id
      expect(citation.quotes.count).to eq 3
      instance.perform(citation.id)
      citation.reload
      expect(citation.quotes.pluck(:id)).to match_array([hypothesis_quote.quote_id, hypothesis_quote2.quote_id])
      hypothesis_quote.reload
      expect(hypothesis_quote.score).to eq 50
      expect(hypothesis_quote.updated_at).to be > Time.current - 30.seconds

      # And check that hypothesis_quote2 wasn't updated (because it didn't need to be)
      hypothesis_quote2.reload
      expect(hypothesis_quote2.updated_at).to be < Time.current - 30.seconds
    end
  end

  describe "citation removed" do
    it "removes the quotes" do
      expect(hypothesis_quote).to be_valid
      expect(Citation.all.pluck(:id)).to eq([citation.id])
      expect(Quote.all.pluck(:id)).to eq([hypothesis_quote.quote_id])
      citation.destroy
      instance.perform(citation.id)
      expect(Citation.count).to eq 0
      expect(Quote.count).to eq 0
      expect(HypothesisQuote.count).to eq 0
    end
  end
end
