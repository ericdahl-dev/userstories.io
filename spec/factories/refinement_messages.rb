FactoryBot.define do
  factory :refinement_message do
    association :submission
    role { "assistant" }
    body { "Refined story content" }
  end
end
