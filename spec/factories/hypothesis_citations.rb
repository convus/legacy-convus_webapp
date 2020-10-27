FactoryBot.define do
  factory :hypothesis_citation do
    hypothesis { FactoryBot.create(:hypothesis) }
    sequence(:url) { |n| "https://example.com/hypothesis_citation-#{n}" }
  end
end
