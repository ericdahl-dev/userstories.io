class RefineSubmissionJob < ApplicationJob
  queue_as :default

  def perform(submission)
    return if submission.refinement_locked?
    return unless submission.refinement_initial_due? || awaiting_initial_reply?(submission)
    return mark_failed!(submission) unless LlmClient.configured?

    ensure_repo_clone!(submission.project)
    ensure_submission_embedding!(submission)

    submission.update!(refinement_status: "processing")
    SubmissionRefiner.new(submission).refine!
    submission.update!(refinement_status: "completed")

    message = submission.refinement_messages.where(role: "assistant").order(created_at: :desc).first
    broadcast_assistant_reply!(submission, message) if message
  rescue LlmClient::Error, SubmissionRefiner::Error => e
    mark_failed!(submission, e.message)
  end

  private

  def ensure_repo_clone!(project)
    GithubRepoClone.new(project).ensure!
  rescue StandardError => e
    Rails.logger.warn("[RefineSubmissionJob] GitHub clone failed: #{e.class}: #{e.message}")
  end

  def ensure_submission_embedding!(submission)
    return unless EmbeddingClient.configured?

    SubmissionEmbeddingGenerator.generate!(submission)
  rescue EmbeddingClient::Error => e
    Rails.logger.warn("[RefineSubmissionJob] Embedding failed: #{e.class}: #{e.message}")
  end

  def awaiting_initial_reply?(submission)
    submission.refinement_status == "processing" &&
      submission.refinement_messages.where(role: "assistant").none?
  end

  def mark_failed!(submission, _message = nil)
    submission.update!(refinement_status: "failed")
    broadcast_processing_failed!(submission)
  end

  def broadcast_assistant_reply!(submission, message)
    RefinementChatBroadcaster.new(submission).complete_assistant_reply!(message)
  rescue StandardError => e
    Rails.logger.warn("[RefineSubmissionJob] Turbo broadcast failed: #{e.class}: #{e.message}")
  end

  def broadcast_processing_failed!(submission)
    RefinementChatBroadcaster.new(submission).processing_failed!
  rescue StandardError => e
    Rails.logger.warn("[RefineSubmissionJob] Turbo broadcast failed: #{e.class}: #{e.message}")
  end
end
