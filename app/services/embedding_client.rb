class EmbeddingClient
  Error = Class.new(StandardError)

  OPENROUTER_BASE = "https://openrouter.ai/api/v1"
  DEFAULT_MODEL = ENV.fetch("OPENROUTER_EMBEDDING_MODEL", "openai/text-embedding-3-small")

  def initialize(client: nil)
    @client = client || build_client
  end

  def embed(text:)
    raise Error, "OPENROUTER_API_KEY is not configured" if access_token.blank?

    response = @client.embeddings(
      parameters: {
        model: DEFAULT_MODEL,
        input: text
      }
    )

    embedding = response.dig("data", 0, "embedding")
    raise Error, "empty response from OpenRouter" if embedding.blank?

    embedding
  rescue Faraday::Error => e
    raise Error, e.message
  end

  def self.configured?
    ENV["OPENROUTER_API_KEY"].present?
  end

  private

  def build_client
    OpenAI::Client.new(
      access_token: access_token,
      uri_base: OPENROUTER_BASE,
      request_timeout: 60,
      extra_headers: openrouter_headers
    )
  end

  def access_token
    ENV["OPENROUTER_API_KEY"]
  end

  def openrouter_headers
    headers = { "X-OpenRouter-Title" => "userstories.io" }
    if (host = ENV["APP_HOST"]).present?
      headers["HTTP-Referer"] = "https://#{host}"
    end
    headers
  end
end
