# frozen_string_literal: true

require "fileutils"
require "json"
require "tmpdir"

require_relative "../../script/devlog/updater"

RSpec.describe Devlog::Updater do
  describe ".last_synced_at" do
    it "returns nil when never synced" do
      expect(described_class.last_synced_at({ "last_synced_at" => nil })).to be_nil
    end

    it "parses the stored timestamp" do
      time = described_class.last_synced_at({ "last_synced_at" => "2026-06-01T12:00:00Z" })
      expect(time).to be_a(Time)
    end
  end

  describe ".update!" do
    it "records last_synced_at even when nothing is new" do
      Dir.mktmpdir do |tmpdir|
        manifest_path = File.join(tmpdir, ".devlog-sync.json")
        stub_const("#{described_class}::MANIFEST_PATH", manifest_path)

        allow(Devlog::GitHub).to receive(:merged_pull_requests).and_return([])

        expect(described_class.update!).to eq([])
        manifest = JSON.parse(File.read(manifest_path))
        expect(manifest["last_synced_at"]).not_to be_nil
      end
    end
  end
end
