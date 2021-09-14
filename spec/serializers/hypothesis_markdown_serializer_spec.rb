# frozen_string_literal: true

require "rails_helper"

describe HypothesisMarkdownSerializer, type: :lib do
  # Set ref number to make sure it isn't just integers, which get wrapped in quotes
  let(:hypothesis) { FactoryBot.create(:hypothesis_approved, title: title, ref_number: 122) }
  let(:title) { "Some cool title." }
  let(:instance) { described_class.new(hypothesis: hypothesis) }

  def normalized_markdown_for(hypothesis_or_instance, explanations = nil)
    if hypothesis_or_instance.is_a?(Hypothesis)
      described_class.new(hypothesis: hypothesis_or_instance, explanations: explanations)
    else
      hypothesis_or_instance
    end.to_markdown.gsub(/ \n/, "\n")
  end

  describe "to_flat_file" do
    context "no explanation, with topics" do
      let(:target_json) { {id: hypothesis.ref_id, hypothesis: title, topics: ["A Topic"], supporting: nil, conflicting: nil, citations: nil} }
      let(:target) { "---\nid: #{hypothesis.ref_id}\nhypothesis: #{title}\ntopics:\n- A Topic\nsupporting:\nconflicting:\ncitations:\n---\n" }
      it "returns" do
        hypothesis.update(tags_string: "A Topic")
        expect(hypothesis.tag_titles).to eq(["A Topic"])
        expect_hashes_to_match(instance.as_json, target_json)
        expect(normalized_markdown_for(instance)).to eq target
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
      let(:pre_relations) { "---\nid: #{hypothesis.ref_id}\nhypothesis: #{title}\ntopics: []\n" }
      let(:post_relations) do
        "citations:\n  #{url1}:\n    title: A Special Title\n    published_date: "\
        "'#{published_date_str}'\n    publication_title: Convus\n---\n## Explanation 1\n\n#{explanation_text}"
      end
      let(:target) { [pre_relations, conflicting_supporting_text, post_relations].join }

      it "serializes" do
        expect(hypothesis.reload.approved?).to be_truthy
        expect(explanation.reload.text_with_references).to eq explanation_text
        expect(explanation.explanation_quotes.count).to eq 1
        expect(explanation_quote.citation_id).to eq citation.id
        expect(citation.publication_title).to eq "Convus"
        expect(citation.published_date_str).to eq published_date_str
        expect_hashes_to_match(instance.as_json, target_json.merge(citations: nil))
        # Not passing in explanation, because it isn't approved
        expect(normalized_markdown_for(instance)).to eq "#{pre_relations}#{conflicting_supporting_text}citations:\n---\n"
        # Passing it in (we regularly serialize unapproved explanations)
        expect(normalized_markdown_for(hypothesis, [explanation])).to eq target
        # And if the explanation is approved, it renders too
        explanation.update(approved_at: Time.current - 1)
        expect(normalized_markdown_for(hypothesis)).to eq target
        expect_hashes_to_match(described_class.new(hypothesis: hypothesis).as_json, target_json)
      end
      context "with relations" do
        let(:hypothesis_conflicting) { FactoryBot.create(:hypothesis_approved) }
        let(:hypothesis_supporting) { FactoryBot.create(:hypothesis_approved) }
        let!(:hypothesis_relation_conflicting) { HypothesisRelation.find_or_create_for(kind: "hypothesis_conflict", hypotheses: [hypothesis_conflicting, hypothesis]) }
        let!(:hypothesis_relation_supporting) { HypothesisRelation.find_or_create_for(kind: "hypothesis_support", hypotheses: [hypothesis_supporting, hypothesis]) }
        let(:relations_json) { target_json.merge(conflicting: [hypothesis_conflicting.title_with_ref_id], supporting: [hypothesis_supporting.title_with_ref_id]) }
        let(:conflicting_supporting_text) { "supporting:\n- '#{hypothesis_supporting.title_with_ref_id}'\nconflicting:\n- '#{hypothesis_conflicting.title_with_ref_id}'\n" }
        it "serializes" do
          expect(hypothesis.reload.approved?).to be_truthy
          expect(explanation.reload.text_with_references).to eq explanation_text
          expect(hypothesis_relation_conflicting.reload.approved?).to be_falsey
          expect(hypothesis_relation_supporting.reload.approved?).to be_falsey
          expect_hashes_to_match(instance.as_json, target_json.merge(citations: nil))
          # Not passing in explanation
          expect(normalized_markdown_for(instance)).to eq "#{pre_relations}supporting:\nconflicting:\ncitations:\n---\n"
          # Passing it in (we regularly serialize unapproved explanations)
          expect(normalized_markdown_for(hypothesis, [explanation])).to eq "#{pre_relations}supporting:\nconflicting:\n#{post_relations}"
          # Approve everything
          [hypothesis, explanation, hypothesis_relation_conflicting, hypothesis_relation_supporting].each { |obj| obj.update(approved_at: Time.current - 1) }
          # And if the explanation is approved, it renders too
          hypothesis.reload
          expect(normalized_markdown_for(hypothesis)).to eq target
          expect_hashes_to_match(described_class.new(hypothesis: hypothesis).as_json, relations_json)
        end
        context "with unapproved hypothesis" do
          let(:hypothesis) { FactoryBot.create(:hypothesis, title: title, ref_number: 122) }
          let(:hypothesis_conflicting_unapproved) { FactoryBot.create(:hypothesis) }
          let!(:hypothesis_relation_conflicting_unapproved) { HypothesisRelation.find_or_create_for(kind: "hypothesis_conflict", hypotheses: [hypothesis_conflicting_unapproved, hypothesis]) }
          it "serializes" do
            expect(hypothesis.reload.approved?).to be_falsey
            expect(explanation.reload.text_with_references).to eq explanation_text
            expect(hypothesis_relation_conflicting.reload.approved?).to be_falsey
            expect(hypothesis_relation_supporting.reload.approved?).to be_falsey
            expect(hypothesis_relation_conflicting_unapproved.reload.approved?).to be_falsey
            # If a user creates two hypotheses, and creates relations for them, then submits one for approval -
            # the one that isn't approved (or submitted) shouldn't be included
            expect_hashes_to_match(instance.as_json, relations_json.merge(citations: nil))
            # It doesn't include
            expect(normalized_markdown_for(instance)).to eq "#{pre_relations}#{conflicting_supporting_text}citations:\n---\n"
            # Passing it in (we regularly serialize unapproved explanations)
            expect(normalized_markdown_for(hypothesis, [explanation])).to eq target
            # Approve everything
            [hypothesis, explanation, hypothesis_relation_conflicting, hypothesis_relation_supporting].each { |obj| obj.update(approved_at: Time.current - 1) }
            hypothesis.reload
            expect(normalized_markdown_for(hypothesis)).to eq target
            expect_hashes_to_match(described_class.new(hypothesis: hypothesis).as_json, relations_json)
          end
        end
      end
    end
  end
end
