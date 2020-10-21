FactoryBot.define do
  factory :hypothesis_citation do
    hypothesis { FactoryBot.create(:hypothesis) }
    citation { FactoryBot.create(:citation) }
  end
end
