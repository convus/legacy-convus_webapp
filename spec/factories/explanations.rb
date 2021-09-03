FactoryBot.define do
  factory :explanation do
    creator { FactoryBot.create(:user) }
    hypothesis { FactoryBot.create(:hypothesis) }

    sequence(:text) { |n| "Explanation text #{n}" }

    trait :approved do
      approved_at { Time.current - 2.hours }
      hypothesis { FactoryBot.create(:hypothesis_approved) }
    end

    factory :explanation_approved, traits: [:approved]
  end
end
