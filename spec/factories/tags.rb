FactoryBot.define do
  factory :tag do
    sequence(:title) { |n| "Tag #{n}" }
    factory :tag_approved do
      approved_at { Time.current }
    end
  end
end
