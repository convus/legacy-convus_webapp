# frozen_string_literal: true

require "rails_helper"

describe HypothesisSerializer, type: :lib do
  let(:obj) { FactoryBot.create(:hypothesis) }
  let(:serializer) { described_class.new(obj, root: false) }

  describe "output" do
    let!(:hypothesis_citation1) { FactoryBot.create(:hypothesis_citation, hypothesis: obj, url: "http://example.com/", quotes_text: "some quote") }
    let!(:hypothesis_citation2) { FactoryBot.create(:hypothesis_citation, hypothesis: obj, url: "http://example.com/stuff?utm_source=ffffff", quotes_text: "quote1\n quote2\n") }
    let(:target) do
      {
        title: obj.title,
        id: obj.id,
        topics: [],
        cited_urls: [
          {
            url: "http://example.com",
            quotes: ["some quote"]
          }, {
            url: "http://example.com/stuff",
            quotes: ["quote1", "quote2"]
          }
        ]
      }
    end
    it "returns the expected output" do
      expect(serializer.as_json).to eq target
    end
  end
end
