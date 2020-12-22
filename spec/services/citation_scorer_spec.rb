require "rails_helper"

RSpec.describe CitationScorer do
  let(:subject) { CitationScorer }

  describe "total_potential_value" do
    it "is the sum of everything, but only highest value publication" do
      expect(CitationScorer.total_potential_score).to eq 26
    end
  end

  describe "hypothesis" do
    it "returns" do
      expect(subject.hypothesis_badges(Hypothesis.new)).to eq({})
    end
    context "with quote quotation" do
      let(:hypothesis_quote) { FactoryBot.create(:hypothesis_quote) }
      let(:hypothesis) { hypothesis_quote.hypothesis }
      it "returns with direct quote" do
        expect(subject.hypothesis_badges(hypothesis)).to eq({has_quote: 1})
      end
    end
    context "with citation" do
      let(:publication) { FactoryBot.create(:publication, impact_factor: 3, has_peer_reviewed_articles: true, has_published_retractions: true) }
      let(:citation) do
        FactoryBot.create(:citation_approved,
          randomized_controlled_trial: true,
          peer_reviewed: true,
          url_is_direct_link_to_full_text: true,
          publication: publication)
      end
      let(:hypothesis) { FactoryBot.create(:hypothesis, tags_string: "A first tag, a second tag") }
      let!(:hypothesis_citation) { FactoryBot.create(:hypothesis_citation, hypothesis: hypothesis, url: citation.url) }
      let(:target_badges) { {has_at_least_two_topics: 1, randomized_controlled_trial: 2, open_access_research: 10, peer_reviewed_medium_impact_factor: 6} }
      it "returns with citation and publication" do
        expect(hypothesis.publications.pluck(:id)).to eq([publication.id])
        expect(hypothesis.citation_for_score&.id).to eq citation.id
        expect(subject.hypothesis_badges(hypothesis)).to eq target_badges
        expect(hypothesis.calculated_score).to eq 19
        hypothesis.update(approved_at: Time.current)
        expect(hypothesis.score).to eq 19
      end
    end
  end

  describe "citation" do
    it "returns" do
      expect(subject.citation_badges(Citation.new)).to eq({})
    end
    context "citation is randomized control trial" do
      let(:citation) { Citation.new(randomized_controlled_trial: true) }
      it "returns 5" do
        expect(subject.citation_badges(citation)).to eq({randomized_controlled_trial: 2})
        expect(citation.calculated_score).to eq 2
      end
    end
    context "has_author and has_publication_date" do
      let(:citation) { Citation.new(authors_str: "Somebody", published_at: Time.current) }
      it "returns 2" do
        expect(subject.citation_badges(citation)).to eq({has_author: 1, has_publication_date: 1})
        expect(citation.calculated_score).to eq 2
      end
    end
    context "citation is peer_reviewed" do
      let(:citation) { Citation.new(peer_reviewed: true) }
      it "returns" do
        expect(subject.citation_badges(citation)).to eq({})
      end
      context "citation is open access" do
        let(:citation) { Citation.new(peer_reviewed: true, url_is_direct_link_to_full_text: true, randomized_controlled_trial: true) }
        it "returns" do
          expect(subject.citation_badges(citation)).to eq({randomized_controlled_trial: 2, open_access_research: 10})
        end
      end
    end
  end

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
      let(:publication) { Publication.new(impact_factor: impact_factor, has_peer_reviewed_articles: true) }
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
