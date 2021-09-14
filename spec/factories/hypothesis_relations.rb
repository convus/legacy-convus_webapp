FactoryBot.define do
  factory :hypothesis_relation do
    hypothesis_earlier { FactoryBot.create(:hypothesis_approved) }
    hypothesis_later { FactoryBot.create(:hypothesis_approved) }

    trait :explanation do
      transient do
        explanation { FactoryBot.create(:explanation_approved, hypothesis: hypothesis_earlier) }
        explanation_quote { FactoryBot.create(:explanation_quote, explanation: explanation) }
      end
    end

    factory :hypothesis_relation_citation_conflict, traits: [:explanation] do
      citation { explanation_quote.citation }
    end
  end
end
