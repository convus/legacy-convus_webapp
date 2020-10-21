FactoryBot.define do
  factory :hypothesis_quote do
    hypothesis { FactoryBot.create(:hypothesis) }
    quote { FactoryBot.create(:quote) }
  end
end
