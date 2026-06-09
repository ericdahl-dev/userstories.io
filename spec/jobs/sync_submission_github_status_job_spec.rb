require "rails_helper"

RSpec.describe SyncSubmissionGithubStatusJob, type: :job do
  describe "#perform" do
    it "runs the submission sync service" do
      submission = create(:submission, status: "accepted", github_issue_number: 42, github_issue_url: "https://github.com/owner/repo/issues/42")
      service = instance_double(SubmissionGithubSync, sync!: true)

      allow(SubmissionGithubSync).to receive(:new).with(submission).and_return(service)

      described_class.perform_now(submission)

      expect(service).to have_received(:sync!)
    end
  end
end
