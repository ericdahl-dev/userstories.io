# frozen_string_literal: true

class StripeWebhookHandler
  def initialize(event)
    @event = event
  end

  def process!
    return if StripeWebhookEvent.exists?(stripe_event_id: @event.id)

    ActiveRecord::Base.transaction do
      StripeWebhookEvent.create!(
        stripe_event_id: @event.id,
        event_type: @event.type,
        processed_at: Time.current
      )

      dispatch!
    end
  end

  private

  def dispatch!
    case @event.type
    when "checkout.session.completed"
      handle_checkout_completed(@event.data.object)
    when "customer.subscription.updated"
      handle_subscription_updated(@event.data.object)
    when "customer.subscription.deleted"
      handle_subscription_deleted(@event.data.object)
    end
  end

  def handle_checkout_completed(session)
    user = user_for_session(session)
    return unless user

    user.activate_pro!(
      stripe_customer_id: session.customer,
      stripe_subscription_id: session.subscription
    )
  end

  def handle_subscription_updated(subscription)
    user = user_for_subscription(subscription)
    return unless user

    if subscription.status.in?(%w[active trialing])
      user.activate_pro!(
        stripe_customer_id: subscription.customer,
        stripe_subscription_id: subscription.id
      )
    else
      user.downgrade_to_free!
    end
  end

  def handle_subscription_deleted(subscription)
    user = user_for_subscription(subscription)
    return unless user

    user.downgrade_to_free!
  end

  def user_for_session(session)
    user_id = session.metadata&.user_id.presence || session.client_reference_id
    User.find_by(id: user_id)
  end

  def user_for_subscription(subscription)
    User.find_by(stripe_subscription_id: subscription.id) ||
      User.find_by(stripe_customer_id: subscription.customer)
  end
end
