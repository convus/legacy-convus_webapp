FactoryBot.define do
  factory :user_score do
    user { FactoryBot.create(:user) }
    hypothesis { FactoryBot.create(:hypothesis) }
    score { 8 }
    kind { "quality" }
  end
end
