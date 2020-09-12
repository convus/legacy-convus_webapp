FactoryBot.define do
  factory :tag do
    sequence(:title) { |n| "Tag #{n}" }
  end
end
