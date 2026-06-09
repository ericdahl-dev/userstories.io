require "rails_helper"

RSpec.describe LlmClient do
  let(:fake_client) { instance_double(OpenAI::Client) }

  around do |example|
    original_key = ENV["OPENROUTER_API_KEY"]
    original_host = ENV["APP_HOST"]
    original_model = ENV["OPENROUTER_MODEL"]

    example.run

    ENV["OPENROUTER_API_KEY"] = original_key
    ENV["APP_HOST"] = original_host
    ENV["OPENROUTER_MODEL"] = original_model
  end

  describe ".configured?" do
    it "returns true when OPENROUTER_API_KEY is present" do
      ENV["OPENROUTER_API_KEY"] = "secret"

      expect(described_class.configured?).to be(true)
    end

    it "returns false when OPENROUTER_API_KEY is blank" do
      ENV["OPENROUTER_API_KEY"] = nil

      expect(described_class.configured?).to be(false)
    end
  end

  describe "#chat" do
    subject(:client) { described_class.new(client: fake_client) }

    before { ENV["OPENROUTER_API_KEY"] = "secret" }

    it "returns assistant content from OpenRouter" do
      allow(fake_client).to receive(:chat).and_return(
        { "choices" => [ { "message" => { "content" => "Refined story" } } ] }
      )

      result = client.chat(messages: [ { role: "user", content: "Hello" } ])

      expect(result).to eq("Refined story")
    end

    it "raises when the API key is missing" do
      ENV["OPENROUTER_API_KEY"] = nil

      expect {
        client.chat(messages: [ { role: "user", content: "Hello" } ])
      }.to raise_error(LlmClient::Error, "OPENROUTER_API_KEY is not configured")
    end

    it "raises when the response content is blank" do
      allow(fake_client).to receive(:chat).and_return(
        { "choices" => [ { "message" => { "content" => "" } } ] }
      )

      expect {
        client.chat(messages: [ { role: "user", content: "Hello" } ])
      }.to raise_error(LlmClient::Error, "empty response from OpenRouter")
    end

    it "wraps Faraday errors" do
      allow(fake_client).to receive(:chat).and_raise(Faraday::TimeoutError, "timeout")

      expect {
        client.chat(messages: [ { role: "user", content: "Hello" } ])
      }.to raise_error(LlmClient::Error, "timeout")
    end
  end

  describe "#initialize" do
    it "builds an OpenAI client with OpenRouter defaults" do
      ENV["OPENROUTER_API_KEY"] = "secret"
      ENV["APP_HOST"] = "userstories.io"
      ENV["OPENROUTER_MODEL"] = "anthropic/claude-3.5-sonnet"

      expect(OpenAI::Client).to receive(:new).with(
        access_token: "secret",
        uri_base: "https://openrouter.ai/api/v1",
        request_timeout: 120,
        extra_headers: {
          "X-OpenRouter-Title" => "userstories.io",
          "HTTP-Referer" => "https://userstories.io"
        }
      ).and_return(fake_client)

      described_class.new
    end
  end
end
