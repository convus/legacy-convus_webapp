require "rails_helper"

RSpec.describe Hypothesis, type: :model do
  it_behaves_like "TitleSluggable"
  it_behaves_like "GithubSubmittable"

  it "has a valid factory" do
    hypothesis = FactoryBot.create(:hypothesis, id: 11)
    expect(hypothesis.ref_number).to eq 11
    expect(hypothesis.ref_id).to eq "B"
    hypothesis.reload
    expect(hypothesis.tags.pluck(:id)).to eq([])
    # Test ref_number still correct
    expect(hypothesis.id).to eq 11 # Sanity check
  end

  describe "slugify" do
    # Issue with trailing - (dash) in filename_slug
    let(:title) { "Overall, the case for reduced meat consumption is strong. Vegetarianism is cheaper, better for your health (if you can afford a diverse diet and are not an infant), and is less impactful for the environment. It also has a significant moral cost in terms of animal suffering." }
    let(:hypothesis) { FactoryBot.create(:hypothesis, title: title) }
    it "makes a valid slug" do
      expect(hypothesis).to be_valid
      slug = hypothesis.slug
      expect(hypothesis.file_path.gsub("hypotheses/", "").length).to be < 255
      expect(Slugifyer.filename_slugify(slug)).to eq slug
      expect(Slugifyer.filename_slugify(hypothesis.file_path)).to eq slug
      expect(Hypothesis.friendly_find(hypothesis.file_path)&.id).to eq hypothesis.id
      expect(Hypothesis.friendly_find("  #{hypothesis.file_path} ")&.id).to eq hypothesis.id
      expect(Hypothesis.friendly_find(slug)&.id).to eq hypothesis.id
      expect(Hypothesis.friendly_find(title)&.id).to eq hypothesis.id
      expect(Hypothesis.friendly_find("#{hypothesis.ref_id.downcase} ")&.id).to eq hypothesis.id
    end
  end

  describe "punctuate_title" do
    let(:hypothesis) { Hypothesis.create(title: title) }
    let(:title) { "\nSomething about things\n" }
    it "punctuates" do
      expect(hypothesis).to be_valid
      expect(hypothesis.title).to eq "Something about things."
    end
    context "with punctuation" do
      let(:title) { " Statement about things. Because a cool party! \n" }
      it "strips" do
        expect(hypothesis).to be_valid
        expect(hypothesis.title).to eq "Statement about things. Because a cool party!"
      end
    end
  end

  describe "friendly_find" do
    let(:title1) { "Overall, the case for reduced meat consumption is strong." }
    let(:title2) { "The case for reduced meat consumption is strong." }
    let(:title1_slug) { "overall-the-case-for-reduced-meat-consumption-is-strong" }
    let(:hypothesis) { FactoryBot.create(:hypothesis_approved, title: title1, ref_number: 3213) }
    it "finds by various things" do
      expect(hypothesis.ref_id).to eq "2H9"
      expect(hypothesis.slug).to eq title1_slug
      expect(hypothesis.file_path).to eq "hypotheses/2H9_#{title1_slug}.yml"
      expect(Slugifyer.filename_slugify(hypothesis.file_path)).to eq title1_slug
      expect(hypothesis.file_path.match?(/\A(hypotheses\/)?[0-z]+_/i)).to be_truthy
      Sidekiq::Worker.clear_all
      hypothesis.update(title: title2)
      StorePreviousHypothesisTitleJob.drain
      hypothesis.reload
      expect(hypothesis.previous_titles.count).to eq 1
      expect(hypothesis.previous_titles.first&.title).to eq title1
      expect(hypothesis.slug).to eq "the-case-for-reduced-meat-consumption-is-strong"
      expect(Hypothesis.friendly_find(" 2H9\n")&.id).to eq hypothesis.id
      expect(Hypothesis.friendly_find(hypothesis.id)&.id).to eq hypothesis.id
      expect(Hypothesis.friendly_find(title2)&.id).to eq hypothesis.id
      expect(Hypothesis.friendly_find(hypothesis.slug)&.id).to eq hypothesis.id
      expect(Hypothesis.friendly_find(hypothesis.file_path)&.id).to eq hypothesis.id
      expect(Hypothesis.friendly_find("2H9_the-case-for-reduced-meat-consumption-is-strong")&.id).to eq hypothesis.id
      expect(Hypothesis.friendly_find("2H9: #{title1}")&.id).to eq hypothesis.id
      expect(Hypothesis.matching_previous_titles(title1).map(&:id)).to eq([hypothesis.id])
      expect(Hypothesis.matching_previous_titles(title1_slug).map(&:id)).to eq([hypothesis.id])
      expect(Hypothesis.friendly_find(title1)&.id).to eq hypothesis.id
      expect(Hypothesis.friendly_find(title1_slug)&.id).to eq hypothesis.id
      expect(Hypothesis.friendly_find(" 2H9_#{title1_slug}")&.id).to eq hypothesis.id
    end
  end

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

  describe "text_search" do
    let!(:hypothesis1) { FactoryBot.create(:hypothesis, title: "bears are neat.") }
    let!(:hypothesis2) { FactoryBot.create(:hypothesis, title: "dragons are neat! ") }
    it "finds" do
      expect(hypothesis2.title).to eq "dragons are neat!"
      expect(Hypothesis.text_search("are neat").pluck(:id)).to match_array([hypothesis1.id, hypothesis2.id])
      expect(Hypothesis.text_search("are NEAT").pluck(:id)).to match_array([hypothesis1.id, hypothesis2.id])
      expect(Hypothesis.text_search("Bears").pluck(:id)).to match_array([hypothesis1.id])
      expect(Hypothesis.text_search("Dragons neat").pluck(:id)).to match_array([hypothesis2.id])
      expect(Hypothesis.text_search(["Dragons", "neat"]).pluck(:id)).to match_array([hypothesis2.id])
    end
  end

  describe "newness_ordered" do
    let!(:hypothesis1) { FactoryBot.create(:hypothesis_approved, created_at: Time.current - 5.hours, approved_at: Time.current - 2.minutes) }
    let!(:hypothesis2) { FactoryBot.create(:hypothesis, created_at: Time.current - 1.hour) }
    let!(:hypothesis3) { FactoryBot.create(:hypothesis_approved, created_at: Time.current - 5.hours, approved_at: Time.current - 50.minutes) }
    let!(:hypothesis4) { FactoryBot.create(:hypothesis) }
    it "orders by approved if approved, otherwise created_at" do
      # I think it would be better to order by approved_at if it's present, otherwise created_at - which would do this:
      # expect(Hypothesis.newness_ordered.pluck(:id)).to eq([hypothesis4.id, hypothesis1.id, hypothesis3.id, hypothesis2.id])
      # ... But I don't know how to do that, so ordering unapproved first
      expect(Hypothesis.newness_ordered.pluck(:id)).to eq([hypothesis4.id, hypothesis2.id, hypothesis1.id, hypothesis3.id])
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
      }.to change(AddToGithubContentJob.jobs, :count).by 0

      expect {
        hypothesis.update(add_to_github: true)
        hypothesis.update(add_to_github: true)
      }.to change(AddToGithubContentJob.jobs, :count).by 1
      expect(AddToGithubContentJob.jobs.map { |j| j["args"] }.last.flatten).to eq(["Hypothesis", hypothesis.id])

      expect {
        hypothesis.update(add_to_github: true, pull_request_number: 12)
      }.to change(AddToGithubContentJob.jobs, :count).by 0

      expect {
        hypothesis.update(add_to_github: true, pull_request_number: nil, approved_at: Time.current)
      }.to change(AddToGithubContentJob.jobs, :count).by 0
    end
    context "with skip_github_update" do
      it "does not enqueue job" do
        stub_const("GithubIntegration::SKIP_GITHUB_UPDATE", true)
        expect {
          hypothesis.update(add_to_github: true)
        }.to change(AddToGithubContentJob.jobs, :count).by 0
      end
    end
  end
end
