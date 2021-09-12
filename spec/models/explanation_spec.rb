require "rails_helper"

RSpec.describe Explanation, type: :model do
  it_behaves_like "GithubSubmittable"

  describe "factory" do
    let(:explanation) { FactoryBot.create(:explanation) }
    it "is valid" do
      expect(explanation).to be_valid
      expect(explanation.id).to be_present
      expect(explanation.hypothesis).to be_present
      expect(explanation.approved?).to be_falsey
    end
    context "approved" do
      let(:explanation) { FactoryBot.create(:explanation_approved) }
      it "is valid" do
        expect(explanation).to be_valid
        expect(explanation.id).to be_present
        expect(explanation.hypothesis).to be_present
        expect(explanation.approved?).to be_truthy
      end
    end
  end

  describe "calculated_body_html" do
    let(:explanation) { Explanation.new(text: text) }
    it "returns empty" do
      expect(Explanation.new.calculated_body_html).to eq ""
      expect(Explanation.new(text: "\n").calculated_body_html).to eq ""
    end
    describe "markdown parsing stuff" do
      context "with some whitespace in between things" do
        let(:text) { "   something\n\n\nanother Thing\n\n\n > Blockquote here\n > more quote" }
        let(:target) do
          "<p>something</p> <p>another Thing</p> <div class=\"explanation-quote-block\"><blockquote> " \
          "<p>Blockquote here more quote</p> </blockquote></div> "
        end
        it "returns the expected content" do
          # Strip multiple spaces to make matching easier
          expect(explanation.calculated_body_html.gsub(/\s+/, " ")).to eq target
        end
      end
      context "with an image" do
        let(:text) { "I want to include an image ![image](https://creativecommons.org/images/deed/cc_icon_white_x2.png)" }
        it "returns the expected content" do
          expect(explanation.calculated_body_html).to eq "<p>#{text}</p>\n"
        end
        context "with an inline image" do
          let(:text) { "I want to include an <a href=\"https://creativecommons.org/images/deed/cc_icon_white_x2.png\">image</a>" }
          it "returns the expected content" do
            expect(explanation.calculated_body_html).to eq "<p>I want to include an image</p>\n"
          end
        end
      end
      context "with some headers" do
        let(:text) { "## Some Text\n\n#### More text" }
        it "returns without headers" do
          expect(explanation.calculated_body_html).to eq("<p>Some Text</p>\n\n<p>More text</p>\n")
        end
      end
      context "with a link" do
        let(:text) { "Something with [no link](https://link.com) <a href=\"http://link.com\">no link</a>" }
        it "returns the expected content" do
          expect(explanation.calculated_body_html).to eq "<p>Something with [no link](https://link.com) no link</p>\n"
        end
      end
      context "with a script tag" do
        let(:text) { "I want to <script>alert('hi')</script>" }
        it "returns the expected content" do
          expect(explanation.calculated_body_html).to eq "<p>I want to alert(&#39;hi&#39;)</p>\n"
        end
      end
      context "with a table" do
        let(:text) { " | t1 | t2 |\n| -- | -- |\n| tb1 | tb2 |" }
        let(:target) { "<table><thead>\n<tr>\n<th>t1</th>\n<th>t2</th>\n</tr>\n</thead><tbody>\n<tr>\n<td>tb1</td>\n<td>tb2</td>\n</tr>\n</tbody></table>\n" }
        it "renders" do
          expect(explanation.calculated_body_html).to eq target
        end
      end
    end
    context "with blockquote" do
      let(:url) { "http://example.com" }
      let(:url2) { "https://convus.org/this-this-this" }
      let(:quote_text) { "I believe that this is the solution to discussions of various things on the internet" }
      let(:explanation_text) { "Something cool and stuff\n\n> #{quote_text}" }
      let(:explanation) { FactoryBot.create(:explanation, text: explanation_text) }
      let!(:explanation_quote) { FactoryBot.create(:explanation_quote, explanation: explanation, text: quote_text, url: url) }
      let(:target) do
        "<p>Something cool and stuff</p>\n\n" \
          "<div class=\"explanation-quote-block\">" \
          "<blockquote>\n<p>#{quote_text}</p>\n</blockquote>" \
          "<span class=\"source\">#{explanation_quote.citation_ref_html}</span></div>\n"
      end
      it "does things" do
        expect(explanation_quote.reload.ref_number).to eq 1 # Expect it to be set
        expect(explanation_quote.citation_ref_html).to be_present
        expect(explanation.reload.body_html).to be_blank
        expect(explanation.ref_number).to eq 1
        expect(explanation.listing_order).to eq 0
        # OMFG testing this was a bear. There is definitely to be a better way, but whatever
        real_lines = explanation.calculated_body_html.split("\n").reject(&:blank?)
        target_lines = target.split("\n").reject(&:blank?)
        real_lines.count.times { |i| expect(real_lines[i]).to eq target_lines[i] }
        expect(real_lines.count).to eq target_lines.count
        expect(real_lines).to eq target_lines
        # Strip multiple spaces to make matching easier
        expect(explanation.calculated_body_html.gsub(/\s+/, " ")).to eq target.gsub(/\s+/, " ")
        explanation.update_body_html
        explanation.reload
        expect(explanation.body_html.gsub(/\s+/, " ")).to eq target.gsub(/\s+/, " ")
      end
      context "with multiple quotes and nothing in between" do
        let(:explanation_text) { "Something cool and stuff\n\n> something\n\n> Something else\n" }
        let!(:explanation_quote) { FactoryBot.create(:explanation_quote, explanation: explanation, text: "something", url: url) }
        let!(:explanation_quote2) { FactoryBot.create(:explanation_quote, explanation: explanation, text: "Something else", url: url2) }
        let(:target) do
          "<p>Something cool and stuff</p>\n\n" \
            "<div class=\"explanation-quote-block\">" \
            "<blockquote>\n<p>something</p>\n</blockquote>" \
            "<span class=\"source\">#{explanation_quote.citation_ref_html}</span></div>\n" \
            "<div class=\"explanation-quote-block\">" \
            "<blockquote>\n<p>Something else</p>\n</blockquote>" \
            "<span class=\"source\">#{explanation_quote2.citation_ref_html}</span></div>\n"
        end
        it "creates" do
          expect(explanation_quote.reload.ref_number).to eq 1
          expect(explanation_quote.citation_ref_html).to be_present
          expect(explanation_quote2.reload.ref_number).to eq 2
          expect(explanation.reload.body_html).to be_blank
          # OMFG testing this was a bear. There is definitely to be a better way, but whatever
          real_lines = explanation.calculated_body_html.split("\n").reject(&:blank?)
          target_lines = target.split("\n").reject(&:blank?)
          real_lines.count.times { |i| expect(real_lines[i]).to eq target_lines[i] }
          expect(real_lines.count).to eq target_lines.count
          expect(real_lines).to eq target_lines
          # Strip multiple spaces to make matching easier
          expect(explanation.calculated_body_html.gsub(/\s+/, " ")).to eq target.gsub(/\s+/, " ")
          explanation.update_body_html
          explanation.reload
          expect(explanation.body_html.gsub(/\s+/, " ")).to eq target.gsub(/\s+/, " ")
        end
      end
      context "with a blockquote with markdown in it" do
        let(:explanation_text) { "Something cool and stuff\n\n> #{quote_text}\n\n And another thing\n > This here **Rocks**\n" }
        let!(:explanation_quote2) { FactoryBot.create(:explanation_quote, explanation: explanation, text: "This here **Rocks**", url: url2) }
        let(:target_with_addition) do
          target +
            "\n<p>And another thing</p>\n\n" \
            "<div class=\"explanation-quote-block\">" \
            "<blockquote>\n<p>This here <strong>Rocks</strong></p>\n</blockquote>" \
            "<span class=\"source\">#{explanation_quote2.citation_ref_html}</span></div>\n"
        end
        it "renders" do
          expect(explanation_quote.reload.ref_number).to eq 1
          expect(explanation_quote.citation_ref_html).to be_present
          expect(explanation_quote2.reload.ref_number).to eq 2
          expect(explanation.reload.body_html).to be_blank
          # OMFG testing this was a bear. There is definitely to be a better way, but whatever
          real_lines = explanation.calculated_body_html.split("\n").reject(&:blank?)
          target_lines = target_with_addition.split("\n").reject(&:blank?)
          real_lines.count.times { |i| expect(real_lines[i]).to eq target_lines[i] }
          expect(real_lines.count).to eq target_lines.count
          expect(real_lines).to eq target_lines
          # Strip multiple spaces to make matching easier
          expect(explanation.calculated_body_html.gsub(/\s+/, " ")).to eq target_with_addition.gsub(/\s+/, " ")
          explanation.update_body_html
          explanation.reload
          expect(explanation.body_html.gsub(/\s+/, " ")).to eq target_with_addition.gsub(/\s+/, " ")
        end
      end
    end
  end

  describe "shown" do
    let(:user) { FactoryBot.create(:user) }
    let!(:explanation1) { FactoryBot.create(:explanation) }
    let(:hypothesis) { explanation1.hypothesis }
    let!(:explanation2) { FactoryBot.create(:explanation, creator: user, hypothesis: hypothesis) }
    let!(:explanation3) { FactoryBot.create(:explanation_approved, hypothesis: hypothesis) }
    let!(:explanation4) { FactoryBot.create(:explanation, creator: user) }
    it "returns users and approved" do
      expect(Explanation.where(creator_id: user.id).pluck(:id)).to match_array([explanation2.id, explanation4.id])
      expect(Explanation.shown(user).pluck(:id)).to match_array([explanation2.id, explanation3.id, explanation4.id])
      expect(Explanation.shown.pluck(:id)).to match_array([explanation3.id])
      expect(hypothesis.reload.explanations.shown(user).pluck(:id)).to match_array([explanation2.id, explanation3.id])
      expect(hypothesis.reload.explanations.shown.pluck(:id)).to match_array([explanation3.id])
    end
  end

  describe "url" do
    let(:url) { "https://example.com/stuff?utm_things=asdfasdf" }
    let(:explanation) { FactoryBot.create(:explanation, creator: FactoryBot.create(:user)) }
    let!(:explanation_quote) { FactoryBot.build(:explanation_quote, explanation: explanation, url: url, citation: nil, creator: nil) }
    it "creates the citation" do
      expect {
        explanation_quote.save
      }.to change(Citation, :count).by 1
      expect(explanation_quote.url).to eq "https://example.com/stuff"
      expect(explanation_quote.explanation.creator).to be_present
      citation = explanation_quote.citation
      expect(citation.url).to eq explanation_quote.url
      expect(citation.creator_id).to eq explanation_quote.explanation.creator_id
    end
    context "citation already exists" do
      let!(:citation) { FactoryBot.create(:citation, url: url, creator: nil) }
      it "associates with the existing citation" do
        expect(citation).to be_valid
        expect(citation.creator_id).to be_blank
        expect {
          explanation_quote.save
        }.to change(Citation, :count).by 0
        expect(explanation_quote.citation_id).to eq citation.id
        expect(citation.creator_id).to be_blank
      end
    end
    context "citation changed" do
      it "updates to a new citation" do
        explanation_quote.save
        citation1 = explanation_quote.citation
        expect(citation1).to be_valid
        explanation_quote.update(url: "https://example.com/other-stuff")
        expect(explanation_quote.citation.id).to_not eq citation1.id
        citation1.reload
        expect(citation1).to be_valid
      end
    end
  end

  describe "validate_can_add_to_github?" do
    let(:explanation) { FactoryBot.create(:explanation, text: text) }
    let(:text) { "Some cool text" }

    it "is not valid" do
      expect(explanation).to be_valid
      expect(explanation.validate_can_add_to_github?).to be_falsey
      expect(explanation.errors.full_messages.count).to eq 1
      expect(explanation.errors.full_messages.first).to match(/quote/i)
    end
    context "with blockquote" do
      let(:text) { "Some cool text\n\n> Some quote\n" }
      it "is not valid" do
        expect(explanation).to be_valid
        expect(explanation.explanation_quotes.count).to eq 0
        expect(explanation.validate_can_add_to_github?).to be_falsey
        expect(explanation.errors.full_messages.count).to eq 1
        expect(explanation.errors.full_messages.first).to match(/quote/i)
        # And then validate with explanation_quote without URL
        explanation.explanation_quotes.create(text: "Some quote")
        expect(explanation.reload.explanation_quotes.count).to eq 1
        expect(explanation).to be_valid
        expect(explanation.validate_can_add_to_github?).to be_falsey
        expect(explanation.errors.full_messages.count).to eq 1
        expect(explanation.errors.full_messages.first).to match(/url/i)
      end
      context "with explanation_quote with url" do
        let!(:explanation_quote1) { explanation.explanation_quotes.create(text: "Some quote", url: "something.com") }
        let!(:explanation_quote2) { explanation.explanation_quotes.create(text: "another quote", removed: true) }
        it "is valid" do
          expect(explanation).to be_valid
          expect(explanation.explanation_quotes.count).to eq 2
          expect(explanation.validate_can_add_to_github?).to be_truthy
          expect(explanation.errors.full_messages.count).to eq 0
        end
      end
    end
  end

  describe "citations_not_removed" do
    let(:explanation) { FactoryBot.create(:explanation) }
    let(:explanation_quote1) { FactoryBot.create(:explanation_quote, explanation: explanation, ref_number: 2) }
    let(:explanation_quote2) { FactoryBot.create(:explanation_quote, explanation: explanation, ref_number: 3, removed: true) }
    let!(:explanation_quote3) { FactoryBot.create(:explanation_quote, explanation: explanation, ref_number: 4, url: explanation_quote1.url) }
    let(:explanation_quote4) { FactoryBot.create(:explanation_quote, explanation: explanation, ref_number: 1) }
    let!(:citation1) { explanation_quote1.citation }
    let!(:citation2) { explanation_quote2.citation }
    let!(:citation3) { explanation_quote4.citation }
    let(:target_explanation_quote_ids) { [explanation_quote4.id, explanation_quote1.id, explanation_quote2.id, explanation_quote3.id] }
    it "only includes the not-removed" do
      expect(explanation.reload.explanation_quotes.ref_ordered.pluck(:id)).to eq target_explanation_quote_ids
      # TODO: can't get the ordering to work. Ideally these associations would be ref_ordered, skipping for now
      expect(explanation.citations.pluck(:id)).to match_array([citation3.id, citation1.id, citation2.id])
      expect(explanation.citations_not_removed.pluck(:id)).to match_array([citation3.id, citation1.id])
    end
  end

  describe "github_html_url" do
    let(:hypothesis) { FactoryBot.create(:hypothesis, pull_request_number: 2) }
    let(:explanation) { FactoryBot.build(:explanation, hypothesis: hypothesis, pull_request_number: 111) }
    it "is pull_request if unapproved, file_path if approved" do
      expect(hypothesis.github_html_url).to match(/pull\/2/)
      expect(explanation.approved?).to be_falsey
      expect(explanation.github_html_url).to match(/pull\/111/)
      # I don't think explanation approved without hypothesis can or will happen
      # but if it did = is what I expect to happen
      explanation.approved_at = Time.current
      expect(explanation.github_html_url).to match(/pull\/2/)
      hypothesis.update(approved_at: Time.current)
      expect(hypothesis.github_html_url).to match(hypothesis.file_path)
      expect(explanation.github_html_url).to eq hypothesis.github_html_url
      expect(explanation.pull_request_url).to match(/pull\/111/)
    end
  end
end
