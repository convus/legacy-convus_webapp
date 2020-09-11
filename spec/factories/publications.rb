FactoryBot.define do
  factory :publication do
    sequence(:title) { |n| "Publication Title #{n}" }
  end
end
