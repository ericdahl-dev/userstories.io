class RefinementTurnJob < ApplicationJob
  queue_as :default

  def perform(submission)
    return if submission.refinement_locked?
    return unless submission.refinement_turn_due?
    return unless RefinementQuotaGuard.allowed?(submission)
    return mark_failed!(submission) unless LlmClient.configured?

    submission.update!(refinement_status: "processing")
    SubmissionRefinementTurn.new(submission).run!
    submission.update!(refinement_status: "completed")

    message = submission.refinement_messages.where(role: "assistant").order(created_at: :desc).first
    RefinementChatBroadcaster.new(submission).complete_assistant_reply!(message) if message
  rescue LlmClient::Error, SubmissionRefinementTurn::Error => e
    mark_failed!(submission, e.message)
  end

  private

  def mark_failed!(submission, _message = nil)
    submission.update!(refinement_status: "failed")
    RefinementChatBroadcaster.new(submission).processing_failed!
  end
end
