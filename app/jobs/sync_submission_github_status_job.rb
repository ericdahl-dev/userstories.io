class SyncSubmissionGithubStatusJob < ApplicationJob
  queue_as :default

  def perform(submission)
    SubmissionGithubSync.new(submission).sync!
  end
end
