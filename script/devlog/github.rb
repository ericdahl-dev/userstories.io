# frozen_string_literal: true

require "json"
require "net/http"
require "open3"
require "time"
require "uri"

module Devlog
  module GitHub
    module_function

    def repository
      return ENV["GITHUB_REPOSITORY"] if ENV["GITHUB_REPOSITORY"]&.include?("/")

      remote = `git -C #{Devlog::Post::ROOT} remote get-url origin 2>/dev/null`.strip
      raise "Set GITHUB_REPOSITORY or run from a git repo with origin" if remote.empty?

      remote
        .sub(%r{\A(?:git@github\.com:|https://github\.com/)}, "")
        .sub(/\.git\z/, "")
    end

    def token
      return ENV["GITHUB_TOKEN"] if ENV["GITHUB_TOKEN"]&.strip&.then { |t| !t.empty? }

      stdout, _status = Open3.capture2("gh", "auth", "token")
      token = stdout.strip
      raise "Set GITHUB_TOKEN or run `gh auth login`" if token.empty?

      token
    end

    def get(path, params = {})
      uri = URI("https://api.github.com#{path}")
      uri.query = URI.encode_www_form(params) if params.any?

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
        request = Net::HTTP::Get.new(uri)
        request["Accept"] = "application/vnd.github+json"
        request["Authorization"] = "Bearer #{token}"
        request["X-GitHub-Api-Version"] = "2022-11-28"
        http.request(request)
      end

      raise "GitHub API #{response.code} for #{path}: #{response.body}" unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body)
    end

    def labels_for(owner:, repo:, number:)
      get("/repos/#{owner}/#{repo}/issues/#{number}/labels").map { |label| label["name"] }
    end

    def merged_pull_requests(since: nil, limit: 100)
      owner, repo = repository.split("/", 2)
      pulls = get("/repos/#{owner}/#{repo}/pulls", state: "closed", per_page: limit, sort: "updated", direction: "desc")

      pulls.filter_map do |pr|
        next unless pr["merged_at"]

        merged_at = Time.parse(pr["merged_at"])
        next if since && merged_at <= since

        labels = labels_for(owner: owner, repo: repo, number: pr["number"])
        next unless Devlog::Sync.devlog_label?(labels)

        {
          number: pr["number"],
          title: pr["title"],
          body: pr["body"].to_s,
          merged_at: pr["merged_at"],
          html_url: pr["html_url"],
          labels: labels
        }
      end
    end

    def merged_pull_request(number:)
      owner, repo = repository.split("/", 2)
      pr = get("/repos/#{owner}/#{repo}/pulls/#{number}")
      raise "PR ##{number} is not merged" unless pr["merged_at"]

      labels = labels_for(owner: owner, repo: repo, number: number)
      {
        number: pr["number"],
        title: pr["title"],
        body: pr["body"].to_s,
        merged_at: pr["merged_at"],
        html_url: pr["html_url"],
        labels: labels
      }
    end
  end
end
