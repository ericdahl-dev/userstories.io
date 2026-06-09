# frozen_string_literal: true

require "fileutils"

RSpec.describe "script/devlog.rb new" do
  let(:script) { File.expand_path("../../script/devlog.rb", __dir__) }
  let(:posts_dir) { File.expand_path("../../pages/_posts", __dir__) }

  it "creates a post file with front matter" do
    title = "Spec generated entry #{Process.pid}"
    pattern = File.join(posts_dir, "*-spec-generated-entry-*.md")

    begin
      expect(system("ruby", script, "new", title, "--type", "note", "--summary", "spec test")).to be(true)

      created = Dir.glob(pattern).max_by { |f| File.mtime(f) }
      expect(created).not_to be_nil

      content = File.read(created)
      expect(content).to include("title: #{title}")
      expect(content).to include("type: note")
      expect(content).to include("summary: spec test")
    ensure
      Dir.glob(pattern).each { |f| File.delete(f) }
    end
  end
end
