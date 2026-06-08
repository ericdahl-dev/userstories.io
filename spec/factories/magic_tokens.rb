FactoryBot.define do
  factory :magic_token do
    association :collaborator
    expires_at { 15.minutes.from_now }
    used_at { nil }
  end
end
