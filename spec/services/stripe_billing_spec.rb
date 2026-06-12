# frozen_string_literal: true

require "rails_helper"

RSpec.describe StripeBilling do
  let(:user) { create(:user) }

  describe ".configured?" do
    it "returns true when required env vars are present", :stripe do
      expect(described_class.configured?).to be(true)
    end

    it "returns false when Stripe keys are missing" do
      expect(described_class.configured?).to be(false)
    end
  end

  describe "#create_checkout_session", :stripe do
    it "creates a subscription checkout session for the developer" do
      customer = double(id: "cus_new")
      session = double(url: "https://checkout.stripe.com/pay")

      expect(Stripe::Customer).to receive(:create).with(
        email: user.email,
        metadata: { user_id: user.id.to_s }
      ).and_return(customer)

      expect(Stripe::Checkout::Session).to receive(:create).with(
        hash_including(
          mode: "subscription",
          customer: "cus_new",
          client_reference_id: user.id.to_s,
          line_items: [ { price: "price_monthly_test", quantity: 1 } ]
        )
      ).and_return(session)

      result = described_class.new(user).create_checkout_session(interval: "monthly")

      expect(result).to eq(session)
      expect(user.reload.stripe_customer_id).to eq("cus_new")
    end

    it "reuses an existing Stripe customer" do
      user.update!(stripe_customer_id: "cus_existing")
      session = double(url: "https://checkout.stripe.com/pay")

      expect(Stripe::Customer).not_to receive(:create)
      expect(Stripe::Checkout::Session).to receive(:create).with(
        hash_including(customer: "cus_existing")
      ).and_return(session)

      described_class.new(user).create_checkout_session(interval: "annual")
    end
  end
end
