# frozen_string_literal: true

require "rails_helper"

describe CitationSerializer, type: :lib do
  let(:obj) { FactoryBot.create(:citation, kind: "research") }
  let(:serializer) { described_class.new(obj, root: false) }

  describe "output" do
    let(:explanation) { FactoryBot.create(:explanation_approved) }
    let!(:explanation_quote1) { FactoryBot.create(:explanation_quote, text: "This is a quote", url: obj.url, explanation: explanation) }
    let!(:explanation_quote2) { FactoryBot.create(:explanation_quote, text: "Another quote from the same thing", url: obj.url, explanation: explanation) }
    let!(:explanation_quote_unapproved) { FactoryBot.create(:explanation_quote, url: obj.url) }
    let(:target) do
      {
        title: obj.title,
        id: obj.id,
        peer_reviewed: false,
        url_is_not_publisher: false,
        url_is_direct_link_to_full_text: false,
        url: obj.url,
        publication_title: obj.publication.title,
        published_date: nil,
        authors: [],
        doi: nil,
        kind: "original research",
        quotes: [
          "This is a quote",
          "Another quote from the same thing"
        ]
      }
    end
    it "returns the expected output" do
      expect(obj.reload.explanation_quotes.pluck(:id)).to match_array([explanation_quote1.id, explanation_quote2.id, explanation_quote_unapproved.id])
      expect(serializer.as_json).to eq target
      expect_hashes_to_match(obj.flat_file_serialized, target)
    end
  end
end
