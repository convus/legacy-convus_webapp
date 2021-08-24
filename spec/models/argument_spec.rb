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
  end
end
