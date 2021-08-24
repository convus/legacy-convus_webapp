FactoryBot.define do
  factory :argument_quote do
    creator { FactoryBot.create(:user) }
    argument { FactoryBot.create(:argument) }

    sequence(:text) { |n| "Argument quote text #{n}" }

    sequence(:url) { |n| "https://example.com/argument_quote-#{n}" }
  end
end
