require "rails_helper"

RSpec.describe GithubIssueCreator do
  let(:user) { create(:user, github_token: "test_token") }
  let(:project) { create(:project, user: user, github_repo: "owner/repo") }
  let(:collaborator) { create(:collaborator, name: "Alice") }
  let(:submission) { create(:submission, project: project, collaborator: collaborator, title: "My Story", body: "I want this.") }

  subject(:creator) { described_class.new(submission) }

  describe "#create!" do
    let(:fake_issue) { double(number: 42, html_url: "https://github.com/owner/repo/issues/42") }
    let(:fake_client) { instance_double(Octokit::Client, create_issue: fake_issue) }

    before do
      allow(Octokit::Client).to receive(:new).with(access_token: "test_token").and_return(fake_client)
    end

    it "creates a GitHub issue in the correct repo" do
      creator.create!
      expect(fake_client).to have_received(:create_issue).with("owner/repo", "My Story", anything)
    end

    it "includes submission body and backlink in issue body" do
      creator.create!
      expect(fake_client).to have_received(:create_issue) do |_repo, _title, body|
        expect(body).to include("I want this.")
        expect(body).to include("userstories.io")
        expect(body).to include("Alice")
      end
    end

    it "returns issue number and url" do
      result = creator.create!
      expect(result).to eq(number: 42, url: "https://github.com/owner/repo/issues/42")
    end

    it "wraps Octokit::Error in GithubIssueCreator::Error" do
      allow(fake_client).to receive(:create_issue).and_raise(Octokit::Error)
      expect { creator.create! }.to raise_error(GithubIssueCreator::Error)
    end
  end
end
