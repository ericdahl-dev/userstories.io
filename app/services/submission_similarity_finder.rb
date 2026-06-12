class SubmissionSimilarityFinder
  TOP_K = 5
  MIN_SIMILARITY_SCORE = 0.5
  BODY_TRUNCATE = SubmissionHistoryContext::BODY_TRUNCATE

  def initialize(submission)
    @submission = submission
    @project = submission.project
  end

  def similar_entries(limit: TOP_K)
    return [] if @submission.embedding.blank?

    scope = @project.submissions
                    .where.not(id: @submission.id)
                    .where.not(status: "dismissed")
                    .where.not(embedding: nil)
                    .includes(:collaborator)

    scope.nearest_neighbors(:embedding, @submission.embedding, distance: "cosine")
         .first(limit)
         .filter_map do |other|
           entry = entry_for(other)
           entry if entry[:similarity_score] >= MIN_SIMILARITY_SCORE
         end
  end

  private

  def entry_for(other)
    {
      id: other.id,
      title: other.title,
      body: truncate_body(other.body),
      status: other.status,
      github_issue_state: other.github_issue_state,
      created_at: other.created_at,
      same_collaborator: other.collaborator_id == @submission.collaborator_id,
      similarity_score: similarity_score_for(other)
    }
  end

  def similarity_score_for(other)
    1.0 - other.neighbor_distance.to_f
  end

  def truncate_body(text)
    return text if text.length <= BODY_TRUNCATE

    "#{text.first(BODY_TRUNCATE)}..."
  end
end
