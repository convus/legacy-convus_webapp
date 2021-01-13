FactoryBot.define do
  factory :hypothesis_citation do
    hypothesis { FactoryBot.create(:hypothesis) }
    sequence(:url) { |n| "https://example.com/hypothesis_citation-#{n}" }

    trait :approved do
      approved_at { Time.current - 2.hours }
    end

    factory :hypothesis_citation_approved, traits: [:approved]
  end
end
