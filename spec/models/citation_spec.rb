require "rails_helper"

RSpec.describe Citation, type: :model do
  it_behaves_like "GithubSubmittable"

  describe "kind_humanized" do
    it "all the things match up" do # Sanity checking because I've messed this up
      expect(Citation.kind_humanized("article")).to eq "article"
      humanized_kinds = Citation.kinds.map { |k| Citation.kind_humanized(k) }
      expect(humanized_kinds.any?(&:blank?)).to be_falsey
      expect((Citation.kinds_data.keys.map(&:to_s) - Citation.kinds)).to eq([])
      expect((Citation.kinds_research - Citation.kinds)).to eq([])
    end
  end

  describe "friendly_find_kind" do
    it "returns" do
      expect(Citation.friendly_find_kind("asdfasdf")).to be_blank
      expect(Citation.friendly_find_kind(:article)).to eq "article"
      expect(Citation.friendly_find_kind("article \n")).to eq "article"
      expect(Citation.friendly_find_kind("research with randomized controlled trial")).to eq "research_with_rct"
    end
  end

  describe "text_search" do
    let!(:citation1) { FactoryBot.create(:citation, title: "bears are neat", url: "http://example.com/something") }
    let!(:citation2) { FactoryBot.create(:citation, title: "dragons are neat", url: "http://example.com/else", kind: "research_comment") }
    it "finds" do
      expect(Citation.text_search("are neat").pluck(:id)).to match_array([citation1.id, citation2.id])
      expect(Citation.text_search("are NEAT").pluck(:id)).to match_array([citation1.id, citation2.id])
      expect(Citation.text_search("Bears").pluck(:id)).to match_array([citation1.id])
      expect(citation1.kind_humanized).to eq "article"
      expect(citation2.kind_humanized).to eq "published research comment"
    end
  end

  describe "factory" do
    let(:publication) { FactoryBot.create(:publication) }
    let(:citation) { FactoryBot.create(:citation, publication: publication) }
    it "is valid" do
      expect(Publication.count).to eq 0
      expect(citation.errors.full_messages).to be_blank
      expect(citation.id).to be_present
      expect(Publication.count).to eq 1 # Ensure there is just one created in this contrived example
    end
  end

  describe "find_or_create_by_params" do
    it "creates" do
      citation = Citation.find_or_create_by_params(url: "https://something.com", title: "something cool")
      expect(citation).to be_valid
      expect(Citation.find_or_create_by_params(url: "https://something.com").id).to eq citation.id
    end
    context "missing url" do
      it "doesn't do anything" do
        expect(Citation.find_or_create_by_params(nil)).to_not be_valid
        expect(Citation.find_or_create_by_params({})).to_not be_valid
        expect(Citation.find_or_create_by_params({title: "party"})).to_not be_valid
      end
    end
  end

  describe "very basic" do
    let(:citation) { Citation.create(url: "example.com") }
    it "is what we expect" do
      expect(citation).to be_valid
      expect(citation.url).to eq "http://example.com"
      expect(citation.title).to eq "example.com"
      expect(citation.display_title).to eq "example.com"
    end
  end

  describe "published_date_str" do
    let(:citation) { Citation.new(published_date_str: published_date_str) }
    context "blank" do
      let(:published_date_str) { " " }
      it "is nil if blank" do
        expect(citation.published_at).to be_blank
      end
    end
    context "2017-03-3" do
      let(:published_date_str) { "2017-03-3" }
      let(:target) { Date.parse("2017-03-03") }
      it "is date" do
        expect(citation.published_at.to_date).to eq target
      end
    end
    context "1995-03" do
      let(:published_date_str) { "1995-03" }
      let(:target) { Date.parse("1995-03-01") }
      it "is date" do
        expect(citation.published_at.to_date).to eq target
      end
    end
  end

  describe "slugging" do
    let(:url) { "https://www.nationalreview.com/2020/09/joe-bidens-money-misadventures/" }
    let(:citation) { FactoryBot.create(:citation, url: url, title: nil) }
    it "slugs from the URL" do
      expect(citation.title).to eq "2020/09/joe-bidens-money-misadventures"
      expect(citation.publication_id).to be_present
      expect(citation.publication.title).to eq "nationalreview.com"
      expect(citation.slug).to eq("2020-09-joe-bidens-money-misadventures")
      expect(citation.file_path).to eq("citations/nationalreview-com/2020-09-joe-bidens-money-misadventures.yml")
      expect(citation.title_url?).to be_truthy
      expect(citation.display_title).to eq "nationalreview.com: 2020/09/joe-bidens-money-misadventures"
    end
    context "really long URL" do
      let(:url) { "https://www.researchgate.net//profile/Mark_Greenberg2/publication/312233343_Promoting_Healthy_Transition_to_College_through_Mindfulness_Training_with_1st_year_College_Students_Pilot_Randomized_Controlled_Trial/links/5ce8706f299bf14d95b76a58/Promoting-Healthy-Transition-to-College-through-Mindfulness-Training-with-1st-year-College-Students-Pilot-Randomized-Controlled-Trial.pdf" }
      let(:target) { "profile-mark-greenberg2-publication-312233343-promoting-healthy-transition-to-college-through-mindfulness-training-with-1st-year-college-students-pilot-randomized-controlled-trial-links-5ce8706f299bf14d95b76a58-promoting-healthy-transition-to-college" }
      it "slugs, limits to 250 characters" do
        expect(citation.title).to eq "/profile/Mark_Greenberg2/publication/312233343_Promoting_Healthy_Transition_to_College_through_Mindfulness_Training_with_1st_year_College_Students_Pilot_Randomized_Controlled_Trial/links/5ce8706f299bf14d95b76a58/Promoting-Healthy-Transition-to-College-through-Mindfulness-Training-with-1st-year-College-Students-Pilot-Randomized-Controlled-Trial.pdf"
        expect(citation.publication_id).to be_present
        expect(citation.publication.title).to eq "researchgate.net"
        expect(citation.title.length).to be > 255
        expect(citation.slug).to eq target
        expect(citation.slug.length).to be < 255 # File name length limit
        expect(citation.title_url?).to be_truthy
        # Test that it still finds, even with trucatedness
        expect(Citation.find_by_slug_or_path_slug(url.gsub("https://www.", ""))).to eq citation
        expect(Citation.friendly_find(url.gsub("https://www.", ""))).to eq citation
        expect(Citation.friendly_find(url.gsub("https://www.researchgate.net", ""))).to eq citation
        expect(Citation.friendly_find(target.gsub("/researchgate-net", ""))).to eq citation
      end
    end
    context "URL is not a url" do
      let(:url) { "This isn't a URL" }
      let(:citation) { FactoryBot.create(:citation, url: url, title: nil) }
      it "doesn't explode" do
        expect(citation.publication_id).to be_blank
        expect(citation.title).to eq url
        expect(citation.slug).to eq("this-isn-t-a-url")
      end
    end
    context "Title and URL" do
      let!(:publication) { FactoryBot.create(:publication, title: "National Review", home_url: "https://www.nationalreview.com") }
      let(:citation) { FactoryBot.create(:citation, url: url, title: "Joe Biden’s Money Misadventures") }
      it "slugs from publication domain & title" do
        expect(citation.title).to eq "Joe Biden’s Money Misadventures"
        expect(citation.publication_id).to eq publication.id
        expect(citation.publication.title).to eq "National Review"
        expect(citation.slug).to eq("joe-biden-s-money-misadventures")
        expect(citation.url).to eq "https://www.nationalreview.com/2020/09/joe-bidens-money-misadventures"
        expect(Citation.friendly_find("Joe Biden’s Money Misadventures")).to eq citation
        expect(Citation.friendly_find(url)).to eq citation
        expect(citation.display_title).to eq "National Review: Joe Biden’s Money Misadventures"
      end
    end
    context "collision of slugs" do
      let!(:citation1) { FactoryBot.create(:citation, url: "https://magazine-research.com", title: "Cool research on novel things", publication_title: "Magazine") }
      let!(:citation2) { FactoryBot.create(:citation, url: "https://website-research.com", title: "Cool research on novel! Things", publication_title: "Website", created_at: Time.current - 1.hour) }
      let(:citation2_dupe) { FactoryBot.build(:citation, url: "https://website-research.com", title: "Cool research on novel things", publication_title: "Website") }
      let(:target_slug) { "cool-research-on-novel-things" }
      it "permits the citations to have the same slug" do
        expect(citation1.slug).to eq target_slug
        expect(citation2.slug).to eq target_slug
        expect(citation1.file_path).to eq "citations/magazine/#{target_slug}.yml"
        expect(citation2.file_path).to eq "citations/website/#{target_slug}.yml"
        expect(citation1.created_at).to be > citation2.created_at
        # It doesn't save an actual dupe
        expect(citation2_dupe.save).to be_falsey
        expect(citation2_dupe.errors.full_messages.join("")).to match("been taken")
        # It finds the citations in expected ways
        expect(Citation.friendly_find(target_slug).id).to eq citation2.id # Because it's the first created
        expect(Citation.friendly_find("magazine/#{target_slug}")&.id).to eq citation1.id
        expect(Citation.friendly_find("magazine/#{target_slug}.yml")&.id).to eq citation1.id
        expect(Citation.friendly_find("website/#{target_slug}")&.id).to eq citation2.id
        expect(Citation.friendly_find("website/#{target_slug}.yml")&.id).to eq citation2.id
        expect(Citation.friendly_find("magazine/#{target_slug}")&.id).to eq citation1.id
      end
    end
  end

  describe "score_percentage" do
    let(:citation) { Citation.new }
    it "returns score_percentage" do
      allow(citation).to receive(:score) { 5 }
      expect(citation.score).to eq 5
      expect(citation.score_percentage).to eq 50
    end
    context "over 10 score" do
      it "returns 10" do
        allow(citation).to receive(:score) { 15 }
        expect(citation.score_percentage).to eq 100
      end
    end
  end

  describe "authors_str" do
    let(:citation) { Citation.new(authors_str: "george stanley") }
    it "does one" do
      expect(citation.authors).to eq(["george stanley"])
      expect(citation.authors_str).to eq "george stanley"
    end
    context "with multiple" do
      let(:citation) { Citation.new(authors_str: "Stanley, George\n  Frank, Bobby") }
      it "splits by new line, sorts" do
        expect(citation.authors).to eq(["Stanley, George", "Frank, Bobby"])
        expect(citation.authors_str).to eq "Stanley, George; Frank, Bobby"
      end
    end
  end

  describe "add_to_github_content" do
    let(:citation) { FactoryBot.build(:citation) }
    it "enqueues only when add_to_github and not already added" do
      expect {
        citation.save
      }.to change(AddCitationToGithubContentJob.jobs, :count).by 0

      expect {
        citation.update(add_to_github: true)
        citation.update(add_to_github: true)
      }.to change(AddCitationToGithubContentJob.jobs, :count).by 1

      expect {
        citation.update(add_to_github: true, pull_request_number: 12)
      }.to change(AddCitationToGithubContentJob.jobs, :count).by 0

      expect {
        citation.update(add_to_github: true, pull_request_number: nil, approved_at: Time.current)
      }.to change(AddCitationToGithubContentJob.jobs, :count).by 0
    end
    context "create with add_to_github" do
      let(:citation) { FactoryBot.build(:citation, add_to_github: true) }
      it "enqueues job" do
        expect {
          citation.save
        }.to change(AddCitationToGithubContentJob.jobs, :count).by 1
      end
    end
    context "via hypothesis creation" do
      let!(:hypothesis_citation) { FactoryBot.build(:hypothesis_citation, url: "https://something.com") }
      it "enqueues job" do
        # This might not be how it should work, but it is how it works right now, so document it.
        # ... via HypothesesController, it does not enqueue the citation job
        Sidekiq::Worker.clear_all
        expect(Citation.count).to eq 0
        expect {
          hypothesis_citation.save
          hypothesis_citation.hypothesis.update(add_to_github: true)
        }.to change(AddCitationToGithubContentJob.jobs, :count).by 0
        expect(AddHypothesisToGithubContentJob.jobs.count).to eq 1
        expect(Hypothesis.count).to eq 1
        expect(Citation.count).to eq 1
      end
    end
    context "with skip_github_update" do
      it "does not enqueue job" do
        stub_const("GithubIntegration::SKIP_GITHUB_UPDATE", true)
        expect {
          citation.save
        }.to change(AddCitationToGithubContentJob.jobs, :count).by 0
      end
    end
  end

  describe "publication_title" do
    # TODO: make this use both the url and the title, if possible
    let(:citation) { Citation.new }
    it "assigns" do
      expect {
        citation.publication_title = "New York Times"
        citation.url = "https://www.nytimes.com/interactive/2020/09/21/us/covid-schools.html"
        citation.set_calculated_attributes
      }.to change(Publication, :count).by 1
      publication = citation.publication
      expect(publication.title).to eq "New York Times"
      expect(publication.home_url).to eq "https://www.nytimes.com"
      expect(citation.publication_title).to eq "New York Times"
      expect {
        citation.publication_title = "new york  times"
      }.to_not change(Publication, :count)
    end
    context "matching publication" do
      let!(:publication) { FactoryBot.create(:publication, title: "Nature") }
      it "assigns, doesn't create" do
        expect {
          citation.publication_title = "nature "
        }.to_not change(Publication, :count)
        expect(citation.publication_title).to eq "Nature"
        expect(citation.publication).to eq publication
      end
    end
    context "url_is_not_publisher" do
      let(:citation) { Citation.create(url: "https://jstor.org/some/thing/here", url_is_not_publisher: true) }
      it "creates a meta_publication" do
        expect(citation).to be_valid
        expect(citation.id).to be_present
        expect(citation.title).to eq "some/thing/here"
        expect(citation.publication.meta_publication).to be_truthy
      end
      context "adding a publication title afterward" do
        it "creates the publication" do
          meta_publication = citation.publication
          expect(meta_publication.meta_publication).to be_truthy
          expect {
            citation.update(publication_title: "Journal of Something")
          }.to change(Publication, :count).by 1
          expect(citation.id).to be_present
          publication = citation.publication
          expect(publication.meta_publication).to be_falsey
          expect(publication.id).to_not eq meta_publication
          expect(publication.title).to eq "Journal of Something"
          expect(publication.home_url).to be_blank
          expect(publication.base_domains).to be_blank
        end
      end
      context "with a publication title" do
        let(:citation) { Citation.create(url: "https://jstor.org/some/thing/here", url_is_not_publisher: true, publication_title: "Journal of Something") }
        it "creates the publication" do
          expect(citation.id).to be_present
          publication = citation.publication
          expect(publication.meta_publication).to be_falsey
          expect(publication.title).to eq "Journal of Something"
          expect(publication.home_url).to be_blank
          expect(publication.base_domains).to be_blank
        end
      end
    end
    describe "other subdomain" do
      it "does not assign publication"
    end
    describe "wikipedia" do
      let!(:citation_prior) { FactoryBot.create(:citation, url: "https://en.wikipedia.org/wiki/Impact_factor", publication_title: "Wikipedia") }
      let(:publication) { citation_prior.publication }
      let(:url) { "https://en.m.wikipedia.org/wiki/Glass–Steagall_legislation" }
      let(:citation) { Citation.new(url: url, title: "Glass–Steagall legislation") }
      it "assigns the publication even with non-matching subdomains" do
        expect(publication.title).to eq "Wikipedia"
        expect(publication.base_domains).to eq(["wikipedia.org"]) # ignoring the "en"
        expect(UrlCleaner.base_domain_without_www(url)).to eq "wikipedia.org"

        citation.set_calculated_attributes
        expect(citation.publication&.id).to eq publication.id
      end
    end
  end
end
