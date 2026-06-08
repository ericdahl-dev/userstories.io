FactoryBot.define do
  factory :project do
    user { nil }
    name { "MyString" }
    github_repo { "MyString" }
    share_token { "MyString" }
  end
end
