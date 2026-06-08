FactoryBot.define do
  factory :project do
    association :user
    sequence(:name) { |n| "Project #{n}" }
    sequence(:github_repo) { |n| "owner/repo-#{n}" }
  end
end
