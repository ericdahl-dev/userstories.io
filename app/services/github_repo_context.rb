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

  SECRET_PATTERNS = [
    /AKIA[0-9A-Z]{16}/,
    /-----BEGIN (?:RSA |EC )?PRIVATE KEY-----/,
    /ghp_[a-zA-Z0-9]{36}/,
    /gho_[a-zA-Z0-9]{36}/,
    /xox[baprs]-[a-zA-Z0-9-]+/,
    /sk_(?:live|test)_[a-zA-Z0-9]+/
  ].freeze

  STOP_WORDS = %w[
    about after again also been before being could every first from have
    into just like make more need only other should some story that their
    them then there these they this those through want what when where which
    while will with would your
  ].freeze

  def initialize(project, submission: nil)
    @project = project
    @developer = project.user
    @submission = submission
  end

  def to_prompt
    bundle = fetch_bundle
    return "(No repository source available.)" if bundle.empty?

    bundle.map { |path, content| "### #{path}\n```\n#{content}\n```" }.join("\n\n")
  end

  def fetch_bundle
    return {} if @project.github_repo.blank? || @developer.github_token.blank?

    bundle = fetch_bundle_from_clone
    return bundle if bundle.present?

    fetch_bundle_from_api
  rescue GithubClient::Error
    {}
  end

  private

  def fetch_bundle_from_clone
    root = GithubRepoClone.new(@project).clone_path
    return {} if root.blank?

    build_bundle_from_filesystem(root)
  end

  def fetch_bundle_from_api
    bundle = {}
    total_bytes = 0

    candidate_paths_from_api.each do |path|
      break if bundle.size >= MAX_FILES
      break if total_bytes >= MAX_TOTAL_BYTES

      content = github_client.file_content(
        repo: @project.github_repo,
        path: path,
        max_bytes: MAX_FILE_BYTES
      )
      next if content.blank?
      next if contains_secret?(content)

      bytes = content.bytesize
      next if bytes > MAX_FILE_BYTES
      next if total_bytes + bytes > MAX_TOTAL_BYTES

      bundle[path] = content
      total_bytes += bytes
    end

    bundle
  end

  def build_bundle_from_filesystem(root)
    bundle = {}
    total_bytes = 0

    ranked_paths(root).each do |path|
      break if bundle.size >= MAX_FILES
      break if total_bytes >= MAX_TOTAL_BYTES

      full_path = File.join(root, path)
      next unless File.file?(full_path)

      content = read_file(full_path)
      next if content.blank?
      next if contains_secret?(content)

      bytes = content.bytesize
      next if bytes > MAX_FILE_BYTES
      next if total_bytes + bytes > MAX_TOTAL_BYTES

      bundle[path] = content
      total_bytes += bytes
    end

    bundle
  end

  def ranked_paths(root)
    paths = candidate_paths_from_filesystem(root)
    keywords = relevance_keywords
    return paths if keywords.empty?

    paths.sort_by do |path|
      score = keywords.count { |keyword| path.downcase.include?(keyword) }
      [ -score, path ]
    end
  end

  def candidate_paths_from_api
    paths = DOC_PATHS.dup

    SOURCE_DIRS.each do |dir|
      github_client.directory_paths(repo: @project.github_repo, path: dir).each do |file_path|
        paths << file_path unless paths.include?(file_path)
      end
    end

    paths
  end

  def candidate_paths_from_filesystem(root)
    paths = []

    DOC_PATHS.each do |path|
      paths << path if File.exist?(File.join(root, path))
    end

    SOURCE_DIRS.each do |dir|
      dir_path = File.join(root, dir)
      next unless File.directory?(dir_path)

      Dir.glob(File.join(dir_path, "**", "*")).each do |full_path|
        next unless File.file?(full_path)

        relative_path = Pathname.new(full_path).relative_path_from(root).to_s
        next if skip_path?(relative_path, File.size(full_path))
        next if paths.include?(relative_path)

        paths << relative_path
      end
    end

    paths
  end

  def relevance_keywords
    return [] unless @submission

    text = [
      @submission.title,
      @submission.body,
      @submission.refined_title,
      @submission.refined_body
    ].compact.join(" ")

    text.downcase.scan(/\b[a-z]{4,}\b/).uniq - STOP_WORDS
  end

  def read_file(path)
    File.read(path, mode: "rb").encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
  rescue Errno::ENOENT, Errno::EACCES
    nil
  end

  def contains_secret?(content)
    SECRET_PATTERNS.any? { |pattern| content.match?(pattern) }
  end

  def skip_path?(path, size)
    return true if size > MAX_FILE_BYTES
    return true if path.start_with?("spec/", "vendor/", "node_modules/", ".git/")
    return true if path.match?(/\.(png|jpg|jpeg|gif|ico|pdf|woff2?|ttf|eot|zip|gz)$/i)

    false
  end

  def github_client
    @github_client ||= GithubClient.new(@developer.github_token)
  end
end
