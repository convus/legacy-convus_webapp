require "rails_helper"

RSpec.describe UrlCleaner do
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
    it "returns the domain if there is no query" do
      expect(subject.without_base_domain("https://bikeindex.org")).to eq "bikeindex.org"
      expect(subject.without_base_domain("http://example.com")).to eq "example.com"
    end
  end

  describe "pretty_url" do
    it "returns without the protocol and trailing stuff" do
      expect(subject.pretty_url("https://en.wikipedia.org/wiki/John_von_Neumann/")).to eq "en.wikipedia.org/wiki/John_von_Neumann"
      expect(subject.pretty_url("http://en.wikipedia.org/wiki/John_von_Neumann/?")).to eq "en.wikipedia.org/wiki/John_von_Neumann"
    end
    it "returns without UTM parameters" do
      target = "nationalreview.com/2020/09/bring-back-the-bison/?somethingimportant=33333utm"
      expect(subject.pretty_url(" www.nationalreview.com/2020/09/bring-back-the-bison/?utm_source=recirc-desktop&utm_medium=article&UTM_CAMPAIGN=river&somethingimportant=33333utm&utm_content=top-bar-latest&utm_term=second")).to eq target
    end
  end

  describe "without_utm" do
    it "returns without UTM parameters" do
      target = "https://www.nationalreview.com/2020/09/bring-back-the-bison/?somethingimportant=33333utm"
      expect(subject.without_utm("https://www.nationalreview.com/2020/09/bring-back-the-bison/?utm_source=recirc-desktop&utm_medium=article&UTM_CAMPAIGN=river&somethingimportant=33333utm&utm_content=top-bar-latest&utm_term=second")).to eq target
    end
  end

  describe "with_http" do
    it "returns with http" do
      expect(subject.with_http("example.com")).to eq "http://example.com"
      expect(subject.with_http("http://example.com")).to eq "http://example.com"
      expect(subject.with_http(subject.without_utm("example.com"))).to eq "http://example.com"
    end
    it "doesn't modify https" do
      expect(subject.with_http("https://www.nationalreview.com/2020/09/?")).to eq "https://www.nationalreview.com/2020/09/?"
    end
    it "non-urls returns without http" do
      expect(subject.with_http("whatever")).to eq "whatever"
    end
  end

  describe "looks_like_url?" do
    it "is true for url" do
      expect(subject.looks_like_url?("https://www.nationalreview.com/2020/09/?")).to be_truthy
    end
    it "is true for url without protocol" do
      expect(subject.looks_like_url?("www.nationalreview.com/2020/09/?")).to be_truthy
      expect(subject.looks_like_url?("www.nationalreview.com")).to be_truthy
    end
    it "is false for sentence" do
      expect(subject.looks_like_url?("quick brown fox")).to be_falsey
    end
    it "is false for blank" do
      expect(subject.looks_like_url?(" ")).to be_falsey
    end
  end
end
