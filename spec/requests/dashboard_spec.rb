require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  describe "GET /dashboard" do
    context "when unauthenticated" do
      it "redirects to sign-in" do
        get dashboard_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated" do
      let(:user) { create(:user) }
      let(:other_user) { create(:user) }

      before { sign_in user }

      it "returns 200" do
        get dashboard_path
        expect(response).to have_http_status(:ok)
      end

      it "shows pending submissions from the developer's own projects" do
        own_project = create(:project, user: user)
        collaborator = create(:collaborator)
        own_submission = create(:submission, project: own_project, collaborator: collaborator, status: "pending")

        get dashboard_path

        expect(response.body).to include(own_submission.title)
      end

      it "does not show submissions from another developer's projects" do
        other_project = create(:project, user: other_user)
        collaborator = create(:collaborator)
        other_submission = create(:submission, project: other_project, collaborator: collaborator, status: "pending")

        get dashboard_path

        expect(response.body).not_to include(other_submission.title)
      end

      it "does not show accepted submissions in the inbox" do
        own_project = create(:project, user: user)
        collaborator = create(:collaborator)
        accepted = create(:submission, project: own_project, collaborator: collaborator, status: "accepted")

        get dashboard_path

        expect(response.body).not_to include(accepted.title)
      end
    end
  end
end

RSpec.describe "GoodJob::Engine", type: :request do
  describe "GET /jobs" do
    context "when unauthenticated" do
      it "redirects to sign-in" do
        get "/jobs"
        expect(response.location).to include("/users/sign_in")
      end
    end

    context "when authenticated" do
      let(:user) { create(:user) }
      before { sign_in user }

      it "returns 200 or redirect within GoodJob" do
        get "/jobs"
        expect(response.status).to be < 400
      end
    end
  end
end
