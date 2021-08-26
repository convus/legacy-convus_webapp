require "rails_helper"

RSpec.describe ArgumentQuote, type: :model do
  describe "citation_ref_text" do
    it "is blank" do
      argument_quote = ArgumentQuote.new
      expect(argument_quote.citation_ref_text).to eq ""
      expect(argument_quote.citation_ref_html).to eq ""
    end
    context "with no citation" do
      let(:url) { "https://example.com" }
      let(:argument_quote) { ArgumentQuote.new(url: url) }
      it "is url" do
        expect(argument_quote.citation_ref_text).to eq url
        expect(argument_quote.citation_ref_html).to eq "<small title=\"#{url}\">#{url}</small>"
      end
      context "longer url" do
        let(:url) { "https://api.github.com/repos/convus/convus_content/contents/hypotheses/publications-that-charge-to-publish-articles-and-don-t-have-peer-review-or-issue-retractions-are-the-least-reputable-source-for-information.yml?ref=df11e5b3abc02939becc893861bf9934a96b8f59" }
        it "is truncated url" do
          expect(argument_quote.citation_ref_text).to eq "https://api.github.com/repos/convus/convus_cont..."
          expect(argument_quote.citation_ref_html).to eq "<small title=\"#{url}\">https://api.github.com/repos/convus/convus_cont...</small>"
        end
      end
    end
    context "with citation" do
      let(:url) { "https://something.com/partystuff" }
      let(:citation) { Citation.find_or_create_by_params(url: url, title: "Something cool") }
      let(:argument_quote) { ArgumentQuote.new(citation: citation, url: url) }
      it "is publication: title" do
        expect(citation.publication.title).to eq "something.com"
        expect(argument_quote.citation_ref_text).to eq "something.com - Something cool"
        expect(argument_quote.citation_ref_html).to eq "<span title=\"#{url}\"><span class=\"less-strong\">something.com:</span> Something cool</span>"
      end
    end
    context "with citation" do
      let(:url) { "https://something.com/partystuff" }
      let(:citation) { Citation.find_or_create_by_params(url: url, title: "Something cool") }
      let(:publication) { citation.publication }
      let(:argument_quote) { ArgumentQuote.new(citation: citation, url: url) }
      it "is publication: title" do
        expect(citation.publication.title).to eq "something.com"
        expect(argument_quote.citation_ref_text).to eq "something.com - Something cool"
        expect(argument_quote.citation_ref_html).to eq "<span title=\"#{url}\"><span class=\"less-strong\">something.com:</span> Something cool</span>"
      end
      context "with publication title" do
        it "uses publication title" do
          publication.update(title: "Cool Publication")
          citation.reload
          expect(argument_quote.citation_ref_text).to eq "Cool Publication - Something cool"
          expect(argument_quote.citation_ref_html).to eq "<span title=\"#{url}\"><span class=\"less-strong\">Cool Publication:</span> Something cool</span>"
        end
      end
    end
  end
end
