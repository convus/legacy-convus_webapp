# frozen_string_literal: true

require "rails_helper"

describe CitationSerializer, type: :lib do
  let(:obj) { FactoryBot.create(:citation, kind: "research") }
  let(:serializer) { described_class.new(obj, root: false) }

  describe "output" do
    let!(:quote1) { FactoryBot.create(:quote, citation: obj, text: "This is a quote") }
    let!(:quote2) { FactoryBot.create(:quote, citation: obj, text: "Another quote from the same thing") }
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
      expect(serializer.as_json).to eq target
      expect_hashes_to_match(obj.flat_file_serialized, target)
    end
  end
end
