FactoryBot.define do
  factory :collaborator do
    sequence(:email) { |n| "collaborator#{n}@example.com" }
    sequence(:name) { |n| "Collaborator #{n}" }
  end
end
