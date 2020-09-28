require "rails_helper"

RSpec.describe HypothesisScorer do
  let(:subject) { described_class }

  describe "publication" do
    it "returns" do
      expect(subject.publication_badges(Publication.new)).to eq({})
    end
    context "has_published_retractions" do
      let(:publication) { Publication.new(has_published_retractions: true) }
      it "returns has_published_retractions" do
        expect(subject.publication_badges(publication)).to eq({non_peer_reviewed_with_retractions: 1})
      end
    end
    context "with impact factor" do
      # TODO: Use per field percentile, rather than specific numbers, for greater accuracy
      let(:publication) { Publication.new(impact_factor: impact_factor, has_published_retractions: true, has_peer_reviewed_articles: true) }
      let(:impact_factor) { 14.144 }
      it "returns high_impact_factor" do
        expect(subject.publication_badges(publication)).to eq({peer_reviewed_high_impact_factor: 10})
      end
      context "4.8" do
        let(:impact_factor) { 3.8 }
        it "returns low_impact_factor" do
          expect(subject.publication_badges(publication)).to eq({peer_reviewed_medium_impact_factor: 6})
        end
      end
      context "0.12" do
        let(:impact_factor) { 0.12 }
        it "returns low_impact_factor" do
          expect(subject.publication_badges(publication)).to eq({peer_reviewed_low_impact_factor: 3})
        end
      end
      context "nil" do
        let(:impact_factor) { nil }
        it "returns low_impact_factor" do
          expect(subject.publication_badges(publication)).to eq({peer_reviewed_low_impact_factor: 3})
        end
      end
    end
  end
end
