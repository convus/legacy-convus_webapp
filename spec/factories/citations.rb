FactoryBot.define do
  factory :citation do
    creator { FactoryBot.create(:user) }
    sequence(:title) { |n| "Citation Title #{n}" }
    sequence(:url) { |n| "https://example.com/citation-#{n}" }
  end
end
