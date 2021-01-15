FactoryBot.define do
  factory :hypothesis_citation do
    hypothesis { FactoryBot.create(:hypothesis, creator_id: creator) }
    sequence(:url) { |n| "https://example.com/hypothesis_citation-#{n}" }

    trait :approved do
      approved_at { Time.current - 2.hours }
      hypothesis { FactoryBot.create(:hypothesis_approved, creator: creator) }
    end

    factory :hypothesis_citation_approved, traits: [:approved]

    factory :hypothesis_citation_challenge_citation_quotation do
      kind { "challenge_citation_quotation" }
      challenged_hypothesis_citation { FactoryBot.create(:hypothesis_citation) }
      citation { challenged_hypothesis_citation.citation }
      url { challenged_hypothesis_citation.url }
    end

    factory :hypothesis_citation_challenge_by_another_citation do
      kind { "challenge_by_another_citation" }
      challenged_hypothesis_citation { FactoryBot.create(:hypothesis_citation) }
    end
  end
end
