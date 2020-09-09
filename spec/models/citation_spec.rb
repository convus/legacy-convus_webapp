require "rails_helper"

RSpec.describe Citation, type: :model do
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
    context "article_by_publisher_with_retractions" do
      let(:publication) { Publication.new(has_published_retractions: true) }
      let(:citation) { Citation.new(assignable_kind: "", publication: publication) }
      it "sets article_by_publisher_with_retractions" do
        expect(citation.kind).to eq "article_by_publisher_with_retractions"
        expect(citation.kind_score).to eq 3
      end
      context "assigning article_by_publisher_with_retractions" do
        let(:assign_kind) { "article_by_publisher_with_retractions" }
        it "returns article_by_publisher_with_retractions" do
          expect(citation.kind).to eq "article_by_publisher_with_retractions"
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
end
