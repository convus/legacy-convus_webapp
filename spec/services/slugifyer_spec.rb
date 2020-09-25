require "rails_helper"

RSpec.describe Slugifyer do
  let(:subject) { described_class }

  describe "slugify" do
    it "slugifies the thing we want" do
      expect(subject.slugify("Universal Health Care ")).to eq("universal-health-care")
    end
    it "handles multiple spaces" do
      expect(subject.slugify("something    thingggG-")).to eq "something-thingggg"
    end
    it "handles &" do
      expect(subject.slugify("Bikes &amp; Trikes")).to eq "bikes-amp-trikes"
      expect(subject.slugify("Bikes & Trikes")).to eq "bikes-amp-trikes"
    end
    it "removes diacritics, because safety and ease" do
      expect(subject.slugify("paké rum runñer")).to eq("pake-rum-runner")
    end
    it "strips special characters" do
      expect(subject.slugify("party-\"\"palaces' hause")).to eq("party-palaces-hause")
    end
    it "converts underscores to dashes" do
      expect(subject.slugify("metro_bike_hub_hollywood_vine")).to eq("metro-bike-hub-hollywood-vine")
    end
    it "handles dashed things" do
      expect(subject.slugify("Cool -- A sweet change")).to eq("cool-a-sweet-change")
    end
    it "removes parentheses and what's inside them" do
      expect(subject.slugify("As Soon As Possible Party (ASAPP) ")).to eq("as-soon-as-possible-party-asapp")
    end
    it "returns without periods" do
      expect(subject.slugify("Washington D.C.")).to eq("washington-d-c")
    end
    it "returns without slashes" do
      expect(subject.slugify("Willowbrooks / Rosa Parks Station")).to eq("willowbrooks-rosa-parks-station")
    end
    it "returns nil if given nil" do
      expect(subject.slugify(nil)).to be_nil
    end
    context "urls" do
      it "handles basic URL" do
        expect(subject.slugify("https://bikeindex.org/bikes/323232")).to eq("bikeindex-org-bikes-323232")
      end
      it "handles more complicated" do
        target = "scholar-google-com-scholar-hl-en-as-sdt-0-5-q-22lithium-ion-22-high-temperature-degradation"
        expect(subject.slugify("https://scholar.google.com/scholar?hl=en&as_sdt=0,5&q=%22lithium+ion%22+high+temperature+degradation")).to eq target
      end
    end
  end

  describe "filename_slugify" do
    it "does not leave trailing -" do
      string = "Overall, the case for reduced meat consumption is strong. Vegetarianism is cheaper, better for your health (if you can afford a diverse diet and are not an infant), and is less impactful for the environment. It also has a significant moral cost in terms of animal suffering."
      expect(subject.filename_slugify(string)).to_not match(/-\z/)
    end
  end
end
