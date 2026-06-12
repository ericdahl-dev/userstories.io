class CloneGithubRepoJob < ApplicationJob
  queue_as :default

  def perform(project)
    GithubRepoClone.new(project).ensure!
  rescue StandardError => e
    Rails.logger.warn("[CloneGithubRepoJob] clone failed for project #{project.id}: #{e.class}: #{e.message}")
  end
end
