FactoryBot.define do
  factory :hypothesis do
    creator { FactoryBot.create(:user) }
    sequence(:title) { |n| "Hypothesis Title #{n}." }

    trait :approved do
      approved_at { Time.current - 2.hours }
    end

    factory :hypothesis_approved, traits: [:approved]
  end
end
