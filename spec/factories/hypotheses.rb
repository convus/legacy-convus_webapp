FactoryBot.define do
  factory :hypothesis do
    creator { FactoryBot.create(:user) }
    sequence(:title) { |n| "Citation Title #{n}" }
    factory :hypothesis_approved do
      approved_at { Time.current - 2.hours }
    end
    factory :hypothesis_refuted do
      transient do
        refuting_hypothesis { FactoryBot.create(:hypothesis) }
      end
      after(:create) do |hypothesis, evaluator|
        hypothesis.refuting_refutations.create(refuter_hypothesis: evaluator.refuting_hypothesis)
      end
    end
  end
end
