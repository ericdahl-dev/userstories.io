# frozen_string_literal: true

require "json"
require "time"

require_relative "github"
require_relative "post"
require_relative "sync"

module Devlog
  module Updater
    MANIFEST_PATH = File.join(Post::ROOT, "pages", ".devlog-sync.json")

    module_function

    def load_manifest
      return default_manifest unless File.exist?(MANIFEST_PATH)

      default_manifest.merge(JSON.parse(File.read(MANIFEST_PATH)))
    end

    def default_manifest
      {
        "synced_pull_requests" => [],
        "last_synced_at" => nil
      }
    end

    def save_manifest!(manifest)
      File.write(MANIFEST_PATH, "#{JSON.pretty_generate(manifest)}\n")
    end

    def last_synced_at(manifest)
      value = manifest["last_synced_at"]
      return nil if value.nil? || value.to_s.strip.empty?

      Time.parse(value)
    end

    def fetch_pulls(pull_request:, since:)
      if pull_request
        [ GitHub.merged_pull_request(number: pull_request) ]
      else
        GitHub.merged_pull_requests(since: since)
      end
    end

    def update!(all: false, pull_request: nil, force: false, dry_run: false)
      manifest = load_manifest
      synced = manifest.fetch("synced_pull_requests", [])
      since = all ? nil : last_synced_at(manifest)
      created = []

      pulls = fetch_pulls(pull_request: pull_request, since: since)

      pulls.each do |pr|
        next if synced.include?(pr[:number])
        unless force || Sync.devlog_label?(pr[:labels])
          puts "Skipping PR ##{pr[:number]} (add the #{Sync::REQUIRED_LABEL} label to publish)"
          next
        end

        if dry_run
          puts "Would create entry from PR ##{pr[:number]}: #{pr[:title]}"
          created << { number: pr[:number], path: nil }
          next
        end

        path = Post.create_from_pull_request(**pr)
        synced << pr[:number]
        created << { number: pr[:number], path: path }
        puts "Created #{path} from PR ##{pr[:number]}"
      end

      unless dry_run
        manifest["synced_pull_requests"] = synced.sort
        manifest["last_synced_at"] = Time.now.utc.iso8601
        save_manifest!(manifest)
      end

      created
    end

    def status
      manifest = load_manifest
      last = manifest["last_synced_at"]
      count = manifest.fetch("synced_pull_requests", []).size

      if last
        puts "Last updated: #{last}"
      else
        puts "Last updated: never"
      end

      puts "Synced PRs: #{count}"
    end
  end
end
