require "rails_helper"

RSpec.describe GenerateSubmissionEmbeddingJob, type: :job do
  let(:submission) { create(:submission) }

  describe "#perform" do
    it "skips when embeddings are not configured" do
      allow(EmbeddingClient).to receive(:configured?).and_return(false)
      allow(SubmissionEmbeddingGenerator).to receive(:generate!)

      described_class.perform_now(submission)

      expect(SubmissionEmbeddingGenerator).not_to have_received(:generate!)
    end

    it "generates an embedding for the submission" do
      allow(EmbeddingClient).to receive(:configured?).and_return(true)
      allow(SubmissionEmbeddingGenerator).to receive(:generate!)

      described_class.perform_now(submission)

      expect(SubmissionEmbeddingGenerator).to have_received(:generate!).with(submission)
    end
  end
end
