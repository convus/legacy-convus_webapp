require "rails_helper"

RSpec.describe Publication, type: :model do
  it_behaves_like "TitleSluggable"

  describe "factory" do
    let(:publication) { FactoryBot.create(:publication) }
    it "is valid" do
      expect(publication.id).to be_present
    end
  end

  describe "find_or_create_by_params" do
    it "creates for title" do
      result = Publication.find_or_create_by_params(title: "Some Publication")
      expect(result.title).to eq "Some Publication"
      expect(result.id).to be_present
      expect(Publication.find_or_create_by_params(title: "Some Publication").id).to eq result.id
    end
    context "url and title" do
      it "creates with url and title" do
        result = Publication.find_or_create_by_params(title: "another Publication", url: "https://publication.com/stuff/things/22222")
        expect(result.title).to eq "another Publication"
        expect(result.id).to be_present
        expect(result.home_url).to eq "https://publication.com"
        expect(Publication.find_or_create_by_params(title: "Another Publication").id).to eq result.id
        expect(Publication.find_or_create_by_params(url: "https://publication.com/other/wow/32123").id).to eq result.id
      end
    end
    context "just url" do
      it "creates once for a base" do
        publication = Publication.find_or_create_by_params(url: "https://www.nytimes.com/2020/09/11/us/wildfires-live-updates.html")
        expect(publication.home_url).to eq "https://www.nytimes.com"
        expect(publication.title).to eq "nytimes.com"
        expect {
          expect(Publication.find_or_create_by_params(url: "https://www.nytimes.com/interactive/2020/us/fires-map-tracker.html").id).to eq publication.id
        }.to_not change(Publication, :count)
        expect(Publication.friendly_find("https://www.nytimes.com/interactive/2020")).to eq publication
      end
      context "with subdomain" do
        it "creates with subdomain" do
          publication = Publication.find_or_create_by_params(url: "blog.bigagnes.com/self-support-on-idahos-south-fork/")
          expect(publication.home_url).to eq "http://blog.bigagnes.com"
          expect(publication.title).to eq "blog.bigagnes.com"
        end
      end
      context "not a url" do
        it "doesn't create a publication" do
          expect {
            Publication.find_or_create_by_params(url: "asdf9adfasdfasdf")
          }.to_not change(Publication, :count)
        end
      end
    end
    context "existing publication" do
      let!(:publication) { Publication.find_or_create_by_params(url: "https://www.journals.uchicago.edu/doi/full/10.1086/691462") }
      it "does not create a new publication for a matching publication" do
        expect(publication.title_url?).to be_truthy
        expect {
          expect(Publication.find_or_create_by_params(url: "https://www.journals.uchicago.edu/doi/10.1086/691974").id).to eq publication.id
        }.to_not change(Publication, :count)
      end
      context "passing in a title" do
        it "updates the publication" do
          expect(publication.title_url?).to be_truthy
          expect {
            Publication.find_or_create_by_params(url: "https://www.journals.uchicago.edu/doi/10.1086/691974", title: "Journal of the Association for Consumer Research")
          }.to_not change(Publication, :count)
          publication.reload
          expect(publication.title).to eq "Journal of the Association for Consumer Research"
          expect(publication.title_url?).to be_falsey

          # But it doesn't update again. Potentially a place/time to update multiple publications?
          Publication.find_or_create_by_params(url: "https://www.journals.uchicago.edu/doi/10.1086/691974", title: "Crap journal")
          publication.reload
          expect(publication.title).to eq "Journal of the Association for Consumer Research"
          expect(publication.title_url?).to be_falsey
        end
      end
    end
  end

  describe "friendly_find and base_domains" do
    let!(:publication) { FactoryBot.create(:publication, title: "NY Times", home_url: "https://www.nytimes.com") }
    it "finds by base domain too" do
      expect(publication.base_domains).to eq(["nytimes.com", "www.nytimes.com"])
      expect(Publication.friendly_find("NY times")).to eq publication
      expect(Publication.friendly_find("nytimes.com")).to eq publication
      expect(Publication.friendly_find("https://www.nytimes.com")).to eq publication
      expect(Publication.friendly_find("http://www.nytimes.com")).to eq publication
      publication.add_base_domain("https://wirecutter.com")
      publication.save
      publication.reload
      expect(Publication.friendly_find("wirecutter.com")).to eq publication
      expect(publication.base_domains).to eq(["nytimes.com", "wirecutter.com", "www.nytimes.com"])
    end
  end

  describe "add_base_domain" do
    let(:publication) { Publication.new }
    it "adds www and no subdomain" do
      publication.add_base_domain("https://www.bikeindex.org")
      expect(publication.base_domains).to eq(["bikeindex.org", "www.bikeindex.org"])
      # And it doesn't add again
      publication.add_base_domain("bikeindex.org")
      expect(publication.base_domains).to eq(["bikeindex.org", "www.bikeindex.org"])
    end
    context "non www" do
      it "does not add without subdomain" do
        publication.add_base_domain("blog.example.com")
        expect(publication.base_domains).to eq(["blog.example.com"])
        # And it doesn't add again
        publication.add_base_domain("http://blog.example.com")
        expect(publication.base_domains).to eq(["blog.example.com"])
      end
    end
    context "starts with www" do
      it "does not split" do
        publication.add_base_domain("wwwwrestling.com")
        expect(publication.base_domains).to eq(["wwwwrestling.com"])
      end
    end
  end
end
