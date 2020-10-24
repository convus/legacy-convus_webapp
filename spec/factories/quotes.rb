FactoryBot.define do
  factory :quote do
    citation { FactoryBot.create(:citation) }
    sequence(:text) { |n| "Some quote from the citation #{n}" }
  end
end
