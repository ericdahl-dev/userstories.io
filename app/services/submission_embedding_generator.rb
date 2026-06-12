class SubmissionEmbeddingGenerator
  def initialize(submission, embedding_client: EmbeddingClient.new)
    @submission = submission
    @embedding_client = embedding_client
  end

  def generate!
    return if @submission.embedding.present?

    @submission.update!(embedding: @embedding_client.embed(text: @submission.embeddable_text))
  end

  def self.generate!(submission, **)
    new(submission, **).generate!
  end
end
