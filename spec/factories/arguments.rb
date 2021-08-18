FactoryBot.define do
  factory :argument do
    creator { FactoryBot.create(:user) }
    hypothesis { FactoryBot.create(:hypothesis) }

    sequence(:text) { |n| "Argument text #{n}" }

    trait :approved do
      approved_at { Time.current - 2.hours }
    end

    factory :argument_approved, traits: [:approved]
  end
end
