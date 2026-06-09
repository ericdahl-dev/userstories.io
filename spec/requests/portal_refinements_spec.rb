require "rails_helper"

RSpec.describe "Portal::Refinements", type: :request do
  include ActiveJob::TestHelper

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
      expect(response.body).to include("turbo-cable-stream-source")
      expect(response.body).not_to include('http-equiv="refresh"')
    end

    it "enqueues the initial refinement and shows a typing indicator" do
      allow(RefineSubmissionJob).to receive(:perform_later)

      get portal_submission_refine_path(share_token: project.share_token, id: submission)

      expect(RefineSubmissionJob).to have_received(:perform_later).with(submission)
      expect(submission.reload).to be_refinement_processing
      expect(response.body).to include("Thinking")
    end
  end

  describe "POST /p/:share_token/submissions/:id/refine/messages" do
    it "creates a collaborator message and responds with turbo stream" do
      create(:refinement_message, submission: submission, role: "assistant", body: "Initial draft")

      expect {
        post portal_submission_refine_messages_path(share_token: project.share_token, id: submission),
             params: { refinement_message: { body: "Can you clarify scope?" } },
             headers: { "Accept" => "text/vnd.turbo-stream.html" }
      }.to have_enqueued_job(RefinementTurnJob).with(submission)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq(Mime[:turbo_stream])
      expect(response.body).to include("turbo-stream")
      expect(response.body).to include("Can you clarify scope?")
      expect(response.body).to include("refinement_typing_indicator")
      expect(submission.reload).to be_refinement_processing
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
