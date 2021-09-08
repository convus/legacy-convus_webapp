# frozen_string_literal: true

require "rails_helper"

RSpec.describe ExplanationParser do
  let(:subject) { described_class }
  let(:instance) { subject.new(explanation: explanation) }

  describe "parse_text_nodes, text_with_references" do
    let(:explanation) { FactoryBot.create(:explanation, text: text) }
    let(:url1) { nil }
    let(:text) { "New explanation, where I prove things\n\n>I'm quoting stuff\n\nfinale" }
    let(:text_with_references) { "New explanation, where I prove things\n\n> I'm quoting stuff\n> ref:#{url1}\n\nfinale" }
    let(:target) { ["New explanation, where I prove things\n", {quote: "I'm quoting stuff", url: url1}, "\nfinale"] }
    it "returns" do
      expect(instance.parse_text_nodes).to eq target
      expect(instance.text_with_references).to eq text_with_references
    end
    context "text with url" do
      let(:url1) { "https://otherthings.com/812383123123" }
      let(:text) { text_with_references }
      it "returns" do
        expect(instance.parse_text_nodes).to eq target
        expect(instance.text_with_references).to eq text_with_references
        expect(instance.text_no_references).to eq "New explanation, where I prove things\n\n> I'm quoting stuff\n\nfinale"
      end
    end
    context "with explanation_quotes" do
      let(:url1) { "https://example.com/something?quote=true" }
      let(:url2) { "https://url.com/stufffff" }
      let(:removed) { true }
      let!(:explanation_quote1) { FactoryBot.create(:explanation_quote, explanation: explanation, url: url2, removed: removed, ref_number: 1) }
      let!(:explanation_quote2) { FactoryBot.create(:explanation_quote, explanation: explanation, url: url1, ref_number: 2) }
      let!(:explanation_quote3) { FactoryBot.create(:explanation_quote, explanation: explanation, text: nil, url: nil, ref_number: 3) }
      it "returns" do
        expect(explanation_quote2.reload.ref_number).to eq 2
        expect(explanation.reload.explanation_quotes.count).to eq 3
        expect(instance.parse_text_nodes).to eq target
        # With passing in a URL
        target_different_url = [target[0], target[1].merge(url: url2), target[2]]
        expect(instance.parse_text_nodes(urls: [url2])).to eq target_different_url
        expect(instance.text_with_references).to eq text_with_references
      end
      context "with multiple quotes" do
        let(:removed) { false }
        let(:text) { "Here is a statement\nand it continues on to a new line\n> A quote goes\n> here\nSomething in the middle\n> Another quote goes here\n Something at the end" }
        let(:target) do
          [
            "Here is a statement\nand it continues on to a new line", # NOTE: need to decide whether to strip out unrendered newlines
            {quote: "A quote goes\nhere", url: url2},
            "Something in the middle",
            {quote: "Another quote goes here", url: url1},
            "Something at the end"
          ]
        end
        let(:text_with_references) do
          "Here is a statement\nand it continues on to a new line\n\n" \
           "> A quote goes\n> here\n> ref:#{url2}" \
           "\n\nSomething in the middle\n\n" \
           "> Another quote goes here\n> ref:#{url1}" \
           "\n\nSomething at the end"
        end
        it "returns" do
          expect(explanation_quote2.reload.ref_number).to eq 2
          expect(explanation.reload.explanation_quotes.count).to eq 3
          expect(instance.parse_text_nodes).to eq target
          expect(instance.text_with_references).to eq text_with_references
        end
      end
    end
  end
end
