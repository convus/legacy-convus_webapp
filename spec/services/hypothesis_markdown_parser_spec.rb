# frozen_string_literal: true

require "rails_helper"

RSpec.describe HypothesisMarkdownParser do
  let(:subject) { described_class }
  let(:instance) { subject.new(file_content: file_content) }

  describe "some calculated content" do
    let(:ref_id) { "3J4" }
    let(:title) { "Some cool title." }
    let(:url1) { "https://convus.org/hypotheses/something" }
    let(:published_date_str) { "2021-09-08" }
    let(:target_front_matter) do
      {id: ref_id,
       hypothesis: title,
       topics: ["A Topic"],
       citations: {
         url1 => {title: "A Special Title", published_date: published_date_str, publication_title: "Convus"}
       }}
    end
    let(:explanation_text) { "Let's talk about some stuff here\n\n> With a quote\n> ref:#{url1}" }
    let(:file_content) do
      "---\nid: #{ref_id}\nhypothesis: #{title}\ntopics:\n- A Topic\n" \
      "citations:\n  #{url1}:\n    title: A Special Title\n    published_date: "\
      "'#{published_date_str}'\n    publication_title: Convus\n---\n## Explanation 1\n\n#{explanation_text}"
    end

    describe "front_matter" do
      it "gets the front_matter" do
        expect(instance.split_content.count).to eq 2
        expect_hashes_to_match(instance.front_matter, target_front_matter)
      end
      context "missing leading ---" do
        # Seems like an easy thing for someone to do, so handle it
        let(:instance) { subject.new(file_content: file_content.gsub(/\A---\n/, "")) }
        it "gets the front_matter" do
          expect_hashes_to_match(instance.front_matter, target_front_matter)
        end
      end
    end

    describe "explanations" do
      it "gets the explanation" do
        expect(instance.explanations.count).to eq 1
        expect(instance.explanations.keys.first).to eq "1"
        explanation = instance.explanations.values.first
        expect(explanation).to eq explanation_text
      end
      context "missing leading ## Explanation" do
        # Seems like an easy thing for someone to do, so handle it
        let(:instance) { subject.new(file_content: file_content.gsub(/## Explanation [^\n]*/, "")) }
        it "gets the explanation" do
          expect(instance.explanations.count).to eq 1
          expect(instance.explanations.keys.first).to eq "1"
          explanation = instance.explanations.values.first
          expect(explanation).to eq explanation_text
        end
      end
      context "second Explanation" do
        let(:explanation_text2) { "Something Cool and whatever\netc" }
        let(:explanation2_number) { 222 }
        # Seems like an easy thing for someone to do, so handle it
        let(:instance) { subject.new(file_content: "#{file_content}\n\n## Explanation #{explanation2_number}\n\n#{explanation_text2}") }
        it "gets the explanation" do
          expect(instance.explanations.count).to eq 2
          expect(instance.explanations.keys.first).to eq "1"
          explanation = instance.explanations.values.first
          expect(explanation).to eq explanation_text
          expect(instance.explanations.keys.last).to eq "222"
          explanation2 = instance.explanations.values.last
          expect(explanation2).to eq explanation_text2
        end
        context "duplicate number" do
          let(:explanation2_number) { 1 }
          it "sets a good number" do
            expect(instance.explanations.count).to eq 2
            expect(instance.explanations.keys.first).to eq "1"
            explanation = instance.explanations.values.first
            expect(explanation).to eq explanation_text
            expect(instance.explanations.keys.last).to eq "2"
            explanation2 = instance.explanations.values.last
            expect(explanation2).to eq explanation_text2
          end
        end
      end
    end

    describe "import" do
      it "imports" do
        expect(Hypothesis.count).to eq 0
        expect(Explanation.count).to eq 0
        instance.import
        expect(Hypothesis.count).to eq 1
        expect(Explanation.count).to eq 1

        hypothesis = Hypothesis.last
        expect(hypothesis.title).to eq title
        expect(hypothesis.tags_string).to eq "A Topic"
        expect(hypothesis.approved?).to be_truthy

        expect(hypothesis.explanations.count).to eq 1
        explanation = Explanation.first
        expect(explanation.text).to eq explanation_text.gsub(/\n> ref:.*/, "")
        expect(explanation.approved?).to be_truthy

        expect(explanation.explanation_quotes.count).to eq 1
        explanation_quote = explanation.explanation_quotes.first
        expect(explanation_quote.text).to eq "With a quote"
        expect(explanation_quote.url).to eq url1
        expect(explanation_quote.citation.published_date_str).to eq published_date_str
        expect(explanation_quote.citation.publication_title).to eq "Convus"
        expect(explanation_quote.citation.approved?).to be_truthy
      end
      context "hypothesis relations" do
        let!(:hypothesis_conflicting) { FactoryBot.create(:hypothesis_approved) }
        let!(:hypothesis_supporting) { FactoryBot.create(:hypothesis_approved) }
        let(:relations_attributes) { {conflicting: [hypothesis_conflicting.title_with_ref_id], supporting: [hypothesis_supporting.ref_id]} }
        it "imports all the acceptable attributes, skips unknown citation" do
          expect(Hypothesis.count).to eq 2
          expect(HypothesisRelation.count).to eq 0
          expect(Explanation.count).to eq 0
          allow_any_instance_of(described_class).to receive(:front_matter) { target_front_matter.merge(relations_attributes) }
          instance.import
          expect(Hypothesis.count).to eq 3
          expect(Explanation.count).to eq 1

          hypothesis = Hypothesis.last
          expect(hypothesis.title).to eq title
          expect(hypothesis.tags_string).to eq "A Topic"
          expect(hypothesis.approved?).to be_truthy
          expect(hypothesis.supporting_hypotheses.pluck(:id)).to eq([hypothesis_supporting.id])
          expect(hypothesis.conflicting_hypotheses.pluck(:id)).to eq([hypothesis_conflicting.id])

          expect(hypothesis.explanations.count).to eq 1
          explanation = Explanation.first
          expect(explanation.text).to eq explanation_text.gsub(/\n> ref:.*/, "")
          expect(explanation.approved?).to be_truthy
        end
      end
      context "overflown citation attributes" do
        let(:citations_attributes) do
          {
            url1 => {
              id: "party",
              explanation_quote_id: 11112,
              title: "Really cool Title",
              published_date: published_date_str,
              publication_title: "Convus",
              authors_str: "George; Scott",
              kind: "research with randomized controlled trial",
              url_is_direct_link_to_full_text: true,
              doi: "https://doi.org/10.1038/s41467-020-17316-z",
              url_is_not_publisher: true,
              peer_reviewed: true,
              randomized_controlled_trial: true
            },
            "https://example2.com/something" => {title: "Other Title", published_date: "2021-2-1"}
          }
        end
        it "imports all the acceptable attributes, skips unknown citation" do
          expect(Hypothesis.count).to eq 0
          expect(Explanation.count).to eq 0
          allow_any_instance_of(described_class).to receive(:front_matter) { target_front_matter.merge(citations: citations_attributes) }
          instance.import
          expect(Hypothesis.count).to eq 1
          expect(Explanation.count).to eq 1

          hypothesis = Hypothesis.last
          expect(hypothesis.title).to eq title
          expect(hypothesis.tags_string).to eq "A Topic"
          expect(hypothesis.approved?).to be_truthy

          expect(hypothesis.explanations.count).to eq 1
          explanation = Explanation.first
          expect(explanation.text).to eq explanation_text.gsub(/\n> ref:.*/, "")
          expect(explanation.approved?).to be_truthy

          expect(explanation.explanation_quotes.count).to eq 1
          explanation_quote = explanation.explanation_quotes.first
          expect(explanation_quote.text).to eq "With a quote"
          expect(explanation_quote.url).to eq url1
          citation = explanation_quote.citation
          expect_attrs_to_match_hash(citation, citations_attributes[url1].except(:id, :explanation_quote_id, :kind))
          expect(citation.authors.count).to eq 2
          expect(citation.kind).to eq "research_with_rct"
          expect(citation.id).to_not eq "party"
        end
      end
    end
  end
end
