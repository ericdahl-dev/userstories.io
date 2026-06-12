# frozen_string_literal: true

require "rails_helper"

RSpec.describe StripeWebhookHandler do
  let(:user) { create(:user, plan: "free") }

  def build_event(type:, object:)
    Stripe::Event.construct_from(
      id: "evt_#{SecureRandom.hex(8)}",
      type: type,
      data: { object: object }
    )
  end

  describe "#process!" do
    it "upgrades the user to pro on checkout.session.completed" do
      event = build_event(
        type: "checkout.session.completed",
        object: {
          customer: "cus_123",
          subscription: "sub_123",
          client_reference_id: user.id.to_s,
          metadata: { user_id: user.id.to_s }
        }
      )

      described_class.new(event).process!

      expect(user.reload).to have_attributes(
        plan: "pro",
        stripe_customer_id: "cus_123",
        stripe_subscription_id: "sub_123"
      )
      expect(StripeWebhookEvent.find_by(stripe_event_id: event.id)).to be_present
    end

    it "downgrades the user on customer.subscription.deleted" do
      user.update!(plan: "pro", stripe_customer_id: "cus_123", stripe_subscription_id: "sub_123")

      event = build_event(
        type: "customer.subscription.deleted",
        object: { id: "sub_123", customer: "cus_123", status: "canceled" }
      )

      described_class.new(event).process!

      expect(user.reload).to have_attributes(plan: "free", stripe_subscription_id: nil)
    end

    it "is idempotent when the same event is delivered twice" do
      event = build_event(
        type: "checkout.session.completed",
        object: {
          customer: "cus_123",
          subscription: "sub_123",
          client_reference_id: user.id.to_s,
          metadata: { user_id: user.id.to_s }
        }
      )

      2.times { described_class.new(event).process! }

      expect(StripeWebhookEvent.where(stripe_event_id: event.id).count).to eq(1)
      expect(user.reload.plan).to eq("pro")
    end
  end
end
