FactoryBot.define do
  factory :citation_challenge do
    transient do
      citation { FactoryBot.create(:citation) }
      hypothesis { FactoryBot.create(:hypothesis) }
    end
    creator { FactoryBot.create(:user) }
    hypothesis_citation { FactoryBot.create(:hypothesis_citation, url: citation.url, hypothesis: hypothesis) }
  end
end
