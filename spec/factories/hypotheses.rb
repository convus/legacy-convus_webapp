FactoryBot.define do
  factory :hypothesis do
    creator { FactoryBot.create(:user) }
    sequence(:title) { |n| "Citation Title #{n}" }

    trait :approved do
      approved_at { Time.current - 2.hours }
    end

    factory :hypothesis_approved, traits: [:approved]

    factory :hypothesis_refuted do
      transient do
        hypothesis_refuting { FactoryBot.create(:hypothesis) }
      end
      after(:create) do |hypothesis, evaluator|
        hypothesis.refuting_refutations.create(refuter_hypothesis: evaluator.hypothesis_refuting)
      end
    end
  end
end
