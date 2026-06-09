require "rails_helper"

RSpec.describe RefinementTurnJob, type: :job do
  let(:submission) { create(:submission) }
  let(:broadcaster) do
    instance_double(RefinementChatBroadcaster, complete_assistant_reply!: true, processing_failed!: true)
  end

  before do
    allow(RefinementChatBroadcaster).to receive(:new).with(submission).and_return(broadcaster)
  end

  describe "#perform" do
    it "skips locked submissions" do
      submission.update!(refinement_locked_at: Time.current)

      expect(SubmissionRefinementTurn).not_to receive(:new)

      described_class.perform_now(submission)
    end

    it "skips when no collaborator reply is waiting" do
      expect(SubmissionRefinementTurn).not_to receive(:new)

      described_class.perform_now(submission)
    end

    it "marks the submission failed when the LLM is not configured" do
      create(:refinement_message, submission: submission, role: "assistant", body: "Draft")
      create(:refinement_message, submission: submission, role: "collaborator", body: "More detail")
      submission.update!(refinement_status: "processing")

      allow(LlmClient).to receive(:configured?).and_return(false)

      described_class.perform_now(submission)

      expect(submission.reload.refinement_status).to eq("failed")
      expect(broadcaster).to have_received(:processing_failed!)
    end

    it "runs the refinement turn, broadcasts the reply, and marks it completed" do
      create(:refinement_message, submission: submission, role: "assistant", body: "Draft")
      create(:refinement_message, submission: submission, role: "collaborator", body: "More detail")
      submission.update!(refinement_status: "processing")

      turn = instance_double(SubmissionRefinementTurn)
      allow(turn).to receive(:run!) do
        create(:refinement_message, submission: submission, role: "assistant", body: "Updated draft")
      end

      allow(LlmClient).to receive(:configured?).and_return(true)
      allow(SubmissionRefinementTurn).to receive(:new).with(submission).and_return(turn)

      described_class.perform_now(submission)

      expect(submission.reload.refinement_status).to eq("completed")
      expect(turn).to have_received(:run!)
      expect(broadcaster).to have_received(:complete_assistant_reply!) do |message|
        expect(message.body).to eq("Updated draft")
      end
    end

    it "marks the submission failed when the turn raises" do
      create(:refinement_message, submission: submission, role: "assistant", body: "Draft")
      create(:refinement_message, submission: submission, role: "collaborator", body: "More detail")
      submission.update!(refinement_status: "processing")

      turn = instance_double(SubmissionRefinementTurn)
      allow(turn).to receive(:run!).and_raise(SubmissionRefinementTurn::Error, "bad response")
      allow(LlmClient).to receive(:configured?).and_return(true)
      allow(SubmissionRefinementTurn).to receive(:new).with(submission).and_return(turn)

      described_class.perform_now(submission)

      expect(submission.reload.refinement_status).to eq("failed")
      expect(broadcaster).to have_received(:processing_failed!)
    end
  end
end
