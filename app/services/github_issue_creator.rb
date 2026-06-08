class GithubIssueCreator
  Error = Class.new(StandardError)

  def initialize(submission)
    @submission = submission
    @project    = submission.project
    @developer  = @project.user
  end

  def create!
    client = Octokit::Client.new(access_token: @developer.github_token)
    issue  = client.create_issue(
      @project.github_repo,
      @submission.title,
      issue_body
    )
    { number: issue.number, url: issue.html_url }
  rescue Octokit::Error => e
    raise Error, e.message
  end

  private

  def issue_body
    <<~BODY
      #{@submission.body}

      ---
      _Submitted via [userstories.io](https://userstories.io) by #{@submission.collaborator.name}_
    BODY
  end
end
