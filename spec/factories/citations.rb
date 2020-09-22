FactoryBot.define do
  factory :citation do
    creator { FactoryBot.create(:user) }
    sequence(:title) { |n| "Citation Title #{n}" }
    sequence(:url) { |n| "https://example.com/citation-#{n}" }
    factory :citation_approved do
      approved_at { Time.current }
    end
  end
end
