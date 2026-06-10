# frozen_string_literal: true

module SystemHelpers
  def setup_cuprite!
    driven_by :cuprite
  end

  def stub_refinement_llm!
    allow(LlmClient).to receive(:configured?).and_return(false)
    allow(RefineSubmissionJob).to receive(:perform_later)
    allow(RefinementTurnJob).to receive(:perform_later)
  end

  def visit_magic_link_from_email!
    perform_enqueued_jobs

    email = ActionMailer::Base.deliveries.last
    raise "Expected a magic link email" unless email

    body = email.text_part&.body&.to_s || email.body.to_s
    path = body[%r{/p/[^\s]+}]
    raise "Could not parse magic link from email" unless path

    visit path
  end
end

RSpec.configure do |config|
  config.include SystemHelpers, type: :system
  config.include ActiveJob::TestHelper, type: :system
  config.include Warden::Test::Helpers, type: :system

  config.before type: :system do
    ActionMailer::Base.deliveries.clear
  end

  config.after type: :system do
    Warden.test_reset!
  end
end
