# frozen_string_literal: true

class BillingController < ApplicationController
  before_action :authenticate_user!

  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  def checkout
    session = StripeBilling.new(current_user).create_checkout_session(interval: params[:interval])
    redirect_to session.url, allow_other_host: true
  rescue StripeBilling::Error, Stripe::StripeError => e
    redirect_to dashboard_path, alert: "Unable to start checkout: #{e.message}"
  end

  def success
    redirect_to dashboard_path, notice: "Welcome to Pro! Your subscription is active."
  end

  def cancel
    redirect_to dashboard_path, alert: "Checkout cancelled — you're still on the Free plan."
  end
end
