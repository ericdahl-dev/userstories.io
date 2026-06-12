# frozen_string_literal: true

class StripeBilling
  Error = Class.new(StandardError)

  INTERVALS = {
    "monthly" => "STRIPE_PRICE_MONTHLY",
    "annual" => "STRIPE_PRICE_ANNUAL"
  }.freeze

  def self.configured?
    ENV["STRIPE_SECRET_KEY"].present? &&
      ENV["STRIPE_PRICE_MONTHLY"].present? &&
      ENV["STRIPE_PRICE_ANNUAL"].present?
  end

  def initialize(user)
    @user = user
  end

  def create_checkout_session(interval:)
    raise Error, "Stripe is not configured" unless self.class.configured?

    price_id = price_id_for(interval)

    Stripe::Checkout::Session.create(
      mode: "subscription",
      customer: ensure_customer_id!,
      client_reference_id: @user.id.to_s,
      metadata: { user_id: @user.id.to_s },
      line_items: [ { price: price_id, quantity: 1 } ],
      success_url: success_url,
      cancel_url: cancel_url
    )
  end

  private

  def price_id_for(interval)
    env_key = INTERVALS.fetch(interval) { raise Error, "Invalid billing interval" }
    ENV.fetch(env_key)
  end

  def ensure_customer_id!
    return @user.stripe_customer_id if @user.stripe_customer_id.present?

    customer = Stripe::Customer.create(
      email: @user.email,
      metadata: { user_id: @user.id.to_s }
    )
    @user.update!(stripe_customer_id: customer.id)
    customer.id
  end

  def success_url
    Rails.application.routes.url_helpers.billing_success_url(default_url_options)
  end

  def cancel_url
    Rails.application.routes.url_helpers.billing_cancel_url(default_url_options)
  end

  def default_url_options
    host = ENV.fetch("APP_HOST", "localhost:3000")
    protocol = host.include?("localhost") ? "http" : "https"
    { host: host, protocol: protocol }
  end
end
