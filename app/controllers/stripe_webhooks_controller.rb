# frozen_string_literal: true

class StripeWebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  def create
    payload = request.body.read
    signature = request.env["HTTP_STRIPE_SIGNATURE"]
    secret = ENV["STRIPE_WEBHOOK_SECRET"]

    raise Stripe::SignatureVerificationError, "missing webhook secret" if secret.blank?

    event = Stripe::Webhook.construct_event(payload, signature, secret)
    StripeWebhookHandler.new(event).process!

    head :ok
  rescue Stripe::SignatureVerificationError
    head :bad_request
  rescue JSON::ParserError
    head :bad_request
  end
end
