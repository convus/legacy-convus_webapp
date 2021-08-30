require "rails_helper"

RSpec.describe Argument, type: :model do
  it_behaves_like "GithubSubmittable"

  describe "factory" do
    let(:argument) { FactoryBot.create(:argument) }
    it "is valid" do
      expect(argument).to be_valid
      expect(argument.id).to be_present
      expect(argument.hypothesis).to be_present
      expect(argument.approved?).to be_falsey
    end
    context "approved" do
      let(:argument) { FactoryBot.create(:argument_approved) }
      it "is valid" do
        expect(argument).to be_valid
        expect(argument.id).to be_present
        expect(argument.hypothesis).to be_present
        expect(argument.approved?).to be_truthy
      end
    end
  end

  describe "parse_quotes" do
    context "empty" do
      let(:target) { [] }
      it "is empty" do
        expect(Argument.parse_quotes("   ")).to eq target
        expect(Argument.parse_quotes(" \n\nasdfasdf\n\nasdfasdf ")).to eq target

        expect(Argument.parse_quotes(">  \n")).to eq target
        expect(Argument.parse_quotes(">  \n\n > \n\n>")).to eq target
      end
    end
    context "single quote" do
      let(:target) { ["something"] }
      it "parses" do
        expect(Argument.parse_quotes("> something")).to eq target
        expect(Argument.parse_quotes("  >  something  \n\nother stuff")).to eq target
        expect(Argument.parse_quotes("\n> something")).to eq target
        expect(Argument.parse_quotes("\nsomething else\nAnd MORE things\n\n\n  >    something \n\nother things")).to eq target
      end
    end
    context "multi line block quotes" do
      let(:target) { ["multi line message"] }
      it "parses" do
        expect(Argument.parse_quotes("> multi line message ")).to eq target
        expect(Argument.parse_quotes("> multi\n> line   \n> message ")).to eq target
        expect(Argument.parse_quotes("Some stuff goes here\n > multi   \n >    line\n > message     \n\n\nAnd then more stuff")).to eq target
      end
    end
    context "multiple quotes" do
      let(:target) { ["something", "something else"] }
      it "parses" do
        expect(Argument.parse_quotes("> something\n\n>something else")).to eq target
        expect(Argument.parse_quotes("  >  something  \n blahhh blah blah\n \nother stuff\n >   something else")).to eq target
      end
    end
    context "multiple of the same quote" do
      let(:target) { ["something"] }
      it "parses" do
        expect(Argument.parse_quotes("> something\n\n>something")).to eq target
        expect(Argument.parse_quotes("  >  something  \n blahhh blah blah\n \nother stuff\n >   something")).to eq target
      end
    end
  end

  describe "update_from_text" do
    let(:argument) { FactoryBot.create(:argument) }
    let(:url1) { "https://otherthings.com/812383123123" }
    let(:text) { "New argument, where I prove things\n\n>I'm quoting stuff\n\nfinale" }
    it "creates" do
      expect(argument.argument_quotes.count).to eq 0
      expect(argument.body_html).to be_blank
      argument.update_from_text(text)
      argument.reload
      expect(argument.argument_quotes.count).to eq 1
      expect(argument.body_html).to be_present
      argument_quote = argument.argument_quotes.first
      expect(argument_quote.url).to be_blank
      expect(argument_quote.text).to eq "I'm quoting stuff"
      expect(argument_quote.ref_number).to eq 1
      # It finds by text, if the text is the same
      argument.update_from_text(text, quote_urls: [url1])
      argument_quote.reload
      expect(argument.body_html).to be_present
      expect(argument_quote.url).to eq url1
      expect(argument_quote.text).to eq "I'm quoting stuff"
      expect(argument_quote.ref_number).to eq 1
    end
    context "with argument_quotes" do
      let!(:argument_quote1) { FactoryBot.create(:argument_quote, argument: argument, url: "https://url.com/stufffff") }
      let!(:argument_quote2) { FactoryBot.create(:argument_quote, argument: argument, url: url1) }
      let!(:argument_quote3) { FactoryBot.create(:argument_quote, argument: argument, text: nil, url: nil) }
      it "updates the matching quote, deletes the other" do
        expect(argument_quote2.reload.ref_number).to eq 2
        expect(argument.reload.argument_quotes.count).to eq 3
        expect(argument.body_html).to be_blank
        argument.update_from_text(text, quote_urls: [url1])
        argument.reload
        expect(argument.body_html).to be_present
        expect(argument.argument_quotes.not_removed.count).to eq 1
        expect(argument.argument_quotes.removed.count).to eq 1
        argument_quote2.reload
        expect(argument_quote2.url).to eq url1
        expect(argument_quote2.text).to eq "I'm quoting stuff"
        expect(argument_quote2.ref_number).to eq 1
      end
    end
  end

  describe "parse_text" do
    let(:argument) { Argument.new(text: text) }
    it "returns empty" do
      expect(Argument.new.parse_text).to eq ""
      expect(Argument.new(text: "\n").parse_text).to eq ""
    end
    describe "markdown parsing stuff" do
      context "with some whitespace in between things" do
        let(:text) { "   something\n\n\nanother Thing\n\n\n > Blockquote here\n > more quote" }
        it "returns the expected content" do
          # NOTE: might want to replace new lines with
          expect(argument.parse_text).to eq "<p>something</p>\n\n<p>another Thing</p>\n\n<blockquote>\n<p>Blockquote here\nmore quote</p>\n</blockquote>\n"
          expect(argument.parse_text).to eq "<p>something</p>\n\n<p>another Thing</p>\n\n<blockquote>\n<p>Blockquote here\nmore quote</p>\n</blockquote>\n"
        end
      end
      context "with an image" do
        let(:text) { "I want to include an image ![image](https://creativecommons.org/images/deed/cc_icon_white_x2.png)" }
        it "returns the expected content" do
          expect(argument.parse_text).to eq "<p>#{text}</p>\n"
        end
        context "with an inline image" do
          let(:text) { "I want to include an <a href=\"https://creativecommons.org/images/deed/cc_icon_white_x2.png\">image</a>" }
          it "returns the expected content" do
            expect(argument.parse_text).to eq "<p>I want to include an image</p>\n"
          end
        end
      end
      context "with some headers" do
        let(:text) { "## Some Text\n\n#### More text" }
        it "returns without headers" do
          expect(argument.parse_text).to eq("<p>Some Text</p>\n\n<p>More text</p>\n")
        end
      end
      context "with a link" do
        let(:text) { "Something with [no link](https://link.com) <a href=\"http://link.com\">no link</a>" }
        it "returns the expected content" do
          expect(argument.parse_text).to eq "<p>Something with [no link](https://link.com) no link</p>\n"
        end
      end
      context "with a script tag" do
        let(:text) { "I want to <script>alert('hi')</script>" }
        it "returns the expected content" do
          expect(argument.parse_text).to eq "<p>I want to alert(&#39;hi&#39;)</p>\n"
        end
      end
      context "with a table" do
        let(:text) { " | t1 | t2 |\n| -- | -- |\n| tb1 | tb2 |" }
        let(:target) { "<table><thead>\n<tr>\n<th>t1</th>\n<th>t2</th>\n</tr>\n</thead><tbody>\n<tr>\n<td>tb1</td>\n<td>tb2</td>\n</tr>\n</tbody></table>\n" }
        it "renders" do
          expect(argument.parse_text).to eq target
        end
      end
    end
    context "with blockquote" do
      let(:url) { "http://example.com" }
      let(:quote_text) { "I believe that this is the solution to discussions of various things on the internet" }
      let(:argument_text) { "Something cool and stuff\n\n> #{quote_text}" }
      let(:argument) { FactoryBot.create(:argument, text: argument_text) }
      let!(:argument_quote) { FactoryBot.create(:argument_quote, argument: argument, text: quote_text, url: url) }
      let(:target) do
        "<p>Something cool and stuff</p>\n\n" \
          "<div class=\"argument-quote-block\">" \
          "<blockquote>\n<p>#{quote_text}</p>\n</blockquote>" \
          "<span class=\"source\">#{argument_quote.citation_ref_html}</span></div>\n"
      end
      it "does things" do
        expect(argument_quote.reload.ref_number).to eq 1 # Expect it to be set
        expect(argument_quote.citation_ref_html).to be_present
        expect(argument.reload.body_html).to be_blank
        expect(argument.ref_number).to eq 1
        expect(argument.listing_order).to eq 0
        # OMFG testing this was a bear. There is definitely to be a better way, but whatever
        real_lines = argument.parse_text_with_blockquotes.split("\n").reject(&:blank?)
        target_lines = target.split("\n").reject(&:blank?)
        real_lines.count.times { |i| expect(real_lines[i]).to eq target_lines[i] }
        expect(real_lines.count).to eq target_lines.count
        expect(real_lines).to eq target_lines

        expect(argument.parse_text_with_blockquotes).to eq target
        argument.update_body_html
        argument.reload
        expect(argument.body_html).to eq target
      end
      context "with a blockquote with markdown in it" do
        let(:url2) { "https://convus.org/this-this-this" }
        let(:argument_text) { "Something cool and stuff\n\n> #{quote_text}\n\n And another thing\n > This here **Rocks**\n" }
        let!(:argument_quote2) { FactoryBot.create(:argument_quote, argument: argument, text: "This here **Rocks**", url: url2) }
        let(:target_with_addition) do
          target +
            "\n<p>And another thing</p>\n\n" \
            "<div class=\"argument-quote-block\">" \
            "<blockquote>\n<p>This here <strong>Rocks</strong></p>\n</blockquote>" \
            "<span class=\"source\">#{argument_quote2.citation_ref_html}</span></div>\n"
        end
        it "renders" do
          expect(argument_quote.reload.ref_number).to eq 1
          expect(argument_quote.citation_ref_html).to be_present
          expect(argument_quote2.reload.ref_number).to eq 2
          expect(argument.reload.body_html).to be_blank
          # OMFG testing this was a bear. There is definitely to be a better way, but whatever
          real_lines = argument.parse_text_with_blockquotes.split("\n").reject(&:blank?)
          target_lines = target_with_addition.split("\n").reject(&:blank?)
          real_lines.count.times { |i| expect(real_lines[i]).to eq target_lines[i] }
          expect(real_lines.count).to eq target_lines.count
          expect(real_lines).to eq target_lines

          expect(argument.parse_text_with_blockquotes).to eq target_with_addition
          argument.update_body_html
          argument.reload
          expect(argument.body_html).to eq target_with_addition
        end
      end
    end
  end

  describe "shown" do
    let(:user) { FactoryBot.create(:user) }
    let!(:argument1) { FactoryBot.create(:argument) }
    let(:hypothesis) { argument1.hypothesis }
    let!(:argument2) { FactoryBot.create(:argument, creator: user, hypothesis: hypothesis) }
    let!(:argument3) { FactoryBot.create(:argument_approved, hypothesis: hypothesis) }
    let!(:argument4) { FactoryBot.create(:argument, creator: user) }
    it "returns users and approved" do
      expect(Argument.where(creator_id: user.id).pluck(:id)).to match_array([argument2.id, argument4.id])
      expect(Argument.shown(user).pluck(:id)).to match_array([argument2.id, argument3.id, argument4.id])
      expect(Argument.shown.pluck(:id)).to match_array([argument3.id])
      expect(hypothesis.reload.arguments.shown(user).pluck(:id)).to match_array([argument2.id, argument3.id])
      expect(hypothesis.reload.arguments.shown.pluck(:id)).to match_array([argument3.id])
    end
  end

  describe "url" do
    let(:url) { "https://example.com/stuff?utm_things=asdfasdf" }
    let(:argument) { FactoryBot.create(:argument, creator: FactoryBot.create(:user)) }
    let!(:argument_quote) { FactoryBot.build(:argument_quote, argument: argument, url: url, citation: nil, creator: nil) }
    it "creates the citation" do
      expect {
        argument_quote.save
      }.to change(Citation, :count).by 1
      expect(argument_quote.url).to eq "https://example.com/stuff"
      expect(argument_quote.argument.creator).to be_present
      citation = argument_quote.citation
      expect(citation.url).to eq argument_quote.url
      expect(citation.creator_id).to eq argument_quote.argument.creator_id
    end
    context "citation already exists" do
      let!(:citation) { FactoryBot.create(:citation, url: url, creator: nil) }
      it "associates with the existing citation" do
        expect(citation).to be_valid
        expect(citation.creator_id).to be_blank
        expect {
          argument_quote.save
        }.to change(Citation, :count).by 0
        expect(argument_quote.citation_id).to eq citation.id
        expect(citation.creator_id).to be_blank
      end
    end
    context "citation changed" do
      it "updates to a new citation" do
        argument_quote.save
        citation1 = argument_quote.citation
        expect(citation1).to be_valid
        argument_quote.update(url: "https://example.com/other-stuff")
        expect(argument_quote.citation.id).to_not eq citation1.id
        citation1.reload
        expect(citation1).to be_valid
      end
    end
  end
end
