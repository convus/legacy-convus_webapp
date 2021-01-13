FactoryBot.define do
  factory :citation_challenge do
    transient do
      citation { FactoryBot.create(:citation) }
      hypothesis { FactoryBot.create(:hypothesis) }
    end
    creator { FactoryBot.create(:user) }
    hypothesis_citation { FactoryBot.create(:hypothesis_citation, url: citation.url, hypothesis: hypothesis) }

    trait :approved do
      approved_at { Time.current - 2.hours }
    end

    factory :citation_challenge_approved, traits: [:approved]
  end
end
