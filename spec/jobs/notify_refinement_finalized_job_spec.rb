require "rails_helper"

RSpec.describe NotifyRefinementFinalizedJob, type: :job do
  let(:submission) { create(:submission, refinement_locked_at: Time.current) }

  it "emails the project owner when refinement is finalized" do
    expect {
      described_class.perform_now(submission)
    }.to change { ActionMailer::Base.deliveries.size }.by(1)

    mail = ActionMailer::Base.deliveries.last
    expect(mail.to).to eq([ submission.project.user.email ])
  end

  it "does not email when refinement is not locked" do
    submission.update!(refinement_locked_at: nil)

    expect {
      described_class.perform_now(submission)
    }.not_to change { ActionMailer::Base.deliveries.size }
  end
end
