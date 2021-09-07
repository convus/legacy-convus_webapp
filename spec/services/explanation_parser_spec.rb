# frozen_string_literal: true

require "rails_helper"

RSpec.describe ExplanationParser do
  let(:subject) { described_class }
  let(:instance) { subject.new(explanation: explanation) }

  describe "quotes" do
    let(:url1) { nil }
    let(:target) { [{quote: text, url: url1}] }
    context "empty" do
      let(:target) { [] }
      it "is empty" do
        expect(subject.quotes("   ")).to eq target
        expect(subject.quotes_with_urls(" \n\nasdfasdf\n\nasdfasdf ")).to eq target

        expect(subject.quotes_with_urls(">  \n")).to eq target
        expect(subject.quotes_with_urls(">  \n\n > \n\n>")).to eq target
      end
    end
    context "single quote" do
      let(:text) { "something" }
      it "parses" do
        expect(subject.quotes("> something")).to eq([text])
        expect(subject.quotes_with_urls("> something")).to eq target
        expect(subject.quotes_with_urls("  >  something  \n\nother stuff")).to eq target
        expect(subject.quotes_with_urls("\n> something")).to eq target
        expect(subject.quotes_with_urls("\nsomething else\nAnd MORE things\n\n\n  >    something \n\nother things")).to eq target
      end
      context "with url" do
        let(:url1) { "https://stuff.com/things" }
        it "parses with passed in url" do
          expect(subject.quotes_with_urls("> something", urls: [url1])).to eq target
          expect(subject.quotes_with_urls("  >  something  \n\nother stuff", urls: [url1])).to eq target
          expect(subject.quotes_with_urls("\n> something", urls: [url1])).to eq target
          expect(subject.quotes_with_urls("\nsomething else\nAnd MORE things\n\n\n  >    something \n\nother things", urls: [url1])).to eq target
        end
        it "parses URL out of text" do
          expect(subject.quotes_with_urls("> something\n> reference: #{url1}")).to eq target
          expect(subject.quotes_with_urls("  >  something  \n> reference:#{url1}\n\nother stuff")).to eq target
          # Text url overrides passed in URLs
          expect(subject.quotes_with_urls("\n> something\n> reference:#{url1}", urls: ["https://notit.com"])).to eq target
          expect(subject.quotes_with_urls("\nsomething else\nAnd MORE things\n\n\n  >    something \n>reference:   #{url1}\n\n\nother things")).to eq target
        end
      end
    end
    context "multi line block quotes" do
      let(:text) { "multi\nline\nmessage" }
      it "parses" do
        expect(subject.quotes_with_urls("> multi\n> line   \n> message ")).to eq target
        expect(subject.quotes_with_urls("Some stuff goes here\n > multi   \n >    line\n > message     \n\n\nAnd then more stuff")).to eq target
      end
      context "with url" do
        let(:url1) { "http://exampleexampleexample.com/article/2021-9-6.html?query=true" }
        it "parses" do
          expect(subject.quotes_with_urls("> multi\n> line   \n> message \n>reference:#{url1}")).to eq target
          expect(subject.quotes_with_urls("> multi\n> line   \n> message \n\n", urls: [url1])).to eq target
        end
      end
    end
    context "multiple quotes" do
      let(:url2) { nil }
      let(:target) { [{quote: "something", url: url1}, {quote: "something else", url: url2}] }
      it "parses" do
        expect(subject.quotes_with_urls("> something\n\n> something else")).to eq target
        expect(subject.quotes_with_urls("  >  something  \n blahhh blah blah\n \nother stuff\n >   something else")).to eq target
      end
      context "with urls" do
        let(:url1) { "http://exampleexampleexample.com/article/2021-9-6.html?query=true" }
        let(:url2) { "https://stuff.com/things" }
        it "parses" do
          expect(subject.quotes_with_urls("> something\n\n> something else", urls: [url1, url2])).to eq target
          expect(subject.quotes_with_urls("> something\n>reference: #{url1}\n\n> something else\n>reference:#{url2}")).to eq target
          expect(subject.quotes_with_urls("  >  something  \n blahhh blah blah\n \nother stuff\n >   something else", urls: [url1, url2])).to eq target
          expect(subject.quotes_with_urls("  >  something  \n > reference:#{url1}  \n  blahhh blah blah\n \nother stuff\n >   something else", urls: ["http://stuff.com", url2])).to eq target
        end
      end
    end
    context "multiple of the same quote" do
      let(:text) { "something" }
      it "parses" do
        expect(subject.quotes("> something\n\n>something")).to eq([text])
        expect(subject.quotes_with_urls("> something\n\n>something")).to eq target
        expect(subject.quotes_with_urls("  >  something  \n blahhh blah blah\n \nother stuff\n >   something")).to eq target
      end
    end
  end

  describe "parse_text_nodes" do
    let(:explanation) { FactoryBot.create(:explanation, text: text) }
    let(:url1) { nil }
    let(:text) { "New explanation, where I prove things\n\n>I'm quoting stuff\n\nfinale" }
    let(:target) { ["New explanation, where I prove things\n", {quote: "I'm quoting stuff", url: url1}, "\nfinale"] }
    it "returns" do
      expect(instance.parse_text_nodes).to eq target
    end
    context "text with url" do
      let(:url1) { "https://otherthings.com/812383123123" }
      let(:text) { "New explanation, where I prove things\n\n>I'm quoting stuff\n> reference: #{url1}\n\nfinale" }
      it "returns" do
        expect(instance.parse_text_nodes).to eq target
      end
    end
    context "with explanation_quotes" do
      let(:url2) { "https://url.com/stufffff" }
      let!(:explanation_quote1) { FactoryBot.create(:explanation_quote, explanation: explanation, url: url2, removed: true) }
      let!(:explanation_quote2) { FactoryBot.create(:explanation_quote, explanation: explanation, url: url1) }
      let!(:explanation_quote3) { FactoryBot.create(:explanation_quote, explanation: explanation, text: nil, url: nil) }
      it "updates the matching quote, deletes the other" do
        expect(explanation_quote2.reload.ref_number).to eq 2
        expect(explanation.reload.explanation_quotes.count).to eq 3
        expect(instance.parse_text_nodes).to eq target
        # With passing in a URL
        target_different_url = [target[0], target[1].merge(url: url2), target[2]]
        expect(instance.parse_text_nodes(urls: [url2])).to eq target_different_url
      end
    end
  end
end
