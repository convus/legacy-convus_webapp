# frozen_string_literal: true

require "rails_helper"

describe HypothesisSerializer, type: :lib do
  let(:obj) { FactoryBot.create(:hypothesis_approved) }
  let(:serializer) { described_class.new(obj, root: false) }

  # Commented out in PR#146
  # describe "output" do
  #   let!(:hypothesis_citation1) { FactoryBot.create(:hypothesis_citation, :approved, hypothesis: obj, url: "http://example.com/", quotes_text: "some quote") }
  #   let!(:hypothesis_citation2) { FactoryBot.create(:hypothesis_citation, :approved, hypothesis: obj, url: "http://example.com/stuff?utm_source=ffffff", quotes_text: "quote1\n quote2\n") }
  #   let(:target) do
  #     {
  #       title: obj.title,
  #       id: obj.ref_id,
  #       topics: [],
  #       explanations: {},
  #       cited_urls: [
  #         {
  #           url: "http://example.com",
  #           quotes: ["some quote"],
  #           challenges: nil
  #         }, {
  #           url: "http://example.com/stuff",
  #           quotes: ["quote1", "quote2"],
  #           challenges: nil
  #         }
  #       ],
  #       new_cited_url: nil
  #     }
  #   end
  #   it "returns the expected output" do
  #     expect_hashes_to_match(serializer.as_json, target)
  #     expect_hashes_to_match(obj.flat_file_serialized, target)
  #   end

  #   context "unapproved hypothesis" do
  #     let(:obj) { FactoryBot.create(:hypothesis) }
  #     it "includes unapproved" do
  #       hypothesis_citation1.update(approved_at: nil)
  #       hypothesis_citation2.update(approved_at: nil)
  #       obj.reload
  #       expect_hashes_to_match(serializer.as_json, target)
  #       expect_hashes_to_match(obj.flat_file_serialized, target)
  #     end
  #   end

  #   context "unsubmitted hypothesis_citation" do
  #     let!(:hypothesis_citation3) { FactoryBot.create(:hypothesis_citation, hypothesis: obj, pull_request_number: 102, submitting_to_github: true) }
  #     let(:target_approved) { target.merge(cited_urls: [target[:cited_urls].last]) }
  #     let(:overridden) { target_approved.merge(new_cited_url: target[:cited_urls].first) }
  #     it "does not include unapproved" do
  #       hypothesis_citation1.update(approved_at: nil)
  #       obj.reload
  #       expect_hashes_to_match(serializer.as_json, target_approved)
  #       expect_hashes_to_match(obj.flat_file_serialized, target_approved)
  #       obj.included_unapproved_hypothesis_citation = hypothesis_citation1
  #       expect_hashes_to_match(obj.flat_file_serialized, overridden)
  #     end
  #   end

  #   context "challenged hypothesis_citation" do
  #     let!(:hypothesis_citation_challenge1) do
  #       FactoryBot.create(:hypothesis_citation_challenge_by_another_citation,
  #         :approved,
  #         challenged_hypothesis_citation: hypothesis_citation2,
  #         url: "https://stuff.com/whooooooo",
  #         quotes_text: "I challenge thee!")
  #     end
  #     let!(:hypothesis_citation_challenge2) do
  #       FactoryBot.create(:hypothesis_citation_challenge_citation_quotation,
  #         :approved,
  #         challenged_hypothesis_citation: hypothesis_citation1,
  #         quotes_text: "quote1 is actually this quote")
  #     end
  #     let(:target_challenged) { target.merge(cited_urls: cited_urls + [challenge2]) }
  #     let(:cited_urls) do
  #       [
  #         {
  #           url: "http://example.com",
  #           quotes: ["some quote"],
  #           challenges: nil
  #         }, {
  #           url: "http://example.com/stuff",
  #           quotes: ["quote1", "quote2"],
  #           challenges: nil
  #         },
  #         {
  #           url: "https://stuff.com/whooooooo",
  #           quotes: ["I challenge thee!"],
  #           challenges: "http://example.com/stuff"
  #         }
  #       ]
  #     end
  #     let(:challenge2) do
  #       {url: "http://example.com",
  #        quotes: ["quote1 is actually this quote"],
  #        challenges: "http://example.com"}
  #     end
  #     it "returns with expected stuff" do
  #       expect(hypothesis_citation1.approved?).to be_truthy
  #       expect(hypothesis_citation2.approved?).to be_truthy
  #       expect(hypothesis_citation_challenge1.approved?).to be_truthy
  #       expect(hypothesis_citation_challenge2.approved?).to be_truthy
  #       obj.reload
  #       expect(serializer.as_json.dig(:cited_urls)).to match_array(cited_urls + [challenge2])
  #       # Commenting out because going to remove...
  #       # expect_hashes_to_match(serializer.as_json, target_challenged)
  #       # expect_hashes_to_match(obj.flat_file_serialized, target_challenged)
  #       # And test with an unapproved challenge
  #       hypothesis_citation_challenge2.update(approved_at: nil)
  #       obj.reload
  #       target_without2 = target.merge(cited_urls: cited_urls)
  #       expect_hashes_to_match(obj.flat_file_serialized, target_without2)
  #       # Test with an included unapproved hypothesis citation
  #       obj.included_unapproved_hypothesis_citation = hypothesis_citation_challenge2
  #       expect_hashes_to_match(obj.flat_file_serialized, target_without2.merge(new_cited_url: challenge2))
  #     end
  #   end
  # end
end
