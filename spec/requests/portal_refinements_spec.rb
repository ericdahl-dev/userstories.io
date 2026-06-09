require "rails_helper"

RSpec.describe "Portal::Refinements", type: :request do
  let(:project) { create(:project) }
  let(:collaborator) { create(:collaborator) }
  let(:submission) { create(:submission, project: project, collaborator: collaborator) }

  def sign_in_collaborator(collab)
    post portal_sessions_path(share_token: project.share_token), params: { email: collab.email }
    token = collab.magic_tokens.valid.last
    get verify_portal_session_path(share_token: project.share_token, token: token.token)
  end

  before { sign_in_collaborator(collaborator) }

  describe "GET /p/:share_token/submissions/:id/refine" do
    it "shows the refinement chat" do
      create(:refinement_message, submission: submission, role: "assistant", body: "Hello")

      get portal_submission_refine_path(share_token: project.share_token, id: submission)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Hello")
      expect(response.body).to include("2 replies remaining")
    end
  end

  describe "POST /p/:share_token/submissions/:id/refine/messages" do
    it "creates a collaborator message and enqueues a turn job" do
      allow(RefinementTurnJob).to receive(:perform_later)

      expect {
        post portal_submission_refine_messages_path(share_token: project.share_token, id: submission),
             params: { refinement_message: { body: "Can you clarify scope?" } }
      }.to change { submission.refinement_messages.where(role: "collaborator").count }.by(1)

      expect(RefinementTurnJob).to have_received(:perform_later).with(submission)
      expect(response).to redirect_to(portal_submission_refine_path(share_token: project.share_token, id: submission))
    end

    it "returns 422 when at reply cap" do
      Submission::MAX_REFINEMENT_COLLABORATOR_REPLIES.times do |n|
        create(:refinement_message, submission: submission, role: "collaborator", body: "Reply #{n}")
      end

      post portal_submission_refine_messages_path(share_token: project.share_token, id: submission),
           params: { refinement_message: { body: "One too many" } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Refinement complete")
    end
  end

  describe "POST /p/:share_token/submissions/:id/refine/finalize" do
    it "locks refinement and redirects to submissions list" do
      post portal_submission_refine_finalize_path(share_token: project.share_token, id: submission)

      expect(submission.reload.refinement_locked_at).to be_present
      expect(response).to redirect_to(portal_submissions_path(share_token: project.share_token))
    end
  end
end
