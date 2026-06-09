require "rails_helper"

RSpec.describe RefinementTurnJob, type: :job do
  let(:submission) { create(:submission, refinement_status: "pending") }

  describe "#perform" do
    it "skips locked submissions" do
      submission.update!(refinement_locked_at: Time.current)

      expect(SubmissionRefinementTurn).not_to receive(:new)

      described_class.perform_now(submission)
    end

    it "marks the submission failed when the LLM is not configured" do
      allow(LlmClient).to receive(:configured?).and_return(false)

      described_class.perform_now(submission)

      expect(submission.reload.refinement_status).to eq("failed")
    end

    it "runs the refinement turn and marks it completed" do
      turn = instance_double(SubmissionRefinementTurn, run!: true)

      allow(LlmClient).to receive(:configured?).and_return(true)
      allow(SubmissionRefinementTurn).to receive(:new).with(submission).and_return(turn)

      described_class.perform_now(submission)

      expect(submission.reload.refinement_status).to eq("completed")
      expect(turn).to have_received(:run!)
    end

    it "marks the submission failed when the turn raises" do
      turn = instance_double(SubmissionRefinementTurn)
      allow(turn).to receive(:run!).and_raise(SubmissionRefinementTurn::Error, "bad response")
      allow(LlmClient).to receive(:configured?).and_return(true)
      allow(SubmissionRefinementTurn).to receive(:new).with(submission).and_return(turn)

      described_class.perform_now(submission)

      expect(submission.reload.refinement_status).to eq("failed")
    end
  end
end
