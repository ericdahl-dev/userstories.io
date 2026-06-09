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

  def get_issue(repo:, number:)
    @client.issue(repo, number)
  rescue Octokit::Error => e
    raise Error, e.message
  end

  def repos
    @client.repos(nil, sort: "pushed", per_page: 100).map(&:full_name).sort
  rescue Octokit::Error => e
    raise Error, e.message
  end

  def file_content(repo:, path:, max_bytes: 8.kilobytes)
    entry = @client.contents(repo, path: path)
    return nil if entry.is_a?(Array)
    return nil unless entry.type == "file"
    return nil if entry.size.to_i > max_bytes

    decode_file_content(entry.content.to_s)
  rescue Octokit::NotFound
    nil
  rescue Octokit::Error => e
    raise Error, e.message
  end

  def directory_paths(repo:, path:)
    entries = @client.contents(repo, path: path)
    return [] unless entries.is_a?(Array)

    entries.filter_map do |entry|
      next unless entry.type == "file"
      next if skip_path?(entry.path, entry.size.to_i)

      entry.path
    end
  rescue Octokit::NotFound
    []
  rescue Octokit::Error => e
    raise Error, e.message
  end

  private

  def decode_file_content(encoded)
    Base64.decode64(encoded).encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
  end

  def skip_path?(path, size)
    return true if size > 8.kilobytes
    return true if path.start_with?("spec/", "vendor/", "node_modules/")
    return true if path.match?(/\.(png|jpg|jpeg|gif|ico|pdf|woff2?|ttf|eot|zip|gz)$/i)

    false
  end
end
