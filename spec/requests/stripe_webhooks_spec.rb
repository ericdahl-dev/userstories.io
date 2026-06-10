# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Stripe webhooks", type: :request do
  let(:user) { create(:user, plan: "free") }

  describe "POST /stripe/webhooks", :stripe do
    it "activates pro on a signed checkout.session.completed event" do
      payload = {
        id: "evt_checkout_complete",
        type: "checkout.session.completed",
        data: {
          object: {
            customer: "cus_live",
            subscription: "sub_live",
            client_reference_id: user.id.to_s,
            metadata: { user_id: user.id.to_s }
          }
        }
      }.to_json

      post_stripe_webhook(payload)

      expect(response).to have_http_status(:ok)
      expect(user.reload).to have_attributes(
        plan: "pro",
        stripe_customer_id: "cus_live",
        stripe_subscription_id: "sub_live"
      )
    end

    it "rejects requests with an invalid signature" do
      payload = { id: "evt_bad", type: "checkout.session.completed", data: { object: {} } }.to_json

      post "/stripe/webhooks",
           params: payload,
           headers: {
             "CONTENT_TYPE" => "application/json",
             "HTTP_STRIPE_SIGNATURE" => "t=0,v1=bad"
           }

      expect(response).to have_http_status(:bad_request)
    end

    it "does not upgrade twice when the same event is replayed" do
      payload = {
        id: "evt_replay",
        type: "checkout.session.completed",
        data: {
          object: {
            customer: "cus_replay",
            subscription: "sub_replay",
            client_reference_id: user.id.to_s,
            metadata: { user_id: user.id.to_s }
          }
        }
      }.to_json

      2.times { post_stripe_webhook(payload) }

      expect(response).to have_http_status(:ok)
      expect(StripeWebhookEvent.where(stripe_event_id: "evt_replay").count).to eq(1)
    end
  end
end
