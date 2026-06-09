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

    it "visible_to_collaborator excludes dismissed submissions" do
      pending_sub = create(:submission, project: project, collaborator: collaborator, status: "pending")
      dismissed_sub = create(:submission, project: project, collaborator: collaborator, status: "dismissed")

      expect(Submission.visible_to_collaborator).to include(pending_sub)
      expect(Submission.visible_to_collaborator).not_to include(dismissed_sub)
    end
  end

  describe "#accept!" do
    it "transitions status to accepted and stores GitHub fields" do
      submission = create(:submission, status: "pending")
      submission.accept!(github_issue_number: 42, github_issue_url: "https://github.com/owner/repo/issues/42")
      expect(submission.reload.status).to eq("accepted")
      expect(submission.github_issue_number).to eq(42)
      expect(submission.github_issue_url).to eq("https://github.com/owner/repo/issues/42")
      expect(submission.github_issue_state).to eq("open")
      expect(submission.github_issue_summary).to eq("Open · just created")
      expect(submission.github_issue_synced_at).to be_present
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

  describe "refinement cap helpers" do
    it "#refinement_at_cap? is false with no collaborator replies" do
      submission = create(:submission)
      expect(submission).not_to be_refinement_at_cap
      expect(submission.refinement_replies_remaining).to eq(2)
    end

    it "#refinement_at_cap? is true after max collaborator replies" do
      submission = create(:submission)
      Submission::MAX_REFINEMENT_COLLABORATOR_REPLIES.times do
        create(:refinement_message, submission: submission, role: "collaborator", body: "reply")
      end
      expect(submission).to be_refinement_at_cap
      expect(submission.refinement_replies_remaining).to eq(0)
    end
  end

  describe "refinement helpers" do
    it "#refinement_initial_due? is true before the first assistant reply" do
      submission = build(:submission, refinement_status: "pending")
      expect(submission).to be_refinement_initial_due
    end

    it "#refinement_turn_due? is true when a collaborator reply awaits a response" do
      submission = create(:submission)
      create(:refinement_message, submission: submission, role: "assistant", body: "Draft")
      create(:refinement_message, submission: submission, role: "collaborator", body: "More detail")

      expect(submission).to be_refinement_turn_due
    end
  end

  describe "GitHub status helpers" do
    it "#github_issue_status_pending? is true without a cached summary" do
      submission = build(:submission, github_issue_number: 42, github_issue_summary: nil)
      expect(submission).to be_github_issue_status_pending
    end

    it "#github_status_refresh_needed? is true for accepted submissions due for refresh" do
      submission = build(
        :submission,
        status: "accepted",
        github_issue_number: 42,
        github_issue_summary: "Open · bug",
        github_issue_synced_at: 6.minutes.ago
      )

      expect(submission).to be_github_status_refresh_needed
    end

    it "#github_status_refresh_needed? is false for freshly synced shipped submissions" do
      submission = build(
        :submission,
        status: "shipped",
        github_issue_number: 42,
        github_issue_summary: "Closed · shipped",
        github_issue_synced_at: Time.current
      )

      expect(submission).not_to be_github_status_refresh_needed
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
