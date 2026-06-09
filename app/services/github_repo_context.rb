class GithubRepoContext
  MAX_FILES = 25
  MAX_FILE_BYTES = 8.kilobytes
  MAX_TOTAL_BYTES = 48.kilobytes

  DOC_PATHS = %w[
    README.md
    README
    CONTEXT.md
    AGENTS.md
    docs/data-model.md
    config/routes.rb
    Gemfile
    db/schema.rb
  ].freeze

  SOURCE_DIRS = %w[
    app/models
    app/services
    app/controllers
    app/policies
    app/jobs
    lib
  ].freeze

  def initialize(project)
    @project = project
    @developer = project.user
  end

  def to_prompt
    bundle = fetch_bundle
    return "(No repository source available.)" if bundle.empty?

    bundle.map { |path, content| "### #{path}\n```\n#{content}\n```" }.join("\n\n")
  end

  def fetch_bundle
    return {} if @project.github_repo.blank? || @developer.github_token.blank?

    bundle = {}
    total_bytes = 0

    candidate_paths.each do |path|
      break if bundle.size >= MAX_FILES
      break if total_bytes >= MAX_TOTAL_BYTES

      content = github_client.file_content(
        repo: @project.github_repo,
        path: path,
        max_bytes: MAX_FILE_BYTES
      )
      next if content.blank?

      bytes = content.bytesize
      next if bytes > MAX_FILE_BYTES
      next if total_bytes + bytes > MAX_TOTAL_BYTES

      bundle[path] = content
      total_bytes += bytes
    end

    bundle
  end

  private

  def candidate_paths
    paths = DOC_PATHS.dup

    SOURCE_DIRS.each do |dir|
      github_client.directory_paths(repo: @project.github_repo, path: dir).each do |file_path|
        paths << file_path unless paths.include?(file_path)
      end
    end

    paths
  end

  def github_client
    @github_client ||= GithubClient.new(@developer.github_token)
  end
end
