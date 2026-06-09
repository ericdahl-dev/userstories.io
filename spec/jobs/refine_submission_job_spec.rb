require "rails_helper"

RSpec.describe RefineSubmissionJob, type: :job do
  let(:submission) { create(:submission, refinement_status: "pending") }

  describe "#perform" do
    it "skips locked submissions" do
      submission.update!(refinement_locked_at: Time.current)

      expect(SubmissionRefiner).not_to receive(:new)

      described_class.perform_now(submission)
    end

    it "marks the submission failed when the LLM is not configured" do
      allow(LlmClient).to receive(:configured?).and_return(false)

      described_class.perform_now(submission)

      expect(submission.reload.refinement_status).to eq("failed")
    end

    it "refines the submission and marks it completed" do
      refiner = instance_double(SubmissionRefiner, refine!: true)

      allow(LlmClient).to receive(:configured?).and_return(true)
      allow(SubmissionRefiner).to receive(:new).with(submission).and_return(refiner)

      described_class.perform_now(submission)

      expect(submission.reload.refinement_status).to eq("completed")
      expect(refiner).to have_received(:refine!)
    end

    it "marks the submission failed when refinement raises" do
      refiner = instance_double(SubmissionRefiner)
      allow(refiner).to receive(:refine!).and_raise(LlmClient::Error, "timeout")
      allow(LlmClient).to receive(:configured?).and_return(true)
      allow(SubmissionRefiner).to receive(:new).with(submission).and_return(refiner)

      described_class.perform_now(submission)

      expect(submission.reload.refinement_status).to eq("failed")
    end
  end
end
