FactoryBot.define do
  factory :hypothesis_citation do
    hypothesis { FactoryBot.create(:hypothesis, creator_id: creator) }
    sequence(:url) { |n| "https://example.com/hypothesis_citation-#{n}" }

    trait :approved do
      approved_at { Time.current - 2.hours }
      hypothesis { FactoryBot.create(:hypothesis_approved, creator: creator) }
    end

    factory :hypothesis_citation_approved, traits: [:approved]
  end
end
