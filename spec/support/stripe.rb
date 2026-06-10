# frozen_string_literal: true

module StripeTestHelpers
  def stripe_webhook_signature(payload, secret: "whsec_test")
    timestamp = Time.now
    signature = Stripe::Webhook::Signature.compute_signature(timestamp, payload, secret)
    "t=#{timestamp.to_i},v1=#{signature}"
  end

  def post_stripe_webhook(payload, secret: "whsec_test")
    post "/stripe/webhooks",
         params: payload,
         headers: {
           "CONTENT_TYPE" => "application/json",
           "HTTP_STRIPE_SIGNATURE" => stripe_webhook_signature(payload, secret: secret)
         }
  end
end

RSpec.configure do |config|
  config.include StripeTestHelpers, type: :request

  config.around(:each, :stripe) do |example|
    original_secret = ENV["STRIPE_SECRET_KEY"]
    original_webhook = ENV["STRIPE_WEBHOOK_SECRET"]
    original_monthly = ENV["STRIPE_PRICE_MONTHLY"]
    original_annual = ENV["STRIPE_PRICE_ANNUAL"]

    ENV["STRIPE_SECRET_KEY"] = "sk_test_example"
    ENV["STRIPE_WEBHOOK_SECRET"] = "whsec_test"
    ENV["STRIPE_PRICE_MONTHLY"] = "price_monthly_test"
    ENV["STRIPE_PRICE_ANNUAL"] = "price_annual_test"
    Stripe.api_key = ENV["STRIPE_SECRET_KEY"]

    example.run

    ENV["STRIPE_SECRET_KEY"] = original_secret
    ENV["STRIPE_WEBHOOK_SECRET"] = original_webhook
    ENV["STRIPE_PRICE_MONTHLY"] = original_monthly
    ENV["STRIPE_PRICE_ANNUAL"] = original_annual
    Stripe.api_key = ENV["STRIPE_SECRET_KEY"]
  end
end
