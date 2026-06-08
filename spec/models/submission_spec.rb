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

    it "raises when submission is not pending" do
      submission = create(:submission, status: "accepted")
      expect {
        submission.accept!(github_issue_number: 1, github_issue_url: "https://example.com")
      }.to raise_error(Submission::InvalidTransition)
    end
  end

  describe "#dismiss!" do
    it "transitions status to dismissed" do
      submission = create(:submission, status: "pending")
      submission.dismiss!
      expect(submission.reload.status).to eq("dismissed")
    end

    it "raises when submission is not pending" do
      submission = create(:submission, status: "accepted")
      expect { submission.dismiss! }.to raise_error(Submission::InvalidTransition)
    end
  end

  describe "#ship!" do
    it "transitions status to shipped" do
      submission = create(:submission, status: "accepted")
      submission.ship!
      expect(submission.reload.status).to eq("shipped")
    end

    it "raises when submission is not accepted" do
      submission = create(:submission, status: "pending")
      expect { submission.ship! }.to raise_error(Submission::InvalidTransition)
    end
  end

  describe "guard predicates" do
    it "#acceptable? true when pending" do
      expect(build(:submission, status: "pending")).to be_acceptable
    end

    it "#acceptable? false when accepted" do
      expect(build(:submission, status: "accepted")).not_to be_acceptable
    end

    it "#dismissable? true when pending" do
      expect(build(:submission, status: "pending")).to be_dismissable
    end

    it "#dismissable? false when dismissed" do
      expect(build(:submission, status: "dismissed")).not_to be_dismissable
    end

    it "#shippable? true when accepted" do
      expect(build(:submission, status: "accepted")).to be_shippable
    end

    it "#shippable? false when pending" do
      expect(build(:submission, status: "pending")).not_to be_shippable
    end
  end
end
