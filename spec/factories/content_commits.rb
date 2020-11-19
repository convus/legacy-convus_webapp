FactoryBot.define do
  factory :content_commit do
    sequence(:sha) { |n| "adasdfasdfasdfdff#{n}" }
    github_data { JSON.parse(File.read(Rails.root.join("spec", "fixtures", "content_commit.json"))) }
  end
end
