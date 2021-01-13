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
        refuted_by_hypotheses: [],
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
      expect_hashes_to_match(serializer.as_json, target)
      expect_hashes_to_match(obj.flat_file_serialized, target)
    end
    context "refuted_hypothesis" do
      let(:obj) { FactoryBot.create(:hypothesis_refuted, hypothesis_refuting: refuting_hypothesis) }
      let(:refuting_hypothesis) { FactoryBot.create(:hypothesis, title: "I refute this hypothesis because of things") }
      let(:refuted_target) { target.merge(refuted_by_hypotheses: ["I refute this hypothesis because of things"]) }
      it "returns target" do
        expect_hashes_to_match(serializer.as_json, refuted_target)
      end
    end

    describe "flat_file_serialized with override" do
      let(:overridden) { target.merge(new_cited_url: {url: "https://stuff.com/example", quotes: ["bbbbbutter"]}) }
      it "returns the expected output" do
        obj.serialized_override = overridden
        expect_hashes_to_match(obj.flat_file_serialized, overridden)
      end
    end
  end
end
