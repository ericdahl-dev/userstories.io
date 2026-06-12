class GenerateSubmissionEmbeddingJob < ApplicationJob
  queue_as :default

  def perform(submission)
    return unless EmbeddingClient.configured?

    SubmissionEmbeddingGenerator.generate!(submission)
  rescue EmbeddingClient::Error => e
    Rails.logger.warn("[GenerateSubmissionEmbeddingJob] #{e.class}: #{e.message}")
  end
end
