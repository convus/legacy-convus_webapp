FactoryBot.define do
  factory :hypothesis_citation do
    creator { FactoryBot.create(:user) }
    hypothesis { FactoryBot.create(:hypothesis, creator: creator) }
    sequence(:url) { |n| "https://example.com/hypothesis_citation-#{n}" }

    trait :approved do
      approved_at { Time.current - 2.hours }
      hypothesis { FactoryBot.create(:hypothesis_approved, creator: creator) }
    end

    factory :hypothesis_citation_approved, traits: [:approved]

    factory :hypothesis_citation_challenge_by_another_citation do
      kind { "challenge_by_another_citation" }
      challenged_hypothesis_citation { FactoryBot.create(:hypothesis_citation) }
      hypothesis { nil } # set in calculated_attributes


      factory :hypothesis_citation_challenge_citation_quotation do
        kind { "challenge_citation_quotation" }
        citation { challenged_hypothesis_citation.citation }
        url { challenged_hypothesis_citation.url }
      end
    end
  end
end
