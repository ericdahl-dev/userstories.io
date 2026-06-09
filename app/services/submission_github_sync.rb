class SubmissionGithubSync
  UNAVAILABLE_SUMMARY = "GitHub status unavailable".freeze

  def initialize(submission)
    @submission = submission
    @project = submission.project
    @developer = @project.user
  end

  def sync!
    return false unless @submission.github_status_trackable?
    return mark_unavailable! if @developer.github_token.blank?

    issue = github_client.get_issue(repo: @project.github_repo, number: @submission.github_issue_number)

    @submission.with_lock do
      @submission.update!(
        github_issue_state: normalized_state(issue.state),
        github_issue_summary: build_summary(issue),
        github_issue_synced_at: Time.current
      )

      @submission.ship! if normalized_state(issue.state) == "closed" && @submission.shippable?
    end

    true
  rescue GithubClient::Error
    mark_unavailable!
  end

  private

  def github_client
    @github_client ||= GithubClient.new(@developer.github_token)
  end

  def mark_unavailable!
    @submission.update!(
      github_issue_state: nil,
      github_issue_summary: UNAVAILABLE_SUMMARY,
      github_issue_synced_at: Time.current
    )
    false
  end

  def build_summary(issue)
    parts = [ normalized_state(issue.state).capitalize ]
    labels = issue_labels(issue)
    parts << labels.join(", ") if labels.any?
    parts << "updated #{time_ago_in_words(issue_updated_at(issue))} ago"
    parts.join(" · ")
  end

  def issue_labels(issue)
    Array(issue.labels).filter_map do |label|
      label.respond_to?(:name) ? label.name : label[:name] || label["name"]
    end
  end

  def issue_updated_at(issue)
    updated_at = issue.updated_at
    updated_at.is_a?(String) ? Time.zone.parse(updated_at) : updated_at
  end

  def normalized_state(state)
    state.to_s.downcase
  end

  def time_ago_in_words(time)
    ActionController::Base.helpers.time_ago_in_words(time)
  end
end
