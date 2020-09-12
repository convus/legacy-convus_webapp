FactoryBot.define do
  factory :hypothesis do
    creator { FactoryBot.create(:user) }
    sequence(:title) { |n| "Citation Title #{n}" }
    family_tag { Tag.family_uncategorized }
  end
end
