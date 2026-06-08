require "rails_helper"

RSpec.describe Submission, type: :model do
  describe "validations" do
    it "requires title" do
      submission = build(:submission, title: "")
      expect(submission).not_to be_valid
    end

    it "requires body" do
      submission = build(:submission, body: "")
      expect(submission).not_to be_valid
    end

    it "requires valid status" do
      submission = build(:submission, status: "invalid_status")
      expect(submission).not_to be_valid
    end

    it "accepts pending as valid status" do
      submission = build(:submission, status: "pending")
      expect(submission).to be_valid
    end
  end

  describe "scopes" do
    let(:project) { create(:project) }
    let(:collaborator) { create(:collaborator) }

    it "pending_review returns only pending submissions" do
      pending_sub = create(:submission, project: project, collaborator: collaborator, status: "pending")
      accepted_sub = create(:submission, project: project, collaborator: collaborator, status: "accepted")
      expect(Submission.pending_review).to include(pending_sub)
      expect(Submission.pending_review).not_to include(accepted_sub)
    end

    it "recent orders by created_at descending" do
      older = create(:submission, project: project, collaborator: collaborator, created_at: 1.hour.ago)
      newer = create(:submission, project: project, collaborator: collaborator, created_at: 1.minute.ago)
      expect(Submission.recent.first).to eq(newer)
    end
  end

  describe "#accept!" do
    it "transitions status to accepted and stores GitHub fields" do
      submission = create(:submission, status: "pending")
      submission.accept!(github_issue_number: 42, github_issue_url: "https://github.com/owner/repo/issues/42")
      expect(submission.reload.status).to eq("accepted")
      expect(submission.github_issue_number).to eq(42)
      expect(submission.github_issue_url).to eq("https://github.com/owner/repo/issues/42")
    end
  end

  describe "#ship!" do
    it "transitions status to shipped" do
      submission = create(:submission, status: "accepted")
      submission.ship!
      expect(submission.reload.status).to eq("shipped")
    end
  end
end
