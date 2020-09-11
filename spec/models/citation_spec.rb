require "rails_helper"

RSpec.describe Citation, type: :model do
  describe "factory" do
    let(:citation) { FactoryBot.create(:citation) }
    it "is valid" do
      expect(citation.errors.full_messages).to be_blank
      expect(citation.id).to be_present
    end
  end

  describe "slugging" do
    let(:url) { "https://www.nationalreview.com/2020/09/joe-bidens-money-misadventures/" }
    let(:citation) { FactoryBot.create(:citation, url: url, title: nil) }
    it "slugs from the URL" do
      expect(citation.title).to eq "2020/09/joe-bidens-money-misadventures"
      expect(citation.publication_id).to be_present
      expect(citation.publication.title).to eq "nationalreview.com"
      expect(citation.slug).to eq("nationalreview-com-2020-09-joe-bidens-money-misadventures")
    end
    context "URL is not a url" do
      let(:url) { "This isn't a URL" }
      let(:citation) { FactoryBot.create(:citation, url: url, title: nil) }
      it "doesn't explode" do
        expect(citation.publication_id).to be_blank
        expect(citation.title).to eq url
        expect(citation.slug).to eq("this-isn-t-a-url")
      end
    end
    context "Title and URL" do
      let!(:publication) { FactoryBot.create(:publication, title: "National Review", home_url: "https://www.nationalreview.com") }
      let(:citation) { FactoryBot.create(:citation, url: url, title: "Joe Biden’s Money Misadventures") }
      it "slugs from publication domain & title" do
        expect(citation.title).to eq "Joe Biden’s Money Misadventures"
        expect(citation.publication_id).to eq publication.id
        expect(citation.publication.title).to eq "National Review"
        expect(citation.slug).to eq("national-review-joe-biden-s-money-misadventures")
        expect(Citation.friendly_find("Joe Biden’s Money Misadventures")).to eq citation
        expect(Citation.friendly_find(url)).to eq citation
      end
    end
  end

  describe "assignable_kind" do
    let(:citation) { Citation.new(assignable_kind: assign_kind) }
    let(:assign_kind) { "" }
    before { citation.set_calculated_attributes }

    it "assigns article" do
      expect(citation.kind).to eq "article"
      expect(citation.kind_score).to eq 1
    end
    context "kind already assigned" do
      let(:citation) { Citation.new(assignable_kind: assign_kind, kind: "open_access_peer_reviewed") }
      it "does not alter kind" do
        expect(citation.kind).to eq "open_access_peer_reviewed"
      end
    end
    context "illegal kind" do
      let(:assign_kind) { "open_access_peer_reviewed" }
      it "returns article" do
        expect(citation.kind).to eq "article"
      end
    end
    context "article_by_publication_with_retractions" do
      let(:publication) { Publication.new(has_published_retractions: true) }
      let(:citation) { Citation.new(assignable_kind: "", publication: publication) }
      it "sets article_by_publication_with_retractions" do
        expect(citation.kind).to eq "article_by_publication_with_retractions"
        expect(citation.kind_score).to eq 3
      end
      context "assigning article_by_publication_with_retractions" do
        let(:assign_kind) { "article_by_publication_with_retractions" }
        it "returns article_by_publication_with_retractions" do
          expect(citation.kind).to eq "article_by_publication_with_retractions"
        end
      end
    end
    context "quote_from_involved_party" do
      let(:assign_kind) { "quote_from_involved_party" }
      it "is quote_from_involved_party" do
        expect(citation.kind).to eq "quote_from_involved_party"
        expect(citation.kind_score).to eq 10
      end
    end
    context "peer_reviewed" do
      let(:assign_kind) { "peer_reviewed" }
      it "sets closed_access" do
        expect(citation.kind).to eq "closed_access_peer_reviewed"
        expect(citation.kind_score).to eq 2
      end
      context "with url_is_direct_link_to_full_text" do
        let(:citation) { Citation.new(assignable_kind: assign_kind, url_is_direct_link_to_full_text: true) }
        it "is open_access" do
          expect(citation.kind).to eq "open_access_peer_reviewed"
          expect(citation.kind_score).to eq 20
        end
      end
    end
  end

  describe "authors_str" do
    let(:citation) { Citation.new(authors_str: "george stanley") }
    it "does one" do
      expect(citation.authors).to eq(["george stanley"])
      expect(citation.authors_str).to eq "george stanley"
    end
    context "with multiple" do
      let(:citation) { Citation.new(authors_str: "Stanley, George\n  Frank, Bobby")}
      it "splits by new line, sorts" do
        expect(citation.authors).to eq(["Stanley, George", "Frank, Bobby"])
        expect(citation.authors_str).to eq "Stanley, George; Frank, Bobby"
      end
    end
  end
end
