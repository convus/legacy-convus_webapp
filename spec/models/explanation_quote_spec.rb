require "rails_helper"

RSpec.describe ExplanationQuote, type: :model do
  describe "citation_ref_text" do
    it "is blank" do
      explanation_quote = ExplanationQuote.new
      expect(explanation_quote.citation_ref_text).to eq ""
      expect(explanation_quote.citation_ref_html).to eq ""
    end
    context "with no citation" do
      let(:url) { "https://example.com" }
      let(:explanation_quote) { ExplanationQuote.new(url: url) }
      it "is url" do
        expect(explanation_quote.citation_ref_text).to eq url
        expect(explanation_quote.citation_ref_html).to eq "<small title=\"#{url}\">#{url}</small>"
      end
      context "longer url" do
        let(:url) { "https://api.github.com/repos/convus/convus_content/contents/hypotheses/publications-that-charge-to-publish-articles-and-don-t-have-peer-review-or-issue-retractions-are-the-least-reputable-source-for-information.yml?ref=df11e5b3abc02939becc893861bf9934a96b8f59" }
        it "is truncated url" do
          expect(explanation_quote.citation_ref_text).to eq "https://api.github.com/repos/convus/convus_cont..."
          expect(explanation_quote.citation_ref_html).to eq "<small title=\"#{url}\">https://api.github.com/repos/convus/convus_cont...</small>"
        end
      end
    end
    context "with citation" do
      let(:url) { "https://something.com/partystuff" }
      let(:citation) { Citation.find_or_create_by_params(url: url, title: "Something cool") }
      let(:explanation_quote) { ExplanationQuote.new(citation: citation, url: url) }
      it "is publication: title" do
        expect(citation.publication.title).to eq "something.com"
        expect(explanation_quote.citation_ref_text).to eq "something.com - Something cool"
        expect(explanation_quote.citation_ref_html).to eq "<span title=\"#{url}\"><span class=\"source-pub\">something.com:</span> <span class=\"source-title\">Something cool</span></span>"
      end
    end
    context "with citation" do
      let(:url) { "https://something.com/partystuff" }
      let(:citation) { Citation.find_or_create_by_params(url: url, title: "Something cool") }
      let(:publication) { citation.publication }
      let(:explanation_quote) { ExplanationQuote.new(citation: citation, url: url) }
      it "is publication: title" do
        expect(citation.publication.title).to eq "something.com"
        expect(explanation_quote.citation_ref_text).to eq "something.com - Something cool"
        expect(explanation_quote.citation_ref_html).to eq "<span title=\"#{url}\"><span class=\"source-pub\">something.com:</span> <span class=\"source-title\">Something cool</span></span>"
      end
      context "with publication title" do
        it "uses publication title" do
          publication.update(title: "Cool Publication")
          citation.reload
          expect(explanation_quote.citation_ref_text).to eq "Cool Publication - Something cool"
          expect(explanation_quote.citation_ref_html).to eq "<span title=\"#{url}\"><span class=\"source-pub\">Cool Publication:</span> <span class=\"source-title\">Something cool</span></span>"
        end
      end
    end
  end

  describe "citation" do
    let(:explanation_quote) { FactoryBot.create(:explanation_quote) }
    let(:explanation) { explanation_quote.explanation }
    it "associates" do
      expect(explanation_quote.reload.hypothesis).to be_present
      expect(explanation_quote.citation.hypotheses.pluck(:id)).to eq([explanation_quote.hypothesis_id])
      expect(explanation_quote.citation_id).to be_present
      expect(explanation_quote.hypothesis.citations.pluck(:id)).to eq([explanation_quote.citation_id])
    end
  end
end
