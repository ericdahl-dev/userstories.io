require "rails_helper"

RSpec.describe GithubIssueCreator do
  let(:user) { create(:user, github_token: "test_token") }
  let(:project) { create(:project, user: user, github_repo: "owner/repo") }
  let(:collaborator) { create(:collaborator, name: "Alice") }
  let(:submission) { create(:submission, project: project, collaborator: collaborator, title: "My Story", body: "I want this.") }

  subject(:creator) { described_class.new(submission) }

  describe "#create!" do
    let(:fake_client) { instance_double(GithubClient) }

    before do
      allow(GithubClient).to receive(:new).with("test_token").and_return(fake_client)
      allow(fake_client).to receive(:create_issue).and_return(number: 42, url: "https://github.com/owner/repo/issues/42")
    end

    it "creates a GitHub issue in the correct repo" do
      creator.create!
      expect(fake_client).to have_received(:create_issue).with(repo: "owner/repo", title: "My Story", body: anything)
    end

    it "includes submission body and backlink in issue body" do
      creator.create!
      expect(fake_client).to have_received(:create_issue) do |kwargs|
        expect(kwargs[:body]).to include("I want this.")
        expect(kwargs[:body]).to include("userstories.io")
        expect(kwargs[:body]).not_to include("Alice")
      end
    end

    it "returns issue number and url" do
      result = creator.create!
      expect(result).to eq(number: 42, url: "https://github.com/owner/repo/issues/42")
    end

    it "wraps GithubClient::Error in GithubIssueCreator::Error" do
      allow(fake_client).to receive(:create_issue).and_raise(GithubClient::Error)
      expect { creator.create! }.to raise_error(GithubIssueCreator::Error)
    end
  end
end
