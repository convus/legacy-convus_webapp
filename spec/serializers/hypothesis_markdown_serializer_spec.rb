# frozen_string_literal: true

require "rails_helper"

describe HypothesisMarkdownSerializer, type: :lib do
  # Set ref number to make sure it isn't just integers, which get wrapped in quotes
  let(:hypothesis) { FactoryBot.create(:hypothesis_approved, title: title, ref_number: 122) }
  let(:title) { "Some cool title." }
  let(:instance) { described_class.new(hypothesis: hypothesis) }

  describe "to_flat_file" do
    context "no explanation, with topics" do
      let(:target_json) { {id: hypothesis.ref_id, hypothesis: title, topics: ["A Topic"], supporting: nil, conflicting: nil, citations: nil} }
      let(:target) { "---\nid: #{hypothesis.ref_id}\nhypothesis: #{title}\ntopics:\n- A Topic\nsupporting:\nconflicting:\ncitations:\n---\n" }
      it "returns" do
        hypothesis.update(tags_string: "A Topic")
        expect(hypothesis.tag_titles).to eq(["A Topic"])
        expect_hashes_to_match(instance.as_json, target_json)
        expect(instance.to_markdown.gsub(/ \n/, "\n")).to eq target
      end
    end

    context "with explanation" do
      let(:url1) { "https://convus.org/hypotheses/something" }
      let(:published_date_str) { "2021-09-08" }
      let(:explanation_text) { "Let's talk about some stuff here\n\n> With a quote\n> ref:#{url1}" }
      let!(:explanation) { FactoryBot.create(:explanation, text: explanation_text, hypothesis: hypothesis, ref_number: 1) }
      let!(:citation) { FactoryBot.create(:citation, url: url1, title: "A Special Title", published_date_str: published_date_str, publication_title: "Convus") }
      let!(:explanation_quote) { explanation.explanation_quotes.create(text: "With a quote", url: url1) }
      let(:target_json) do
        {id: hypothesis.ref_id,
         hypothesis: title,
         topics: [],
         supporting: nil,
         conflicting: nil,
         citations: {
           url1 => {title: "A Special Title", published_date: published_date_str, publication_title: "Convus"}
         }}
      end
      let(:conflicting_supporting_text) { "supporting:\nconflicting:\n" }
      let(:target) do
        "---\nid: #{hypothesis.ref_id}\nhypothesis: #{title}\ntopics: []\n#{conflicting_supporting_text}" \
        "citations:\n  #{url1}:\n    title: A Special Title\n    published_date: "\
        "'#{published_date_str}'\n    publication_title: Convus\n---\n## Explanation 1\n\n#{explanation_text}"
      end
      it "serializes" do
        hypothesis.reload
        expect(explanation.reload.text_with_references).to eq explanation_text
        expect(explanation.explanation_quotes.count).to eq 1
        expect(explanation_quote.citation_id).to eq citation.id
        expect(citation.publication_title).to eq "Convus"
        expect(citation.published_date_str).to eq published_date_str
        expect_hashes_to_match(instance.as_json, target_json.merge(citations: nil))
        # Not passing in explanation, because it isn't approved
        expect(instance.to_markdown.gsub(/ \n/, "\n")).to eq "---\nid: #{hypothesis.ref_id}\nhypothesis: #{title}\ntopics: []\n#{conflicting_supporting_text}citations:\n---\n"
        # Passing it in (we regularly serialize unapproved explanations)
        expect(described_class.new(hypothesis: hypothesis, explanations: [explanation]).to_markdown.gsub(/ \n/, "\n")).to eq target
        # And if the explanation is approved, it renders too
        explanation.update(approved_at: Time.current - 1)
        new_instance = described_class.new(hypothesis: hypothesis)
        expect(new_instance.to_markdown.gsub(/ \n/, "\n")).to eq target
        expect_hashes_to_match(new_instance.as_json, target_json)
      end
      context "with relations" do
        let(:hypothesis_conflicting) { FactoryBot.create(:hypothesis_approved) }
        let(:hypothesis_supporting) { FactoryBot.create(:hypothesis_approved) }
        let!(:hypothesis_relation_conflicting) { HypothesisRelation.create_for(kind: "hypothesis_conflict", hypotheses: [hypothesis_conflicting, hypothesis])}
        let!(:hypothesis_relation_supporting) { HypothesisRelation.create_for(kind: "hypothesis_support", hypotheses: [hypothesis_supporting, hypothesis])}
        let(:relations_json) { target_json.merge(conflicting: [hypothesis_conflicting.title_with_ref_id], supporting: [hypothesis_supporting.title_with_ref_id]) }
        let(:conflicting_supporting_text) { "supporting:\n- '#{hypothesis_supporting.title_with_ref_id}'\nconflicting:\n- '#{hypothesis_conflicting.title_with_ref_id}'\n" }
        it "serializes" do
          hypothesis.reload
          expect(explanation.reload.text_with_references).to eq explanation_text
          expect_hashes_to_match(instance.as_json, relations_json.merge(citations: nil))
          # Not passing in explanation, because it isn't approved
          expect(instance.to_markdown.gsub(/ \n/, "\n")).to eq "---\nid: #{hypothesis.ref_id}\nhypothesis: #{title}\ntopics: []\n#{conflicting_supporting_text}citations:\n---\n"
          # Passing it in (we regularly serialize unapproved explanations)
          expect(described_class.new(hypothesis: hypothesis, explanations: [explanation]).to_markdown.gsub(/ \n/, "\n")).to eq target
          # And if the explanation is approved, it renders too
          explanation.update(approved_at: Time.current - 1)
          new_instance = described_class.new(hypothesis: hypothesis)
          expect(new_instance.to_markdown.gsub(/ \n/, "\n")).to eq target
          expect_hashes_to_match(new_instance.as_json, relations_json)
        end
      end
    end
  end
end
