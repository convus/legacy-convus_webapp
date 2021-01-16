FactoryBot.define do
  factory :hypothesis_citation do
    hypothesis { FactoryBot.create(:hypothesis) }
    creator { hypothesis.creator }
    sequence(:url) { |n| "https://example.com/hypothesis_citation-#{n}" }

    trait :approved do
      approved_at { Time.current - 2.hours }
      hypothesis { FactoryBot.create(:hypothesis_approved) }
    end

    factory :hypothesis_citation_approved, traits: [:approved]

    factory :hypothesis_citation_challenge_by_another_citation do
      creator { FactoryBot.create(:user) }
      kind { "challenge_by_another_citation" }
      challenged_hypothesis_citation { FactoryBot.create(:hypothesis_citation, creator: creator) }
      hypothesis { nil } # set in calculated_attributes

      factory :hypothesis_citation_challenge_citation_quotation do
        kind { "challenge_citation_quotation" }
        citation { challenged_hypothesis_citation.citation }
        url { challenged_hypothesis_citation.url }
      end
    end
  end
end
