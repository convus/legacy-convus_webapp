FactoryBot.define do
  factory :explanation_quote do
    creator { FactoryBot.create(:user) }
    explanation { FactoryBot.create(:explanation) }

    sequence(:text) { |n| "Explanation quote text #{n}" }

    sequence(:url) { |n| "https://example.com/explanation_quote-#{n}" }
  end
end
