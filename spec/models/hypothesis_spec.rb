require "rails_helper"

RSpec.describe Hypothesis, type: :model do
  it_behaves_like "TitleSluggable"
  it_behaves_like "GithubSubmittable"

  it "has a valid factory" do
    hypothesis = FactoryBot.create(:hypothesis)
    expect(hypothesis.id).to be_present
    hypothesis.reload
    expect(hypothesis.tags.pluck(:id)).to eq([])
  end

  describe "slugify" do
    # Issue with trailing - (dash) in filename_slug
    let(:title) { "Overall, the case for reduced meat consumption is strong. Vegetarianism is cheaper, better for your health (if you can afford a diverse diet and are not an infant), and is less impactful for the environment. It also has a significant moral cost in terms of animal suffering." }
    let(:hypothesis) { FactoryBot.create(:hypothesis, title: title) }
    it "makes a valid slug" do
      expect(hypothesis).to be_valid
      slug = hypothesis.slug
      expect(Slugifyer.filename_slugify(slug)).to eq slug
      expect(Hypothesis.friendly_find(slug)).to eq hypothesis
      expect(Hypothesis.friendly_find(title)).to eq hypothesis
    end
  end

  # Commenting out for now, because it's not relevant - but it may be soon
  # describe "errors_full_messages" do
  #   let(:hypothesis) { Hypothesis.new }
  #   it "returns errors full_messages" do
  #     expect(hypothesis.errors_full_messages).to be_blank
  #     hypothesis.save
  #     expect(hypothesis.errors_full_messages).to eq(["Title can't be blank"])
  #   end
  #   context "with hypothesis_citation" do
  #     let(:hypothesis_citation) { hypothesis.hypothesis_citations.build(quotes_text: " ") }
  #     it "returns hypothesis_citation errors as well" do
  #       expect(hypothesis.errors_full_messages).to be_blank
  #       expect(hypothesis_citation.errors.full_messages).to be_blank
  #       hypothesis.save
  #       expect(hypothesis.errors_full_messages).to eq(["Citation URL can't be blank", "Title can't be blank"])
  #     end
  #   end
  # end

  describe "tags_string" do
    let(:hypothesis) { FactoryBot.create(:hypothesis) }
    it "assigns an array" do
      hypothesis.tags_string = ["Space"]
      hypothesis.save
      hypothesis.reload
      expect(hypothesis.tags_string).to eq("Space")
      expect(Hypothesis.with_tags("Space").pluck(:id)).to eq([hypothesis.id])
      expect(Hypothesis.with_tags(["space "]).pluck(:id)).to eq([hypothesis.id])
      expect(Hypothesis.with_tags("Spacer").pluck(:id)).to eq([])
      Tag.create(title: "Stuff")
      expect(Hypothesis.with_tags("Space, stuff").pluck(:id)).to eq([])
    end
    context "assigning a string" do
      let!(:tag) { FactoryBot.create(:tag, title: "SOME existing title") }
      let(:hypothesis) { FactoryBot.create(:hypothesis_approved, tags_string: "some  existing titlé  ,") }
      it "assigns based on the string, adds removes" do
        hypothesis.reload
        expect(hypothesis.tags.pluck(:id)).to eq([tag.id])
        hypothesis.update(tags_string: "a new tag,Something\n environmenT")
        hypothesis.reload
        expect(hypothesis.tags.count).to eq 3
        expect(hypothesis.tags.pluck(:id)).to_not include(tag.id)
        expect(hypothesis.tags_string).to eq("a new tag, environmenT, Something")
        hypothesis2 = FactoryBot.create(:hypothesis, tags_string: "environment ")
        expect(Hypothesis.with_tags("environment").pluck(:id)).to eq([hypothesis.id, hypothesis2.id])
        expect(Hypothesis.with_tags("environment, Something").pluck(:id)).to eq([hypothesis.id])
        tag_ids = Tag.matching_tags("environment, Something").pluck(:id)
        expect(Hypothesis.with_tag_ids(tag_ids).pluck(:id)).to eq([hypothesis.id])
      end
    end
    context "Assigning a new tag" do
      let(:hypothesis) { Hypothesis.create(title: "Some new thing", tags_string: "Something") }
      let(:tag) { hypothesis.tags.first }
      let(:target_tag_titles) { ["Something", "Another thing"] }
      it "adds the new tag" do
        expect(hypothesis.tags.pluck(:id)).to eq([tag.id])
        hypothesis.update(tags_string: target_tag_titles)
        expect(hypothesis.hypothesis_tags.count).to eq 2
        hypothesis.reload
        expect(hypothesis.tags.count).to eq 2
        expect(hypothesis.tag_titles).to match_array(target_tag_titles)
      end
    end
    context "assigning without creating" do
      let(:hypothesis) { Hypothesis.new(tags_string: "One,    Xwo, three") }
      it "returns what was assigned" do
        expect(hypothesis.tags_string).to eq("One, three, Xwo")
      end
    end
  end

  describe "github_html_url" do
    let(:hypothesis) { FactoryBot.create(:hypothesis, pull_request_number: 2) }
    it "is pull_request if unapproved, file_path if approved" do
      expect(hypothesis.github_html_url).to match(/pull\/2/)
      hypothesis.approved_at = Time.current
      expect(hypothesis.github_html_url).to match(hypothesis.file_path)
    end
  end

  describe "add_to_github_content" do
    let(:hypothesis) { FactoryBot.build(:hypothesis) }
    it "enqueues job" do
      expect {
        hypothesis.save
      }.to change(AddHypothesisToGithubContentJob.jobs, :count).by 0

      expect {
        hypothesis.update(add_to_github: true)
        hypothesis.update(add_to_github: true)
      }.to change(AddHypothesisToGithubContentJob.jobs, :count).by 1

      expect {
        hypothesis.update(add_to_github: true, pull_request_number: 12)
      }.to change(AddHypothesisToGithubContentJob.jobs, :count).by 0

      expect {
        hypothesis.update(add_to_github: true, pull_request_number: nil, approved_at: Time.current)
      }.to change(AddHypothesisToGithubContentJob.jobs, :count).by 0
    end
    context "with skip_github_update" do
      it "does not enqueue job" do
        stub_const("GithubIntegration::SKIP_GITHUB_UPDATE", true)
        expect {
          hypothesis.update(add_to_github: true)
        }.to change(AddHypothesisToGithubContentJob.jobs, :count).by 0
      end
    end
  end

  describe "score" do
    let(:hypothesis) { FactoryBot.create(:hypothesis_approved) }
    it "sets the score" do
      hypothesis.reload
      expect(hypothesis.citations.count).to eq 0
      expect(hypothesis.score).to eq 0
    end
    context "with quote, peer_reviewed" do
      let(:citation) { FactoryBot.create(:citation_approved, peer_reviewed: true, url_is_direct_link_to_full_text: true) }
      let(:hypothesis) { FactoryBot.create(:hypothesis) }
      let!(:hypothesis_citation) { FactoryBot.create(:hypothesis_citation, hypothesis: hypothesis, url: citation.url, quotes_text: "this is a quote") }
      it "sets the score" do
        expect(hypothesis.citations.pluck(:id)).to eq([citation.id])
        expect(hypothesis.score).to eq 0
        expect(hypothesis.calculated_score).to eq 11
        hypothesis.update(approved_at: Time.current)
        hypothesis.reload
        expect(hypothesis.score).to eq 11
      end
    end
  end
end
