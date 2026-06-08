FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "developer#{n}@example.com" }
    password { "password123" }
    provider { "github" }
    sequence(:uid) { |n| "github_uid_#{n}" }
    github_token { "fake_github_token" }
  end
end
