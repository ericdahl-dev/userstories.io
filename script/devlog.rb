#!/usr/bin/env ruby
# frozen_string_literal: true

require "optparse"
require "time"

require_relative "devlog/post"
require_relative "devlog/updater"

def run_new(argv)
  options = {
    type: "note",
    date: Time.now.utc.strftime("%Y-%m-%d"),
    tag: "devlog",
    summary: nil,
    open: false
  }

  parser = OptionParser.new do |opts|
    opts.banner = "Usage: script/devlog.rb new \"Entry title\" [options]"

    opts.on("-t", "--type TYPE", Devlog::Post::TYPES, "Entry type (#{Devlog::Post::TYPES.join(', ')})") do |value|
      options[:type] = value
    end

    opts.on("-d", "--date DATE", "Entry date (YYYY-MM-DD)") do |value|
      options[:date] = value
    end

    opts.on("-s", "--summary TEXT", "One-line summary for indexes") do |value|
      options[:summary] = value
    end

    opts.on("--tag TAG", "Primary tag (default: devlog)") do |value|
      options[:tag] = value
    end

    opts.on("-e", "--edit", "Open the new file in $EDITOR") do
      options[:open] = true
    end
  end

  parser.parse!(argv)

  title = argv.join(" ").strip
  if title.empty?
    warn parser
    exit 1
  end

  path = Devlog::Post.create_manual(
    title: title,
    type: options[:type],
    date: options[:date],
    summary: options[:summary],
    tag: options[:tag]
  )

  puts "Created #{path}"
  puts
  puts "Preview: cd pages && bundle exec jekyll serve"
  puts "Publish: commit pages/ and push to main"

  if options[:open]
    editor = ENV["EDITOR"] || "vim"
    system(editor, path) || warn("Could not open #{path} with #{editor}")
  end
end

def run_update(argv)
  options = { all: false, pull_request: nil, force: false, dry_run: false }

  parser = OptionParser.new do |opts|
    opts.banner = "Usage: script/devlog.rb update [options]"

    opts.on("--all", "Ignore last run time; sync any unsynced labeled PRs") do
      options[:all] = true
    end

    opts.on("--pr NUMBER", Integer, "Sync one merged PR by number") do |value|
      options[:pull_request] = value
    end

    opts.on("--force", "Sync the PR even without the devlog label") do
      options[:force] = true
    end

    opts.on("-n", "--dry-run", "Show what would sync without writing") do
      options[:dry_run] = true
    end
  end

  parser.parse!(argv)

  created = Devlog::Updater.update!(**options)

  if created.empty?
    puts "No new dev log entries."
  else
    action = options[:dry_run] ? "Would sync" : "Synced"
    puts "#{action} #{created.size} entr#{created.size == 1 ? 'y' : 'ies'}."
  end
end

def print_help
  puts <<~HELP
    Usage: script/devlog.rb COMMAND

    Commands:
      update   Pull in merged PRs labeled devlog since the last run
      new      Create a manual dev log entry
      status   Show last update time and synced PR count

    Examples:
      script/devlog.rb update
      script/devlog.rb update --dry-run
      script/devlog.rb update --pr 93 --force
      script/devlog.rb new "Quarterly recap" --type milestone -e

    Auth: GITHUB_TOKEN env var, or `gh auth login`
    Publish: commit pages/ and push to main (GitHub Pages deploys via Actions)
  HELP
end

command = ARGV.shift

case command
when "update", "sync"
  run_update(ARGV)
when "new", "create"
  run_new(ARGV)
when "status"
  Devlog::Updater.status
when "-h", "--help", "help", nil
  print_help
  exit(command.nil? ? 1 : 0)
else
  warn "Unknown command: #{command}"
  print_help
  exit 1
end
