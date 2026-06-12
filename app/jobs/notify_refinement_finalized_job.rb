class NotifyRefinementFinalizedJob < ApplicationJob
  queue_as :default

  def perform(submission)
    return unless submission.refinement_locked?

    DeveloperMailer.refinement_finalized(submission).deliver_now
  end
end
