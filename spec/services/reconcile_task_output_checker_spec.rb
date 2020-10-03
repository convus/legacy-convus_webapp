require "rails_helper"

RSpec.describe ReconcileTaskOutputChecker do
  let(:subject) { described_class }

  describe "success?" do
    it "returns true" do
      expect(described_class.success?("\n\n\nEverything up-to-date \n")).to be_truthy
      expect(described_class.success?("\n\n \n")).to be_truthy
    end
    context "all up to date" do
      it "returns true" do
        expect(described_class.success?("already up to date ")).to be_truthy
        expect(described_class.success?("Already up to date.")).to be_truthy
      end
    end
    context "multiline" do
      let(:multiline) { "HEAD is now at 4f6e4b1 remove duped citations again\nAlready up to date.\n[main 24fc419] reconciliation\n1 file changed, 3 deletions(-)" }
      it "returns truthy" do
        expect(described_class.success?(multiline)).to be_truthy
      end
    end
    context "another multiline" do
      let(:multiline) { "HEAD is now at 0e99686 Reconciliation: 2020-10-03\nFrom github.com:convus/convus_content\n0e99686..c6f2305 main -> origin/main\nUpdating 0e99686..c6f2305\nFast-forward\n...illion-population-as-of-october-2-2020-by-country.yml | 12 ++++++++++++\n...7-and-slightly-more-than-12th-place-sweden-578-70.yml | 12 ++++++++++++\n...-accounted-for-the-remaining-portion-of-known-sho.yml | 16 ++++++++++++++++\n...2-7-and-asian-pacific-islander-arrestees-1-5-acco.yml | 16 ++++++++++++++++\n4 files changed, 56 insertions(+)\ncreate mode 100644 citations/statista/coronavirus-covid-19-deaths-worldwide-per-one-million-population-as-of-october-2-2020-by-country.yml\ncreate mode 100644 hypotheses/in-number-of-cases-per-million-residents-the-united-states-ranks-ninth-632-92-slightly-less-than-eighth-place-great-britain-633-37-and-slightly-more-than-12th-place-sweden-578-70.yml\ncreate mode 100644 hypotheses/the-race-ethnicity-of-known-shooting-suspects-is-most-frequently-black-74-4-hispanic-suspects-accounted-for-an-additional-22-0-of-all-suspects-white-suspects-2-4-and-asian-pacific-islander-suspects-1-1-accounted-for-the-remaining-portion-of-known-sho.yml\ncreate mode 100644 hypotheses/the-shooting-arrest-population-is-similarly-distributed-to-the-shooting-suspects-black-arrestees-71-6-and-hispanic-arrestees-24-1-account-for-the-majority-of-shooting-arrest-population-white-arrestees-2-7-and-asian-pacific-islander-arrestees-1-5-acco.yml\nOn branch main\nYour branch is up to date with 'origin/main'.\nnothing to commit, working tree clean\nEverything up-to-date" }
      it "returns truthy" do
        expect(described_class.success?(multiline)).to be_truthy
      end
    end
  end
end

