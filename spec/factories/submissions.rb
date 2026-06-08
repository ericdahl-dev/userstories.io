FactoryBot.define do
  factory :submission do
    association :collaborator
    association :project
    sequence(:title) { |n| "User story #{n}" }
    body { "As a user, I want something, so that I benefit." }
    status { "pending" }
  end
end
