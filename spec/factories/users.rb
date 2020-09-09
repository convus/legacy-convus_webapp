FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "email#{n}@bikehub.com" }

    factory :user_developer do
      role { "developer" }
    end
  end
end
