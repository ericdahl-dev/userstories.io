class SubmissionHistoryContext
  MAX_ENTRIES = 20
  MAX_SIMILAR = 5
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

  def to_similar_prompt
    matches = similar_to
    return "(No similar submissions detected on this project.)" if matches.empty?

    matches.map { |match| format_similar_match(match) }.join("\n")
  end

  def similar_to
    matches = similar_to_via_embeddings
    matches = similar_to_via_text if matches.empty?
    matches.first(MAX_SIMILAR)
  end

  def fetch_entries
    similar = similar_entries
    return similar if similar.any?

    recent_entries
  end

  private

  def similar_to_via_embeddings
    ensure_submission_embedding!
    return [] if @submission.embedding.blank?

    SubmissionSimilarityFinder.new(@submission).similar_entries(limit: MAX_SIMILAR).filter_map do |entry|
      other = candidate_submissions.find { |submission| submission.id == entry[:id] }
      next unless other

      build_similar_match(other, score: entry[:similarity_score])
    end
  end

  def similar_to_via_text
    source_title, source_body = comparison_text.values_at(:title, :body)

    candidate_submissions.filter_map do |other|
      score = SubmissionSimilarity.score(source_title, source_body, other.title, other.body)
      next if score < SubmissionSimilarity::RELATED_THRESHOLD

      build_similar_match(other, score: score)
    end.sort_by { |match| -match[:score] }
  end

  def build_similar_match(other, score:)
    rounded_score = score.to_f.round(2)
    {
      id: other.id,
      title: other.title,
      status: other.status,
      github_issue_state: other.github_issue_state,
      created_at: other.created_at,
      submitter_label: other.collaborator.name,
      same_collaborator: other.collaborator_id == @submission.collaborator_id,
      relationship: classify_relationship(other, rounded_score),
      score: rounded_score
    }
  end

  def similar_entries
    ensure_submission_embedding!
    SubmissionSimilarityFinder.new(@submission).similar_entries
  end

  def recent_entries
    candidate_submissions
      .recent
      .limit(MAX_ENTRIES)
      .map { |other| entry_for(other) }
  end

  def candidate_submissions
    @project.submissions
            .where.not(id: @submission.id)
            .where.not(status: "dismissed")
            .includes(:collaborator)
  end

  def comparison_text
    {
      title: @submission.refined_title.presence || @submission.title,
      body: @submission.refined_body.presence || @submission.body
    }
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

  def classify_relationship(other, score)
    if shipped_or_closed?(other)
      "already shipped"
    elsif other.collaborator_id == @submission.collaborator_id
      "repeat submission"
    elsif score >= SubmissionSimilarity::DUPLICATE_THRESHOLD
      "likely duplicate"
    else
      "related ask"
    end
  end

  def shipped_or_closed?(other)
    other.status == "shipped" ||
      (other.status == "accepted" && other.github_issue_state == "closed")
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

  def format_similar_match(match)
    "- \"#{match[:title]}\" by #{match[:submitter_label]} " \
      "(#{match[:status]}, #{match[:created_at].to_date}) — #{match[:relationship]} " \
      "(score: #{match[:score]})"
  end
end
