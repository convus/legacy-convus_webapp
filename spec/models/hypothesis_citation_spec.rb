require "rails_helper"

RSpec.describe HypothesisCitation, type: :model do
  it_behaves_like "GithubSubmittable"

  describe "factory" do
    let(:hypothesis_citation) { FactoryBot.create(:hypothesis_citation) }
    let(:hypothesis) { hypothesis_citation.hypothesis }
    let(:citation) { hypothesis_citation.citation }
    it "has a valid factory" do
      expect(hypothesis_citation).to be_valid
      expect(hypothesis_citation.kind).to eq "hypothesis_supporting"
      expect(hypothesis_citation.challenge?).to be_falsey
      expect(hypothesis_citation.approved?).to be_falsey
      # Another hypothesis_citation of same url is invalid
      hypothesis_citation_invalid = FactoryBot.build(:hypothesis_citation, hypothesis: hypothesis, url: hypothesis_citation.url)
      expect(hypothesis_citation_invalid).to_not be_valid
    end
    context "challenges" do
      let(:challenge_citation_quotation) do
        FactoryBot.create(:hypothesis_citation_challenge_citation_quotation,
          challenged_hypothesis_citation: hypothesis_citation)
      end
      let(:challenge_by_another_citation) do
        FactoryBot.create(:hypothesis_citation_challenge_by_another_citation,
          :approved,
          challenged_hypothesis_citation: hypothesis_citation)
      end
      it "both are valid simultaneously" do
        expect(challenge_citation_quotation).to be_valid
        expect(challenge_citation_quotation.challenged_hypothesis_citation_id).to eq hypothesis_citation.id
        expect(challenge_citation_quotation.hypothesis_id).to eq hypothesis.id
        expect(challenge_citation_quotation.citation_id).to eq citation.id
        expect(challenge_citation_quotation.kind).to eq "challenge_citation_quotation"
        expect(challenge_citation_quotation.kind_humanized).to eq "Challenge quotation's accuracy in piece"
        expect(challenge_citation_quotation.challenge?).to be_truthy
        expect(challenge_citation_quotation.challenged_hypothesis_citation&.id).to eq hypothesis_citation.id
        expect(challenge_citation_quotation.url).to eq hypothesis_citation.url
        expect(challenge_citation_quotation.citation_id).to eq hypothesis_citation.citation_id
        expect(challenge_citation_quotation.approved?).to be_falsey
        hypothesis_citation.reload
        expect(hypothesis_citation.challenges.pluck(:id)).to eq([challenge_citation_quotation.id])
        expect(hypothesis_citation.challenges_approved.pluck(:id)).to eq([])
        expect(HypothesisCitation.no_approved_challenges.map(&:id)).to match_array([hypothesis_citation.id, challenge_citation_quotation.id])
        expect(HypothesisCitation.approved_challenges.map(&:id)).to eq([])
        # And the challenge by another citation is valid
        expect(challenge_by_another_citation).to be_valid
        expect(challenge_by_another_citation.challenged_hypothesis_citation_id).to eq hypothesis_citation.id
        expect(challenge_by_another_citation.hypothesis_id).to eq hypothesis.id
        expect(challenge_by_another_citation.citation_id).to_not eq citation.id
        expect(challenge_by_another_citation.kind).to eq "challenge_by_another_citation"
        expect(challenge_by_another_citation.challenge?).to be_truthy
        expect(challenge_by_another_citation.challenged_hypothesis_citation&.id).to eq hypothesis_citation.id
        expect(challenge_by_another_citation.citation_id).to be_present
        expect(challenge_by_another_citation.citation_id).to_not eq hypothesis_citation.id
        expect(challenge_by_another_citation.approved?).to be_truthy
        # challenging again with another url is valid
        challenge_by_another_citation2 = FactoryBot.create(:hypothesis_citation_challenge_by_another_citation, challenged_hypothesis_citation: hypothesis_citation)
        expect(challenge_by_another_citation2).to be_valid
        expect(challenge_by_another_citation2.hypothesis_id).to eq hypothesis.id
        # But challenging by citation quotation again isn't, since it already exists
        challenge_citation_quotation_invalid = FactoryBot.build(:hypothesis_citation_challenge_citation_quotation, challenged_hypothesis_citation: hypothesis_citation)
        expect(challenge_citation_quotation_invalid).to_not be_valid
        # And challenging with the existing url isn't, since it already exists
        challenge_by_another_citation_invalid = FactoryBot.build(:hypothesis_citation_challenge_by_another_citation, challenged_hypothesis_citation: hypothesis_citation, url: challenge_by_another_citation.url)
        expect(challenge_by_another_citation_invalid.url).to eq challenge_by_another_citation.url
        expect(challenge_by_another_citation_invalid).to_not be_valid
        hypothesis_citation.reload
        # Commented out in PR#137 because flaky and don't matter
        # expect(hypothesis_citation.challenges.pluck(:id)).to eq([challenge_citation_quotation.id, challenge_by_another_citation.id, challenge_by_another_citation2.id])
        # expect(hypothesis_citation.challenges_approved.pluck(:id)).to eq([challenge_by_another_citation.id])
        # expect(HypothesisCitation.no_approved_challenges.map(&:id)).to eq([challenge_citation_quotation.id, challenge_by_another_citation.id, challenge_by_another_citation2.id])
        # expect(HypothesisCitation.approved_challenges.map(&:id)).to eq([hypothesis_citation.id])
      end
    end
  end

  describe "url" do
    let(:url) { "https://example.com/stuff?utm_things=asdfasdf" }
    let(:hypothesis) { FactoryBot.create(:hypothesis, creator: FactoryBot.create(:user)) }
    let!(:hypothesis_citation) { FactoryBot.build(:hypothesis_citation, hypothesis: hypothesis, citation: nil, url: url) }
    it "creates the citation" do
      expect {
        hypothesis_citation.save
      }.to change(Citation, :count).by 1
      expect(hypothesis_citation.url).to eq "https://example.com/stuff"
      expect(hypothesis_citation.hypothesis.creator).to be_present
      citation = hypothesis_citation.citation
      expect(citation.url).to eq hypothesis_citation.url
      expect(citation.creator_id).to eq hypothesis_citation.hypothesis.creator_id
    end
    context "citation already exists" do
      let!(:citation) { FactoryBot.create(:citation, url: url, creator: nil) }
      it "associates with the existing citation" do
        expect(citation).to be_valid
        expect(citation.creator_id).to be_blank
        expect {
          hypothesis_citation.save
        }.to change(Citation, :count).by 0
        expect(hypothesis_citation.citation_id).to eq citation.id
        expect(citation.creator_id).to be_blank
      end
    end
    context "citation changed" do
      it "updates to a new citation" do
        hypothesis_citation.save
        citation1 = hypothesis_citation.citation
        expect(citation1).to be_valid
        hypothesis_citation.update(url: "https://example.com/other-stuff")
        expect(hypothesis_citation.citation.id).to_not eq citation1.id
        citation1.reload
        expect(citation1).to be_valid
      end
    end
    context "challenge_same_citation_kind" do
      let(:hypothesis_citation_challenge) do
        FactoryBot.create(:hypothesis_citation_challenge_citation_quotation,
          challenged_hypothesis_citation: hypothesis_citation,
          url: "https://example.com")
      end
      it "uses the same url" do
        expect(hypothesis_citation_challenge).to be_valid
        expect(hypothesis_citation_challenge.challenge_same_citation_kind?).to be_truthy
        expect(hypothesis_citation_challenge.url).to eq hypothesis_citation.url
      end
    end
  end

  describe "quotes_text" do
    let(:citation) { FactoryBot.create(:citation) }
    let(:hypothesis) { FactoryBot.create(:hypothesis, created_at: Time.current - 5.minutes) }
    let(:hypothesis_citation) { HypothesisCitation.new(url: citation.url, hypothesis: hypothesis, quotes_text: quotes_text) }
    let(:quotes_text) { " " }
    it "is ok if blank" do
      expect {
        expect(hypothesis_citation.save).to be_truthy
      }.to change(UpdateCitationQuotesJob.jobs, :count).by 1
      expect(hypothesis_citation.quotes_text).to eq nil
      expect(hypothesis_citation.hypothesis_quotes.pluck(:id)).to eq([])
      expect(hypothesis_citation.quotes.pluck(:id)).to eq([])
    end
    context "with multiple quotes" do
      let(:quote_text1) { "The Shooting arrest population is similarly distributed to the shooting suspects. Black arrestees (71.6%) and Hispanic arrestees (24.1%) account for the majority of Shooting arrest population. White arrestees (2.7%) and Asian/Pacific Islander arrestees (1.5%) account for the remaining portion of the Shooting arrest population." }
      let(:quotes_text) { "  some quote\n\n #{quote_text1} " }
      it "saves, doesn't create duplicates or error when resubmitted" do
        expect(citation.quotes.count).to eq 0
        expect(hypothesis.quotes.count).to eq 0
        Sidekiq::Worker.clear_all
        expect {
          expect(hypothesis_citation).to be_valid
          expect(hypothesis_citation.save).to be_truthy
        }.to change(Quote, :count).by 2
        expect(UpdateCitationQuotesJob.jobs.count).to eq 1
        UpdateCitationQuotesJob.drain
        expect(hypothesis_citation.hypothesis_quotes.count).to eq 2
        hypothesis_quote1 = hypothesis_citation.hypothesis_quotes.first
        hypothesis_quote2 = hypothesis_citation.hypothesis_quotes.second
        expect(hypothesis_quote1.score).to be > hypothesis_quote2.score
        expect(hypothesis_quote1.citation_id).to eq citation.id
        expect(hypothesis_quote1.hypothesis_id).to eq hypothesis.id
        expect(hypothesis_quote1.hypothesis_citation_id).to eq hypothesis_citation.id
        expect(hypothesis_citation.quotes.count).to eq 2
        expect(hypothesis_citation.quotes.pluck(:text)).to eq(["some quote", quote_text1])

        hypothesis_citation.update(quotes_text: "#{quote_text1}\n\n\nsome quote")
        expect(UpdateCitationQuotesJob.jobs.count).to eq 1
        UpdateCitationQuotesJob.drain
        hypothesis_citation.reload
        hypothesis_quote1.reload
        hypothesis_quote2.reload
        expect(hypothesis_citation.quotes_text).to eq("#{quote_text1}\n\nsome quote")
        expect(hypothesis_quote1.score).to be < hypothesis_quote2.score
        expect(hypothesis_citation.quotes.pluck(:id)).to eq([hypothesis_quote2.quote_id, hypothesis_quote1.quote_id])
        hypothesis_citation.update(quotes_text: quote_text1)
        expect(UpdateCitationQuotesJob.jobs.count).to eq 1
        UpdateCitationQuotesJob.drain
        expect(hypothesis_citation.quotes_text).to eq quote_text1
        hypothesis_citation.reload
        expect(hypothesis_citation.quotes.count).to eq 1
        expect(hypothesis_citation.quotes.pluck(:id)).to eq([hypothesis_quote2.quote_id])

        citation.reload
        expect(citation.quotes.pluck(:text)).to match_array([quote_text1])
      end
      context "other hypothesis_quote exists" do
        let!(:hypothesis_quote_other) { FactoryBot.create(:hypothesis_quote, text: " #{quote_text1}", citation: citation) }
        it "saves, doesn't create duplicates, doesn't delete other quote if it's used" do
          expect(citation.quotes.count).to eq 1
          expect(hypothesis.quotes.count).to eq 0
          Sidekiq::Worker.clear_all
          expect {
            expect(hypothesis_citation).to be_valid
            expect(hypothesis_citation.save).to be_truthy
          }.to change(Quote, :count).by 1
          expect(UpdateCitationQuotesJob.jobs.count).to eq 1
          UpdateCitationQuotesJob.drain
          expect(hypothesis_citation.quotes_text).to eq("some quote\n\n#{quote_text1}")
          expect(hypothesis_citation.quotes.count).to eq 2
          expect(hypothesis_citation.quotes.pluck(:id)).to include hypothesis_quote_other.quote_id

          hypothesis_citation.update(quotes_text: "some quote")
          Sidekiq::Worker.clear_all
          expect {
            expect(hypothesis_citation).to be_valid
            expect(hypothesis_citation.save).to be_truthy
          }.to change(Quote, :count).by 0
          expect(UpdateCitationQuotesJob.jobs.count).to eq 1
          UpdateCitationQuotesJob.drain
          citation.reload
          expect(citation.quotes.pluck(:text)).to match_array(["some quote", quote_text1])
        end
      end
    end
  end
end
