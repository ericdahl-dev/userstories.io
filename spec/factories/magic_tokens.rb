FactoryBot.define do
  factory :magic_token do
    collaborator { nil }
    token { "MyString" }
    expires_at { "2026-06-08 15:48:30" }
    used_at { "2026-06-08 15:48:30" }
  end
end
