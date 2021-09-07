# frozen_string_literal: true

require "rails_helper"

RSpec.describe ExplanationParser do
  let(:subject) { described_class }

  describe "parse_quotes" do
    let(:url1) { nil }
    let(:target) { [{text: text, url: url1}] }
    context "empty" do
      let(:target) { [] }
      it "is empty" do
        expect(ExplanationParser.parse_quotes("   ")).to eq target
        expect(ExplanationParser.parse_quotes(" \n\nasdfasdf\n\nasdfasdf ")).to eq target

        expect(ExplanationParser.parse_quotes(">  \n")).to eq target
        expect(ExplanationParser.parse_quotes(">  \n\n > \n\n>")).to eq target
      end
    end
    context "single quote" do
      let(:text) { "something" }
      it "parses" do
        expect(ExplanationParser.parse_quotes("> something")).to eq target
        expect(ExplanationParser.parse_quotes("  >  something  \n\nother stuff")).to eq target
        expect(ExplanationParser.parse_quotes("\n> something")).to eq target
        expect(ExplanationParser.parse_quotes("\nsomething else\nAnd MORE things\n\n\n  >    something \n\nother things")).to eq target
      end
      context "with url" do
        let(:url1) { "https://stuff.com/things" }
        it "parses with passed in url" do
          expect(ExplanationParser.parse_quotes("> something", urls: [url1])).to eq target
          expect(ExplanationParser.parse_quotes("  >  something  \n\nother stuff", urls: [url1])).to eq target
          expect(ExplanationParser.parse_quotes("\n> something", urls: [url1])).to eq target
          expect(ExplanationParser.parse_quotes("\nsomething else\nAnd MORE things\n\n\n  >    something \n\nother things", urls: [url1])).to eq target
        end
        it "parses URL out of text" do
          expect(ExplanationParser.parse_quotes("> something\n> reference: #{url1}")).to eq target
          expect(ExplanationParser.parse_quotes("  >  something  \n> reference:#{url1}\n\nother stuff")).to eq target
          # Text url overrides passed in URLs
          expect(ExplanationParser.parse_quotes("\n> something\n> reference:#{url1}", urls: ["https://notit.com"])).to eq target
          expect(ExplanationParser.parse_quotes("\nsomething else\nAnd MORE things\n\n\n  >    something \n>reference:   #{url1}\n\n\nother things")).to eq target
        end
      end
    end
    context "multi line block quotes" do
      let(:text) { "multi line message" }
      it "parses" do
        expect(ExplanationParser.parse_quotes("> multi line message ")).to eq target
        expect(ExplanationParser.parse_quotes("> multi\n> line   \n> message ")).to eq target
        expect(ExplanationParser.parse_quotes("Some stuff goes here\n > multi   \n >    line\n > message     \n\n\nAnd then more stuff")).to eq target
      end
      context "with url" do
        let(:url) { "http://exampleexampleexample.com/article/2021-9-6.html?query=true" }
        it "parses" do
        end
      end
    end
    context "multiple quotes" do
      let(:target) { [{text: "something", url: url1}, {text: "something else", url: url2}] }
      it "parses" do
        expect(ExplanationParser.parse_quotes("> something\n\n> something else")).to eq target
        expect(ExplanationParser.parse_quotes("  >  something  \n blahhh blah blah\n \nother stuff\n >   something else")).to eq target
      end
    end
    context "multiple of the same quote" do
      let(:target) { ["something"] }
      it "parses" do
        expect(ExplanationParser.parse_quotes("> something\n\n>something")).to eq target
        expect(ExplanationParser.parse_quotes("  >  something  \n blahhh blah blah\n \nother stuff\n >   something")).to eq target
      end
    end
  end
end
