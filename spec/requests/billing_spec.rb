# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Billing", type: :request do
  let(:user) { create(:user, plan: "free") }

  describe "POST /billing/checkout", :stripe do
    context "when authenticated" do
      before { sign_in user }

      it "redirects to Stripe Checkout for monthly billing" do
        session = double(url: "https://checkout.stripe.com/test_session")
        billing = instance_double(StripeBilling, create_checkout_session: session)
        allow(StripeBilling).to receive(:new).with(user).and_return(billing)

        post billing_checkout_path(interval: "monthly")

        expect(billing).to have_received(:create_checkout_session).with(interval: "monthly")
        expect(response).to redirect_to("https://checkout.stripe.com/test_session")
      end

      it "redirects to Stripe Checkout for annual billing" do
        session = double(url: "https://checkout.stripe.com/test_annual")
        billing = instance_double(StripeBilling, create_checkout_session: session)
        allow(StripeBilling).to receive(:new).with(user).and_return(billing)

        post billing_checkout_path(interval: "annual")

        expect(billing).to have_received(:create_checkout_session).with(interval: "annual")
        expect(response).to redirect_to("https://checkout.stripe.com/test_annual")
      end
    end

    context "when unauthenticated" do
      it "redirects to sign-in" do
        post billing_checkout_path(interval: "monthly")

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET /billing/success" do
    it "redirects authenticated developers to the dashboard with a notice" do
      sign_in user

      get billing_success_path

      expect(response).to redirect_to(dashboard_path)
      expect(flash[:notice]).to include("Welcome to Pro")
    end
  end
end
