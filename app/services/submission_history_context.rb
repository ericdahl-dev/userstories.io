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
    source_title, source_body = comparison_text.values_at(:title, :body)

    candidate_submissions.filter_map do |other|
      score = SubmissionSimilarity.score(source_title, source_body, other.title, other.body)
      next if score < SubmissionSimilarity::RELATED_THRESHOLD

      {
        id: other.id,
        title: other.title,
        status: other.status,
        github_issue_state: other.github_issue_state,
        created_at: other.created_at,
        submitter_label: other.collaborator.name,
        same_collaborator: other.collaborator_id == @submission.collaborator_id,
        relationship: classify_relationship(other, score),
        score: score.round(2)
      }
    end.sort_by { |match| -match[:score] }.first(MAX_SIMILAR)
  end

  def fetch_entries
    candidate_submissions
      .recent
      .limit(MAX_ENTRIES)
      .map { |other| build_entry(other) }
  end

  private

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

  def build_entry(other)
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
      "  same_collaborator: #{entry[:same_collaborator]}",
      "  body: #{entry[:body]}"
    ]
    lines.join("\n")
  end

  def format_similar_match(match)
    "- \"#{match[:title]}\" by #{match[:submitter_label]} " \
      "(#{match[:status]}, #{match[:created_at].to_date}) — #{match[:relationship]} " \
      "(score: #{match[:score]})"
  end
end
