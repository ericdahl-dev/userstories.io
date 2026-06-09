require "rails_helper"

RSpec.describe SubmissionGithubSync do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user, github_token: "test_token") }
  let(:project) { create(:project, user: user, github_repo: "owner/repo") }
  let(:submission) do
    create(
      :submission,
      project: project,
      status: "accepted",
      github_issue_number: 42,
      github_issue_url: "https://github.com/owner/repo/issues/42"
    )
  end
  let(:fake_client) { instance_double(GithubClient) }

  subject(:service) { described_class.new(submission) }

  before do
    allow(GithubClient).to receive(:new).with("test_token").and_return(fake_client)
  end

  describe "#sync!" do
    it "caches the current GitHub issue state and summary" do
      issue = double(
        state: "open",
        labels: [ double(name: "bug"), double(name: "enhancement") ],
        updated_at: Time.zone.parse("2026-06-08 10:00:00 UTC")
      )
      allow(fake_client).to receive(:get_issue).with(repo: "owner/repo", number: 42).and_return(issue)

      travel_to Time.zone.parse("2026-06-08 12:00:00 UTC") do
        service.sync!
      end

      submission.reload

      expect(submission.github_issue_state).to eq("open")
      expect(submission.github_issue_summary).to eq("Open · bug, enhancement · updated about 2 hours ago")
      expect(submission.github_issue_synced_at).to eq(Time.zone.parse("2026-06-08 12:00:00 UTC"))
      expect(submission.status).to eq("accepted")
    end

    it "auto-ships accepted submissions when the GitHub issue is closed" do
      issue = double(state: "closed", labels: [], updated_at: 15.minutes.ago)
      allow(fake_client).to receive(:get_issue).and_return(issue)

      service.sync!

      expect(submission.reload.status).to eq("shipped")
      expect(submission.github_issue_state).to eq("closed")
    end

    it "marks status unavailable when GitHub sync fails" do
      allow(fake_client).to receive(:get_issue).and_raise(GithubClient::Error, "boom")

      service.sync!

      submission.reload

      expect(submission.github_issue_state).to be_nil
      expect(submission.github_issue_summary).to eq("GitHub status unavailable")
      expect(submission.github_issue_synced_at).to be_present
      expect(submission.status).to eq("accepted")
    end
  end
end
