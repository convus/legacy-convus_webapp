require "rails_helper"

RSpec.describe Slugifyer do
  describe "slugify" do
    it "handles multiple spaces" do
      expect(Slugifyer.slugify("something    thingggG")).to eq "something-thingggg"
    end

    it "handles &" do
      expect(Slugifyer.slugify("Bikes &amp; Trikes")).to eq "bikes-amp-trikes"
      expect(Slugifyer.slugify("Bikes & Trikes")).to eq "bikes-amp-trikes"
    end
  end
end
