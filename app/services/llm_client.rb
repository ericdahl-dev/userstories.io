class LlmClient
  Error = Class.new(StandardError)

  OPENROUTER_BASE = "https://openrouter.ai/api/v1"

  def initialize(client: nil)
    @client = client || build_client
  end

  def chat(messages:, model: default_model)
    raise Error, "OPENROUTER_API_KEY is not configured" if access_token.blank?

    response = @client.chat(
      parameters: {
        model: model,
        messages: messages
      }
    )

    content = response.dig("choices", 0, "message", "content")
    raise Error, "empty response from OpenRouter" if content.blank?

    content
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
      request_timeout: 120,
      extra_headers: openrouter_headers
    )
  end

  def access_token
    ENV["OPENROUTER_API_KEY"]
  end

  def default_model
    ENV.fetch("OPENROUTER_MODEL", "openai/gpt-4o-mini")
  end

  def openrouter_headers
    headers = { "X-OpenRouter-Title" => "userstories.io" }
    if (host = ENV["APP_HOST"]).present?
      headers["HTTP-Referer"] = "https://#{host}"
    end
    headers
  end
end
