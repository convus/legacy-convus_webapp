FactoryBot.define do
  factory :assertion do
    creator { FactoryBot.create(:user) }
    sequence(:title) { |n| "Citation Title #{n}" }
  end
end
