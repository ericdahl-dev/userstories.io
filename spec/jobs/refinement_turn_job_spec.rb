require "rails_helper"

RSpec.describe RefinementTurnJob, type: :job do
  let(:submission) { create(:submission) }
  let(:broadcaster) { instance_double(RefinementChatBroadcaster, complete_assistant_reply!: true) }

  before do
    create(:refinement_message, submission: submission, role: "assistant", body: "Draft")
    create(:refinement_message, submission: submission, role: "collaborator", body: "More detail")
    submission.update!(refinement_status: "processing")

    allow(LlmClient).to receive(:configured?).and_return(true)
    allow(RefinementChatBroadcaster).to receive(:new).with(submission).and_return(broadcaster)
  end

  it "broadcasts the assistant reply when the turn completes" do
    turn = instance_double(SubmissionRefinementTurn)

    allow(SubmissionRefinementTurn).to receive(:new).with(submission).and_return(turn)
    allow(turn).to receive(:run!) do
      create(:refinement_message, submission: submission, role: "assistant", body: "Updated draft")
    end

    described_class.perform_now(submission)

    expect(broadcaster).to have_received(:complete_assistant_reply!) do |message|
      expect(message.body).to eq("Updated draft")
    end
    expect(submission.reload.refinement_status).to eq("completed")
  end
end
