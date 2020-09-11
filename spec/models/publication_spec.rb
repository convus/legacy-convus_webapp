require "rails_helper"

RSpec.describe Publication, type: :model do
  it_behaves_like "TitleSluggable"

  describe "create_for_url" do
    it "creates once for a base" do
      publication = Publication.create_for_url("https://www.nytimes.com/2020/09/11/us/wildfires-live-updates.html")
      expect(publication.home_url).to eq "https://www.nytimes.com"
      expect(publication.title).to eq "nytimes.com"
      expect {
        expect(Publication.create_for_url("https://www.nytimes.com/interactive/2020/us/fires-map-tracker.html").id).to eq publication.id
      }.to_not change(Publication, :count)
      expect(Publication.friendly_find("https://www.nytimes.com/interactive/2020")).to eq publication
    end
    context "with subdomain" do
      it "creates with subdomain" do
        publication = Publication.create_for_url("blog.bigagnes.com/self-support-on-idahos-south-fork/")
        expect(publication.home_url).to eq "http://blog.bigagnes.com"
        expect(publication.title).to eq "blog.bigagnes.com"
      end
    end
    context "not a url" do
      it "doesn't create a publication" do
        expect {
          Publication.create_for_url("asdf9adfasdfasdf")
        }.to_not change(Publication, :count)
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
  end
end
