class RefinementTurnJob < ApplicationJob
  queue_as :default

  def perform(submission)
    return if submission.refinement_locked?
    return unless submission.refinement_turn_due?
    return unless RefinementQuotaGuard.allowed?(submission)
    return mark_failed!(submission) unless LlmClient.configured?

    ensure_repo_clone!(submission.project)

    submission.update!(refinement_status: "processing")
    SubmissionRefinementTurn.new(submission).run!
    submission.update!(refinement_status: "completed")

    message = submission.refinement_messages.where(role: "assistant").order(created_at: :desc).first
    broadcast_assistant_reply!(submission, message) if message
  rescue LlmClient::Error, SubmissionRefinementTurn::Error => e
    mark_failed!(submission, e.message)
  end

  private

  def ensure_repo_clone!(project)
    GithubRepoClone.new(project).ensure!
  rescue StandardError => e
    Rails.logger.warn("[RefinementTurnJob] GitHub clone failed: #{e.class}: #{e.message}")
  end

  def mark_failed!(submission, _message = nil)
    submission.update!(refinement_status: "failed")
    broadcast_processing_failed!(submission)
  end

  def broadcast_assistant_reply!(submission, message)
    RefinementChatBroadcaster.new(submission).complete_assistant_reply!(message)
  rescue StandardError => e
    Rails.logger.warn("[RefinementTurnJob] Turbo broadcast failed: #{e.class}: #{e.message}")
  end

  def broadcast_processing_failed!(submission)
    RefinementChatBroadcaster.new(submission).processing_failed!
  rescue StandardError => e
    Rails.logger.warn("[RefinementTurnJob] Turbo broadcast failed: #{e.class}: #{e.message}")
  end
end
