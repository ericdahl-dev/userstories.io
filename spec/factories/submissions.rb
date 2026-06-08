FactoryBot.define do
  factory :submission do
    collaborator { nil }
    project { nil }
    title { "MyString" }
    body { "MyText" }
    status { "MyString" }
    github_issue_number { 1 }
    github_issue_url { "MyString" }
  end
end
