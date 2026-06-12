require "rails_helper"

RSpec.describe GithubRepoContext do
  let(:user) { create(:user, github_token: "token") }
  let(:project) { create(:project, user: user, github_repo: "owner/repo") }
  let(:fake_client) { instance_double(GithubClient) }
  let(:clone_service) { instance_double(GithubRepoClone, clone_path: nil) }

  subject(:context) { described_class.new(project) }

  before do
    allow(GithubRepoClone).to receive(:new).with(project).and_return(clone_service)
    allow(GithubClient).to receive(:new).with("token").and_return(fake_client)
    allow(fake_client).to receive(:file_content).and_return(nil)
    allow(fake_client).to receive(:directory_paths).and_return([])
  end

  it "includes fetched source files in prompt from the API fallback" do
    allow(fake_client).to receive(:file_content)
      .with(repo: "owner/repo", path: "app/models/submission.rb", max_bytes: 8.kilobytes)
      .and_return("class Submission\nend")

    allow(fake_client).to receive(:directory_paths)
      .with(repo: "owner/repo", path: "app/models")
      .and_return([ "app/models/submission.rb" ])

    prompt = context.to_prompt
    expect(prompt).to include("app/models/submission.rb")
    expect(prompt).to include("class Submission")
  end

  it "prefers the local clone when available" do
    clone_root = Rails.root.join("tmp/test_github_repo_context")
    FileUtils.mkdir_p(clone_root.join("app/models"))
    File.write(clone_root.join("app/models/submission.rb"), "class Submission\nend")

    allow(clone_service).to receive(:clone_path).and_return(clone_root.to_s)

    prompt = context.to_prompt
    expect(prompt).to include("app/models/submission.rb")
    expect(fake_client).not_to have_received(:file_content)
  ensure
    FileUtils.rm_rf(clone_root)
  end

  it "excludes files that match secret patterns" do
    clone_root = Rails.root.join("tmp/test_github_repo_context_secrets")
    FileUtils.mkdir_p(clone_root)
    File.write(clone_root.join("README.md"), "token ghp_abcdefghijklmnopqrstuvwxyz1234567890")

    allow(clone_service).to receive(:clone_path).and_return(clone_root.to_s)

    expect(context.to_prompt).to eq("(No repository source available.)")
  ensure
    FileUtils.rm_rf(clone_root)
  end

  it "ranks clone paths using submission keywords" do
    submission = create(:submission, project: project, title: "Dark mode", body: "Add theme toggle")
    clone_root = Rails.root.join("tmp/test_github_repo_context_ranking")
    FileUtils.mkdir_p(clone_root.join("app/controllers"))
    FileUtils.mkdir_p(clone_root.join("app/models"))
    File.write(clone_root.join("app/controllers/theme_controller.rb"), "class ThemeController\nend")
    File.write(clone_root.join("app/models/user.rb"), "class User\nend")

    allow(clone_service).to receive(:clone_path).and_return(clone_root.to_s)

    ranked_context = described_class.new(project, submission: submission)
    prompt = ranked_context.to_prompt

    expect(prompt.index("theme_controller.rb")).to be < prompt.index("user.rb")
  ensure
    FileUtils.rm_rf(clone_root)
  end

  it "returns placeholder when no files are available" do
    expect(context.to_prompt).to eq("(No repository source available.)")
  end

  it "falls back to the API when clone bundle is empty" do
    clone_root = Rails.root.join("tmp/test_github_repo_context_empty_clone")
    FileUtils.mkdir_p(clone_root)

    allow(clone_service).to receive(:clone_path).and_return(clone_root.to_s)
    allow(fake_client).to receive(:file_content)
      .with(repo: "owner/repo", path: "README.md", max_bytes: 8.kilobytes)
      .and_return("# Project")

    prompt = context.to_prompt
    expect(prompt).to include("README.md")
    expect(prompt).to include("# Project")
  ensure
    FileUtils.rm_rf(clone_root)
  end

  it "returns placeholder when GitHub API errors and clone is unavailable" do
    allow(fake_client).to receive(:directory_paths)
      .and_raise(GithubClient::Error, "rate limit exceeded")

    expect(context.to_prompt).to eq("(No repository source available.)")
  end
end
