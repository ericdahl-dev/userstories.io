class GithubClient
  Error = Class.new(StandardError)

  def initialize(token)
    @client = Octokit::Client.new(access_token: token)
  end

  def create_issue(repo:, title:, body:)
    issue = @client.create_issue(repo, title, body)
    { number: issue.number, url: issue.html_url }
  rescue Octokit::Error => e
    raise Error, e.message
  end

  def repos
    @client.repos(nil, sort: "pushed", per_page: 100).map(&:full_name).sort
  rescue Octokit::Error => e
    raise Error, e.message
  end
end
