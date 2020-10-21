require "rails_helper"

RSpec.describe HypothesisQuote, type: :model do
  describe "factory" do
    let(:hypothesis_quote) { FactoryBot.create(:hypothesis_quote, importance: nil) }
    it "has a valid factory" do
      expect(hypothesis_quote).to be_valid
      expect(hypothesis_quote.hypothesis.quotes.pluck(:id)).to eq([hypothesis_quote.quote_id])
      expect(hypothesis_quote.importance).to eq 5
      expect(hypothesis_quote.score).to eq 5
    end
  end

  describe "importance limits" do
    before { hypothesis_quote.set_calculated_attributes }
    context "nil importance" do
      let(:hypothesis_quote) { HypothesisQuote.new(importance: nil) }
      it "sets importance to default" do
        expect(hypothesis_quote.importance).to eq 5
        expect(hypothesis_quote.score).to eq 5
      end
    end
    context "-1 importance" do
      let(:hypothesis_quote) { HypothesisQuote.new(importance: -1) }
      it "sets importance to max" do
        expect(hypothesis_quote.importance).to eq 1
        expect(hypothesis_quote.score).to eq 1
      end
    end
    context "20 importance" do
      let(:hypothesis_quote) { HypothesisQuote.new(importance: 20) }
      it "sets importance to max" do
        expect(hypothesis_quote.importance).to eq 10
        expect(hypothesis_quote.score).to eq 10
      end
    end
  end

  describe "calculated_score" do
    let(:importance) { HypothesisQuote::DEFAULT_IMPORTANCE }
    let(:hypothesis_quote) { HypothesisQuote.new(quote: quote, importance: importance) }
    let(:quote) { Quote.new(citation: citation) }
    before do
      # citation.set_calculated_attributes
      hypothesis_quote.set_calculated_attributes
    end
    context "citation peer_reviewed open access" do
      let(:citation) { Citation.new(peer_reviewed: true, url_is_direct_link_to_full_text: true) }
      it "sets closed_access" do
        expect(citation.badges).to eq({open_access_research: 10})
        expect(citation.calculated_score).to eq 10
        expect(hypothesis_quote.importance).to eq 5
        expect(hypothesis_quote.score).to eq 15
      end
    end
    context "citation randomized_controlled_trial" do
      let(:citation) { Citation.new(randomized_controlled_trial: true) }
      let(:importance) { 7 }
      it "returns calculated_score with importance" do
        expect(citation.calculated_score).to eq 2
        expect(hypothesis_quote.score).to eq 9
      end
    end
  end
end
