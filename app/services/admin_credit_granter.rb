# frozen_string_literal: true

class AdminCreditGranter
  Error = Class.new(StandardError)

  def initialize(recipient:, granted_by:)
    @recipient = recipient
    @granted_by = granted_by
  end

  def grant!(amount:, reason: nil)
    parsed_amount = Integer(amount)
    raise Error, "Amount must be at least 1" if parsed_amount < 1

    ActiveRecord::Base.transaction do
      @recipient.increment!(:refinement_credit_balance, parsed_amount)
      AdminCreditGrant.create!(
        user: @recipient,
        granted_by: @granted_by,
        amount: parsed_amount,
        reason: reason.presence
      )
    end
  end
end
