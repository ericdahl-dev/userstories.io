# frozen_string_literal: true

class RefinementQuotaGuard
  def self.allowed?(submission)
    developer = submission.project.user
    developer.reset_refinement_usage_if_needed!

    return true if submission.refinement_messages.where(role: "assistant").exists?

    developer.refinement_quota_remaining.positive?
  end

  def self.consume_session!(submission)
    return unless submission.refinement_messages.where(role: "assistant").count == 1

    submission.project.user.consume_refinement_session!
  end

  def self.blocked?(submission)
    !allowed?(submission)
  end
end
