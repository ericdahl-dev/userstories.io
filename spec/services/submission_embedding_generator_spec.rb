require "rails_helper"

RSpec.describe SubmissionEmbeddingGenerator do
  let(:submission) { create(:submission, title: "Dark mode", body: "Add a night theme") }
  let(:embedding_client) { instance_double(EmbeddingClient) }
  let(:vector) { Array.new(Submission::EMBEDDING_DIMENSIONS) { |i| i * 0.001 } }

  subject(:generator) { described_class.new(submission, embedding_client: embedding_client) }

  describe "#generate!" do
    it "stores an embedding from title and body" do
      allow(embedding_client).to receive(:embed)
        .with(text: "Dark mode\n\nAdd a night theme")
        .and_return(vector)

      generator.generate!

      stored = submission.reload.embedding.to_a
      expect(stored.length).to eq(vector.length)
      stored.zip(vector).each do |actual, expected|
        expect(actual).to be_within(1e-6).of(expected)
      end
    end

    it "skips when the submission already has an embedding" do
      submission.update!(embedding: vector)
      allow(embedding_client).to receive(:embed)

      generator.generate!

      expect(embedding_client).not_to have_received(:embed)
    end
  end
end
