FactoryBot.define do
  factory :hypothesis_quote do
    transient do
      sequence(:text) { |n| "Hypothesis Quote from the citation #{n}" }
      citation { FactoryBot.create(:citation) }
    end
    hypothesis { FactoryBot.create(:hypothesis) }
    quote { FactoryBot.create(:quote, text: text, citation: citation) }
  end
end
