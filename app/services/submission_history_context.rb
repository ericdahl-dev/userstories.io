class SubmissionHistoryContext
  MAX_ENTRIES = 20
  BODY_TRUNCATE = 500

  def initialize(submission)
    @submission = submission
    @project = submission.project
  end

  def to_prompt
    entries = fetch_entries
    return "(No prior submissions on this project.)" if entries.empty?

    entries.map { |entry| format_entry(entry) }.join("\n\n")
  end

  def fetch_entries
    similar = similar_entries
    return similar if similar.any?

    recent_entries
  end

  private

  def similar_entries
    ensure_submission_embedding!
    SubmissionSimilarityFinder.new(@submission).similar_entries
  end

  def recent_entries
    @project.submissions
            .where.not(id: @submission.id)
            .where.not(status: "dismissed")
            .recent
            .limit(MAX_ENTRIES)
            .includes(:collaborator)
            .map { |other| entry_for(other) }
  end

  def entry_for(other)
    {
      id: other.id,
      title: other.title,
      body: truncate_body(other.body),
      status: other.status,
      github_issue_state: other.github_issue_state,
      created_at: other.created_at,
      same_collaborator: other.collaborator_id == @submission.collaborator_id
    }
  end

  def ensure_submission_embedding!
    return unless EmbeddingClient.configured?
    return if @submission.embedding.present?

    SubmissionEmbeddingGenerator.generate!(@submission)
  rescue EmbeddingClient::Error
    nil
  end

  def truncate_body(text)
    return text if text.length <= BODY_TRUNCATE

    "#{text.first(BODY_TRUNCATE)}..."
  end

  def format_entry(entry)
    lines = [
      "- id: #{entry[:id]}",
      "  title: #{entry[:title]}",
      "  status: #{entry[:status]}",
      "  github_issue_state: #{entry[:github_issue_state].presence || 'n/a'}",
      "  created_at: #{entry[:created_at].iso8601}",
      "  same_collaborator: #{entry[:same_collaborator]}"
    ]
    lines << "  similarity_score: #{format('%.3f', entry[:similarity_score])}" if entry[:similarity_score]
    lines << "  body: #{entry[:body]}"
    lines.join("\n")
  end
end
