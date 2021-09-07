FactoryBot.define do
  factory :hypothesis_challenge do
    hypothesis { FactoryBot.create(:hypothesis) }
    challenged_hypothesis { FactoryBot.create(:hypothesis_approved) }

    trait :explanation do
      transient do
        explanation { FactoryBot.create(:explanation_approved, hypothesis: challenged_hypothesis) }
        explanation_quote { FactoryBot.create(:explanation_quote, explanation: explanation) }
      end
    end

    factory :hypothesis_challenge_citation, traits: [:explanation] do
      challenged_citation { explanation_quote.citation }
    end

    factory :hypothesis_challenge_explanation_quote, traits: [:explanation] do
      challenged_explanation_quote { explanation_quote }
    end
  end
end
