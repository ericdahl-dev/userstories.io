require "rails_helper"

RSpec.describe GithubRepoContext do
  let(:user) { create(:user, github_token: "token") }
  let(:project) { create(:project, user: user, github_repo: "owner/repo") }
  let(:fake_client) { instance_double(GithubClient) }

  subject(:context) { described_class.new(project) }

  before do
    allow(GithubClient).to receive(:new).with("token").and_return(fake_client)
    allow(fake_client).to receive(:file_content).and_return(nil)
    allow(fake_client).to receive(:directory_paths).and_return([])
  end

  it "includes fetched source files in prompt" do
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

  it "returns placeholder when no files are available" do
    expect(context.to_prompt).to eq("(No repository source available.)")
  end

  it "returns placeholder when GitHub API errors" do
    allow(fake_client).to receive(:directory_paths)
      .and_raise(GithubClient::Error, "rate limit exceeded")

    expect(context.to_prompt).to eq("(No repository source available.)")
  end
end
