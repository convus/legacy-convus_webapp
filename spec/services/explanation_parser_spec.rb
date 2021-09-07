# frozen_string_literal: true

require "rails_helper"

RSpec.describe ExplanationParser do
  let(:subject) { described_class }

  describe "quotes" do
    let(:url1) { nil }
    let(:target) { [{text: text, url: url1}] }
    context "empty" do
      let(:target) { [] }
      it "is empty" do
        expect(ExplanationParser.quotes("   ")).to eq target
        expect(ExplanationParser.quotes_with_urls(" \n\nasdfasdf\n\nasdfasdf ")).to eq target

        expect(ExplanationParser.quotes_with_urls(">  \n")).to eq target
        expect(ExplanationParser.quotes_with_urls(">  \n\n > \n\n>")).to eq target
      end
    end
    context "single quote" do
      let(:text) { "something" }
      it "parses" do
        expect(ExplanationParser.quotes("> something")).to eq([text])
        expect(ExplanationParser.quotes_with_urls("> something")).to eq target
        expect(ExplanationParser.quotes_with_urls("  >  something  \n\nother stuff")).to eq target
        expect(ExplanationParser.quotes_with_urls("\n> something")).to eq target
        expect(ExplanationParser.quotes_with_urls("\nsomething else\nAnd MORE things\n\n\n  >    something \n\nother things")).to eq target
      end
      context "with url" do
        let(:url1) { "https://stuff.com/things" }
        it "parses with passed in url" do
          expect(ExplanationParser.quotes_with_urls("> something", urls: [url1])).to eq target
          expect(ExplanationParser.quotes_with_urls("  >  something  \n\nother stuff", urls: [url1])).to eq target
          expect(ExplanationParser.quotes_with_urls("\n> something", urls: [url1])).to eq target
          expect(ExplanationParser.quotes_with_urls("\nsomething else\nAnd MORE things\n\n\n  >    something \n\nother things", urls: [url1])).to eq target
        end
        it "parses URL out of text" do
          expect(ExplanationParser.quotes_with_urls("> something\n> reference: #{url1}")).to eq target
          expect(ExplanationParser.quotes_with_urls("  >  something  \n> reference:#{url1}\n\nother stuff")).to eq target
          # Text url overrides passed in URLs
          expect(ExplanationParser.quotes_with_urls("\n> something\n> reference:#{url1}", urls: ["https://notit.com"])).to eq target
          expect(ExplanationParser.quotes_with_urls("\nsomething else\nAnd MORE things\n\n\n  >    something \n>reference:   #{url1}\n\n\nother things")).to eq target
        end
      end
    end
    context "multi line block quotes" do
      let(:text) { "multi line message" }
      it "parses" do
        expect(ExplanationParser.quotes_with_urls("> multi line message ")).to eq target
        expect(ExplanationParser.quotes_with_urls("> multi\n> line   \n> message ")).to eq target
        expect(ExplanationParser.quotes_with_urls("Some stuff goes here\n > multi   \n >    line\n > message     \n\n\nAnd then more stuff")).to eq target
      end
      context "with url" do
        let(:url1) { "http://exampleexampleexample.com/article/2021-9-6.html?query=true" }
        it "parses" do
          expect(ExplanationParser.quotes_with_urls("> multi\n> line   \n> message \n>reference:#{url1}")).to eq target
          expect(ExplanationParser.quotes_with_urls("> multi\n> line   \n> message \n\n", urls: [url1])).to eq target
        end
      end
    end
    context "multiple quotes" do
      let(:url2) { nil }
      let(:target) { [{text: "something", url: url1}, {text: "something else", url: url2}] }
      it "parses" do
        expect(ExplanationParser.quotes_with_urls("> something\n\n> something else")).to eq target
        expect(ExplanationParser.quotes_with_urls("  >  something  \n blahhh blah blah\n \nother stuff\n >   something else")).to eq target
      end
      context "with urls" do
        let(:url1) { "http://exampleexampleexample.com/article/2021-9-6.html?query=true" }
        let(:url2) { "https://stuff.com/things" }
        it "parses" do
          expect(ExplanationParser.quotes_with_urls("> something\n\n> something else", urls: [url1, url2])).to eq target
          expect(ExplanationParser.quotes_with_urls("> something\n>reference: #{url1}\n\n> something else\n>reference:#{url2}")).to eq target
          expect(ExplanationParser.quotes_with_urls("  >  something  \n blahhh blah blah\n \nother stuff\n >   something else", urls: [url1, url2])).to eq target
          expect(ExplanationParser.quotes_with_urls("  >  something  \n > reference:#{url1}  \n  blahhh blah blah\n \nother stuff\n >   something else", urls: ["http://stuff.com", url2])).to eq target
        end
      end
    end
    context "multiple of the same quote" do
      let(:text) { "something" }
      it "parses" do
        expect(ExplanationParser.quotes("> something\n\n>something")).to eq([text])
        expect(ExplanationParser.quotes_with_urls("> something\n\n>something")).to eq target
        expect(ExplanationParser.quotes_with_urls("  >  something  \n blahhh blah blah\n \nother stuff\n >   something")).to eq target
      end
    end
  end
end
