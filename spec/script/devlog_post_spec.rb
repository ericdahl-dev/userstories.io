# frozen_string_literal: true

require "fileutils"
require "tmpdir"

require_relative "../../script/devlog/post"
require_relative "../../script/devlog/sync"

RSpec.describe Devlog::Sync do
  describe ".devlog_label?" do
    it "requires the devlog label" do
      expect(described_class.devlog_label?(%w[feature devlog])).to be(true)
      expect(described_class.devlog_label?(%w[bug])).to be(false)
    end
  end
end

RSpec.describe Devlog::Post do
  describe ".infer_type" do
    it "prefers devlog labels" do
      expect(described_class.infer_type(labels: %w[feature], title: "Fix things")).to eq("feature")
    end

    it "infers from title prefixes" do
      expect(described_class.infer_type(labels: [], title: "Fix race on accept")).to eq("fix")
      expect(described_class.infer_type(labels: [], title: "Add capped refinement chat")).to eq("feature")
    end
  end

  describe ".create_from_pull_request" do
    it "writes a post with PR metadata" do
      Dir.mktmpdir do |tmpdir|
        posts_dir = File.join(tmpdir, "_posts")
        stub_const("#{described_class}::POSTS_DIR", posts_dir)

        path = described_class.create_from_pull_request(
          number: 42,
          title: "Add GitHub issue sync",
          merged_at: "2026-06-07T18:30:00Z",
          body: "Sync collaborator status when issues close.",
          labels: %w[feature github],
          html_url: "https://github.com/org/repo/pull/42"
        )

        content = File.read(path)
        expect(content).to include("title: Add GitHub issue sync")
        expect(content).to include("type: feature")
        expect(content).to include("pull_request: 42")
        expect(content).to include("PR #42")
      end
    end
  end
end
