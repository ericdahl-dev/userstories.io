require "open3"
require "fileutils"
require "timeout"

class GithubRepoClone
  TTL = 24.hours
  CLONE_TIMEOUT = 120

  class << self
    attr_writer :git_runner

    def git_runner
      @git_runner ||= method(:default_git_clone)
    end

    def base_dir
      Rails.root.join("tmp/github_clones")
    end

    def default_git_clone(url, destination)
      Timeout.timeout(CLONE_TIMEOUT) do
        _stdout, _stderr, status = Open3.capture3(
          "git", "clone", "--depth", "1", url, destination.to_s
        )
        status.success?
      end
    rescue Timeout::Error
      false
    end
  end

  def initialize(project)
    @project = project
    @developer = project.user
  end

  def ensure!
    return false if @project.github_repo.blank? || @developer.github_token.blank?
    return true if fresh_clone?

    clone!
  end

  def clone_path
    fresh_clone? ? clone_dir.to_s : nil
  end

  def invalidate!
    FileUtils.rm_rf(clone_dir) if clone_dir.exist?
    @project.update!(github_clone_status: nil, github_clone_refreshed_at: nil)
  end

  def refresh!
    invalidate!
    clone!
  end

  private

  def fresh_clone?
    clone_dir.exist? &&
      @project.github_clone_status == "succeeded" &&
      @project.github_clone_refreshed_at.present? &&
      @project.github_clone_refreshed_at >= TTL.ago
  end

  def clone!
    @project.update!(github_clone_status: "pending")
    FileUtils.rm_rf(clone_dir)
    FileUtils.mkdir_p(self.class.base_dir)

    success = self.class.git_runner.call(clone_url, clone_dir)
    if success
      @project.update!(github_clone_status: "succeeded", github_clone_refreshed_at: Time.current)
      true
    else
      FileUtils.rm_rf(clone_dir)
      @project.update!(github_clone_status: "failed")
      false
    end
  rescue StandardError
    FileUtils.rm_rf(clone_dir)
    @project.update!(github_clone_status: "failed")
    false
  end

  def clone_url
    token = CGI.escape(@developer.github_token)
    "https://x-access-token:#{token}@github.com/#{@project.github_repo}.git"
  end

  def clone_dir
    @clone_dir ||= self.class.base_dir.join("project_#{@project.id}")
  end
end
