require "rails_helper"

RSpec.describe "Portal", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:project) { create(:project) }
  let(:collaborator) { create(:collaborator) }

  def verify_collaborator!(collab = collaborator)
    token = collab.magic_tokens.create!
    get verify_portal_session_path(share_token: project.share_token, token: token.token)
  end

  describe "GET /p/:share_token" do
    it "returns 200 for valid share_token" do
      get portal_path(share_token: project.share_token)
      expect(response).to have_http_status(:ok)
    end

    it "returns 404-like plain text for invalid share_token" do
      get portal_path(share_token: "invalid_token")
      expect(response).to have_http_status(:not_found)
      expect(response.body).to include("no longer valid")
    end
  end

  describe "POST /p/:share_token/sessions (request magic link)" do
    it "finds or creates collaborator and enqueues magic link email" do
      expect {
        post portal_sessions_path(share_token: project.share_token),
             params: { email: "new@example.com" }
      }.to have_enqueued_mail(CollaboratorMailer, :magic_link)
    end

    it "creates Collaborator record for new email" do
      expect {
        post portal_sessions_path(share_token: project.share_token),
             params: { email: "newuser@example.com" }
      }.to change(Collaborator, :count).by(1)
    end

    it "reuses existing Collaborator for known email" do
      create(:collaborator, email: "known@example.com")
      expect {
        post portal_sessions_path(share_token: project.share_token),
             params: { email: "known@example.com" }
      }.not_to change(Collaborator, :count)
    end

    it "redirects back to portal with notice" do
      post portal_sessions_path(share_token: project.share_token),
           params: { email: "user@example.com" }
      expect(response).to redirect_to(portal_path(share_token: project.share_token))
    end

    it "returns 422 with blank email" do
      post portal_sessions_path(share_token: project.share_token),
           params: { email: "" }
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns 422 with invalid email format" do
      post portal_sessions_path(share_token: project.share_token),
           params: { email: "not-an-email" }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "GET /p/:share_token/sessions/verify" do
    context "with valid token" do
      let(:token) { collaborator.magic_tokens.create! }

      it "establishes collaborator session and redirects to submissions" do
        get verify_portal_session_path(share_token: project.share_token, token: token.token)
        expect(response).to redirect_to(portal_submissions_path(share_token: project.share_token))
      end

      it "stores collaborator session expiry metadata" do
        freeze_time do
          get verify_portal_session_path(share_token: project.share_token, token: token.token)
          expect(session[:collaborator_authenticated_at]).to eq(Time.current.iso8601)
        end
      end

      it "consumes the token" do
        get verify_portal_session_path(share_token: project.share_token, token: token.token)
        expect(token.reload).to be_used
      end

      it "rotates the session to prevent session fixation" do
        get portal_path(share_token: project.share_token)
        session_id_before = cookies["_session_id"] || response.headers["Set-Cookie"]

        get verify_portal_session_path(share_token: project.share_token, token: token.token)
        session_id_after = cookies["_session_id"] || response.headers["Set-Cookie"]

        expect(session_id_after).not_to eq(session_id_before)
      end
    end

    context "with expired token" do
      let(:token) { collaborator.magic_tokens.create!(expires_at: 1.hour.ago) }

      it "redirects to portal with alert" do
        get verify_portal_session_path(share_token: project.share_token, token: token.token)
        expect(response).to redirect_to(portal_path(share_token: project.share_token))
      end
    end

    context "with already-used token" do
      let(:token) { collaborator.magic_tokens.create! }

      before { token.consume! }

      it "redirects to portal with alert" do
        get verify_portal_session_path(share_token: project.share_token, token: token.token)
        expect(response).to redirect_to(portal_path(share_token: project.share_token))
      end
    end

    context "with nonexistent token" do
      it "redirects to portal with alert" do
        get verify_portal_session_path(share_token: project.share_token, token: "bogus")
        expect(response).to redirect_to(portal_path(share_token: project.share_token))
      end
    end
  end

  describe "DELETE /p/:share_token/sessions" do
    it "signs out the collaborator and redirects to the portal landing" do
      verify_collaborator!

      delete portal_session_path(share_token: project.share_token)

      expect(response).to redirect_to(portal_path(share_token: project.share_token))
      expect(flash[:notice]).to eq("Signed out.")
      expect(session[:collaborator_id]).to be_nil
      expect(session[:collaborator_authenticated_at]).to be_nil
    end

    it "requires sign-in again after sign-out" do
      verify_collaborator!
      delete portal_session_path(share_token: project.share_token)

      get portal_submissions_path(share_token: project.share_token)

      expect(response).to redirect_to(new_portal_session_path(share_token: project.share_token))
    end
  end

  describe "collaborator session expiry" do
    it "expires the session after 30 days" do
      verify_collaborator!

      travel_to 31.days.from_now do
        get portal_submissions_path(share_token: project.share_token)
        expect(response).to redirect_to(new_portal_session_path(share_token: project.share_token))
      end
    end

    it "keeps the session active within 30 days" do
      verify_collaborator!

      travel_to 29.days.from_now do
        get portal_submissions_path(share_token: project.share_token)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "signed-in portal UI" do
    before { verify_collaborator! }

    it "shows a sign-out button on submissions index" do
      get portal_submissions_path(share_token: project.share_token)

      expect(response.body).to include("Sign out")
      expect(response.body).to include(portal_session_path(share_token: project.share_token))
    end
  end
end
