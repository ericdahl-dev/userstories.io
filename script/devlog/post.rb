# frozen_string_literal: true

require "fileutils"
require "time"
require "yaml"

module Devlog
  module Post
    ROOT = File.expand_path("../..", __dir__)
    POSTS_DIR = File.join(ROOT, "pages", "_posts")
    TYPES = %w[feature fix milestone note].freeze

    TEMPLATE = <<~MARKDOWN
      ---
      title: %{title}
      date: %{date}
      type: %{type}
      summary: %{summary}
      tags:
      %{tags_yaml}
      %{extra_front_matter}---

      %{body}
    MARKDOWN

    module_function

    def slugify(text)
      text.downcase
        .gsub(/['']/, "")
        .gsub(/[^a-z0-9]+/, "-")
        .gsub(/\A-+|-+\z/, "")
    end

    def infer_type(labels:, title:)
      label_types = labels.map { |l| l.to_s.downcase } & TYPES
      return label_types.first if label_types.any?

      case title
      when /\A(?:fix|bug|hotfix|patch)\b/i then "fix"
      when /\A(?:feat|feature|add|ship|launch)\b/i then "feature"
      when /\A(?:milestone|release|v\d)/i then "milestone"
      else "note"
      end
    end

    def summary_from_body(body, fallback:)
      text = body.to_s.strip
      return fallback if text.empty?

      paragraph = text.lines.reject { |line| line.strip.start_with?("#") }.join.strip
      paragraph = paragraph.gsub(/\s+/, " ")
      paragraph.length > 180 ? "#{paragraph[0, 177]}..." : paragraph
    end

    def format_tags(tags)
      tags = Array(tags).map(&:to_s).reject(&:empty?)
      tags = ["devlog"] if tags.empty?
      tags.map { |tag| "  - #{tag}" }.join("\n")
    end

    def filename_for(date:, title:, suffix: nil)
      slug = slugify(title)
      slug = "#{slug}-#{suffix}" if suffix
      "#{date}-#{slug}.md"
    end

    def write(path:, title:, date:, type:, summary:, body:, tags: [], extra_front_matter: {})
      FileUtils.mkdir_p(File.dirname(path))
      extra = extra_front_matter.filter_map do |key, value|
        next if value.nil? || value.to_s.empty?

        "  #{key}: #{value}"
      end
      extra << "" unless extra.empty?

      content = format(
        TEMPLATE,
        title: title,
        date: date,
        type: type,
        summary: summary,
        tags_yaml: format_tags(tags),
        extra_front_matter: extra.empty? ? "" : "#{extra.join("\n")}\n",
        body: body
      )

      File.write(path, content)
      path
    end

    def create_manual(title:, type: "note", date: Time.now.utc.strftime("%Y-%m-%d"), summary: nil, tag: "devlog", body: nil)
      summary ||= "TODO: one-line summary"
      path = File.join(POSTS_DIR, filename_for(date: date, title: title))
      raise "Entry already exists: #{path}" if File.exist?(path)

      write(
        path: path,
        title: title,
        date: date,
        type: type,
        summary: summary,
        tags: [tag],
        body: body || "Write the story behind **#{title}**.\n\n## What changed\n\n-\n\n## Why it matters\n\n-\n\n## Next up\n\n-"
      )
    end

    def create_from_pull_request(number:, title:, merged_at:, body:, labels:, html_url:)
      date = Time.parse(merged_at).utc.strftime("%Y-%m-%d")
      type = infer_type(labels: labels, title: title)
      summary = summary_from_body(body, fallback: title)
      tags = (labels.map { |l| l.to_s.downcase } - TYPES).uniq
      tags << "pull-request" unless tags.include?("pull-request")

      base = filename_for(date: date, title: title)
      path = File.join(POSTS_DIR, base)
      path = File.join(POSTS_DIR, filename_for(date: date, title: title, suffix: "pr-#{number}")) if File.exist?(path)

      body_text = body.to_s.strip
      body_text = "_No PR description provided._" if body_text.empty?
      body_text = "#{body_text}\n\n---\n\nMerged in [PR ##{number}](#{html_url})."

      write(
        path: path,
        title: title,
        date: date,
        type: type,
        summary: summary,
        tags: tags,
        extra_front_matter: { "pull_request" => number },
        body: body_text
      )
    end
  end
end
