FactoryBot.define do
  factory :hypothesis do
    creator { FactoryBot.create(:user) }
    sequence(:title) { |n| "Citation Title #{n}" }
    factory :hypothesis_approved do
      approved_at { Time.current - 2.hours }
    end
  end
end
