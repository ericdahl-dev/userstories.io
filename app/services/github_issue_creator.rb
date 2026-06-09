class GithubIssueCreator
  Error = Class.new(StandardError)

  def initialize(submission)
    @submission = submission
    @project    = submission.project
    @developer  = @project.user
  end

  def create!
    result = github_client.create_issue(
      repo:  @project.github_repo,
      title: @submission.title,
      body:  issue_body
    )
    result
  rescue GithubClient::Error => e
    raise Error, e.message
  end

  private

  def github_client
    GithubClient.new(@developer.github_token)
  end

  def issue_body
    <<~BODY
      #{@submission.body}

      ---
      _Submitted via [userstories.io](https://userstories.io)_
    BODY
  end
end
