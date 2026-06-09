require "rails_helper"

RSpec.describe "Portal::Submissions", type: :request do
  let(:project) { create(:project) }
  let(:collaborator) { create(:collaborator) }

  def sign_in_collaborator(collab)
    post portal_sessions_path(share_token: project.share_token), params: { email: collab.email }
    token = collab.magic_tokens.valid.last
    get verify_portal_session_path(share_token: project.share_token, token: token.token)
  end

  describe "GET /p/:share_token/submissions/new" do
    context "when unauthenticated" do
      it "redirects to magic-link prompt" do
        get new_portal_submission_path(share_token: project.share_token)
        expect(response).to redirect_to(new_portal_session_path(share_token: project.share_token))
      end
    end

    context "when authenticated" do
      before { sign_in_collaborator(collaborator) }

      it "returns 200" do
        get new_portal_submission_path(share_token: project.share_token)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "POST /p/:share_token/submissions" do
    context "when unauthenticated" do
      it "redirects to magic-link prompt" do
        post portal_submissions_path(share_token: project.share_token),
             params: { submission: { title: "A story", body: "Some details" } }
        expect(response).to redirect_to(new_portal_session_path(share_token: project.share_token))
      end
    end

    context "when authenticated" do
      before { sign_in_collaborator(collaborator) }

      it "creates a submission and redirects to refinement chat" do
        allow(RefineSubmissionJob).to receive(:perform_later)

        expect {
          post portal_submissions_path(share_token: project.share_token),
               params: { submission: { title: "A story", body: "Some details" } }
        }.to change(Submission, :count).by(1)

        submission = Submission.last
        expect(response).to redirect_to(portal_submission_refine_path(share_token: project.share_token, id: submission))
        expect(RefineSubmissionJob).to have_received(:perform_later).with(submission)
      end

      it "creates submission with pending status" do
        post portal_submissions_path(share_token: project.share_token),
             params: { submission: { title: "A story", body: "Some details" } }
        expect(Submission.last.status).to eq("pending")
      end

      it "associates submission with authenticated collaborator" do
        post portal_submissions_path(share_token: project.share_token),
             params: { submission: { title: "A story", body: "Some details" } }
        expect(Submission.last.collaborator).to eq(collaborator)
      end

      it "re-renders new with 422 on missing fields" do
        post portal_submissions_path(share_token: project.share_token),
             params: { submission: { title: "", body: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /p/:share_token/submissions" do
    context "when unauthenticated" do
      it "redirects to magic-link prompt" do
        get portal_submissions_path(share_token: project.share_token)
        expect(response).to redirect_to(new_portal_session_path(share_token: project.share_token))
      end
    end

    context "when authenticated" do
      before { sign_in_collaborator(collaborator) }

      it "returns 200" do
        get portal_submissions_path(share_token: project.share_token)
        expect(response).to have_http_status(:ok)
      end

      it "shows own submissions" do
        submission = create(:submission, collaborator: collaborator, project: project, status: "pending")
        get portal_submissions_path(share_token: project.share_token)
        expect(response.body).to include(submission.title)
      end

      it "does not show another collaborator's submissions" do
        other_collaborator = create(:collaborator)
        other_submission = create(:submission, collaborator: other_collaborator, project: project)
        get portal_submissions_path(share_token: project.share_token)
        expect(response.body).not_to include(other_submission.title)
      end

      it "shows cached GitHub summary for accepted submissions" do
        submission = create(
          :submission,
          collaborator: collaborator,
          project: project,
          status: "accepted",
          github_issue_number: 42,
          github_issue_url: "https://github.com/owner/repo/issues/42",
          github_issue_summary: "Open · bug · updated 2 hours ago",
          github_issue_synced_at: Time.current
        )

        get portal_submissions_path(share_token: project.share_token)

        expect(response.body).to include(submission.github_issue_summary)
        expect(response.body).to include(submission.github_issue_url)
      end

      it "enqueues a sync for stale GitHub issue metadata" do
        stale_submission = create(
          :submission,
          collaborator: collaborator,
          project: project,
          status: "accepted",
          github_issue_number: 42,
          github_issue_url: "https://github.com/owner/repo/issues/42",
          github_issue_synced_at: 6.minutes.ago
        )

        allow(SyncSubmissionGithubStatusJob).to receive(:perform_later)

        get portal_submissions_path(share_token: project.share_token)

        expect(SyncSubmissionGithubStatusJob).to have_received(:perform_later).with(stale_submission)
      end
    end
  end
end

RSpec.describe "Portal::Profile", type: :request do
  let(:project) { create(:project) }
  let(:collaborator) { create(:collaborator, name: "swift-penguin-42") }

  def sign_in_collaborator(collab)
    post portal_sessions_path(share_token: project.share_token), params: { email: collab.email }
    token = collab.magic_tokens.valid.last
    get verify_portal_session_path(share_token: project.share_token, token: token.token)
  end

  describe "PATCH /p/:share_token/profile" do
    context "when authenticated" do
      before { sign_in_collaborator(collaborator) }

      it "updates display name and redirects" do
        patch portal_profile_path(share_token: project.share_token),
              params: { collaborator: { name: "brave-otter-77" } }
        expect(response).to redirect_to(portal_submissions_path(share_token: project.share_token))
        expect(collaborator.reload.name).to eq("brave-otter-77")
      end

      it "re-renders with 422 on blank name" do
        patch portal_profile_path(share_token: project.share_token),
              params: { collaborator: { name: "" } }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when unauthenticated" do
      it "redirects to sign-in" do
        patch portal_profile_path(share_token: project.share_token),
              params: { collaborator: { name: "brave-otter-77" } }
        expect(response).to redirect_to(new_portal_session_path(share_token: project.share_token))
      end
    end
  end
end
