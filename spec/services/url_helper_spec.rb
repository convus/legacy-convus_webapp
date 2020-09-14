require "rails_helper"

RSpec.describe UrlHelper do
  let(:subject) { described_class }

  describe "base_domains" do
    it "returns array of domain with www and without" do
      expect(subject.base_domains("https://www.nationalreview.com/2020/09/the-cdcs-power-grab/")).to eq(["www.nationalreview.com", "nationalreview.com"])
    end
    it "returns just one domain" do
      expect(subject.base_domains("https://en.wikipedia.org/wiki/John_von_Neumann")).to eq(["en.wikipedia.org"])
    end
  end

  describe "base_domain_without_www" do
    it "gets the domain without www" do
      expect(subject.base_domain_without_www("https://www.nationalreview.com/2020/09/the-cdcs-power-grab/")).to eq("nationalreview.com")
    end
    it "includes non-www subdomain" do
      expect(subject.base_domain_without_www("https://en.wikipedia.org/wiki/John_von_Neumann")).to eq "en.wikipedia.org"
    end
    it "handles without http" do
      expect(subject.base_domain_without_www("wikipedia.org/wiki/John_von_Neumann")).to eq "wikipedia.org"
    end
  end

  describe "without_base_domain" do
    it "returns the string if it doesn't seem like a url" do
      expect(subject.without_base_domain("This isn't a URL")).to eq "This isn't a URL"
    end
    it "returns without the base domain" do
      expect(subject.without_base_domain("https://www.nationalreview.com/2020/09/the-cdcs-power-grab/")).to eq "2020/09/the-cdcs-power-grab"
    end
  end

  describe "pretty_url" do
    it "returns without the protocol" do
      expect(subject.pretty_url("https://en.wikipedia.org/wiki/John_von_Neumann/")).to eq "en.wikipedia.org/wiki/John_von_Neumann"
    end
  end
end
