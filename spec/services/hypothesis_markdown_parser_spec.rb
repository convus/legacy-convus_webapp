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
        expect_hashes_to_match(instance.front_matter, target_front_matter)
      end
      context "missing leading ---" do
        # Seems like an easy thing for someone to do
        let(:instance) { subject.new(file_content: file_content.gsub(/\A---\n/, "")) }
        it "gets the front_matter" do
          expect_hashes_to_match(instance.front_matter, target_front_matter)
        end
      end
    end

    describe "import" do
      xit "imports" do
        expect(Hypothesis.count).to eq 0
        expect(Explanation.count).to eq 0
        instance.import
        expect(Hypothesis.count).to eq 1
        expect(Explanation.count).to eq 1
      end
    end
  end
end
