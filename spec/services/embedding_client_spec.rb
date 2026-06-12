require "rails_helper"

RSpec.describe EmbeddingClient do
  let(:client) { instance_double(OpenAI::Client) }
  subject(:embedding_client) { described_class.new(client: client) }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("OPENROUTER_API_KEY").and_return("sk-test")
  end

  describe "#embed" do
    it "returns the embedding vector from OpenRouter" do
      vector = Array.new(Submission::EMBEDDING_DIMENSIONS, 0.1)
      allow(client).to receive(:embeddings).and_return(
        { "data" => [ { "embedding" => vector } ] }
      )

      result = embedding_client.embed(text: "dark mode toggle")

      expect(result).to eq(vector)
      expect(client).to have_received(:embeddings).with(
        parameters: {
          model: described_class::DEFAULT_MODEL,
          input: "dark mode toggle"
        }
      )
    end

    it "raises when the API key is missing" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("OPENROUTER_API_KEY").and_return(nil)

      expect { described_class.new.embed(text: "hello") }
        .to raise_error(EmbeddingClient::Error, /OPENROUTER_API_KEY/)
    end

    it "raises when the response is empty" do
      allow(client).to receive(:embeddings).and_return({ "data" => [] })

      expect { embedding_client.embed(text: "hello") }
        .to raise_error(EmbeddingClient::Error, /empty response/)
    end
  end

  describe ".configured?" do
    it "is true when OPENROUTER_API_KEY is set" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("OPENROUTER_API_KEY").and_return("sk-test")

      expect(described_class.configured?).to be true
    end
  end
end
