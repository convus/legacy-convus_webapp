FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "email#{n}@bikehub.com" }
    sequence(:username) { |n| "some-handle#{n}" }

    factory :user_developer do
      role { "developer" }
    end
  end
end
