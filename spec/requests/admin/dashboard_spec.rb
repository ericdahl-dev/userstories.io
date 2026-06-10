require "rails_helper"

RSpec.describe "Admin::Dashboard", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:admin) { create(:user, email: "ops@example.com") }
  let(:developer) { create(:user, email: "dev@example.com") }

  before do
    allow(AdminAllowlist).to receive(:include?) { |email| email == admin.email }
  end

  describe "GET /admin" do
    context "when unauthenticated" do
      it "redirects to sign-in" do
        get admin_root_path

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated as a non-admin" do
      before { sign_in developer }

      it "redirects with an authorization error" do
        get admin_root_path

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("You are not authorized to perform this action.")
      end
    end

    context "when authenticated as an admin" do
      before { sign_in admin }

      it "shows platform totals and submission breakdown" do
        project = create(:project, user: admin)
        collaborator = create(:collaborator)
        create(:submission, project: project, collaborator: collaborator, status: "pending", title: "Stale inbox item")
        create(:submission, project: project, collaborator: collaborator, status: "accepted")

        get admin_root_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Ops dashboard")
        expect(response.body).to include("Developers")
        expect(response.body).to include("Pending")
        expect(response.body).to include("Acceptance rate")
        expect(response.body).to include("accepted ÷ (accepted + dismissed)")
        expect(response.body).to include("Stale inbox item")
        expect(response.body).to include("Magic links sent")
      end

      it "filters metrics by time window" do
        project = create(:project, user: admin)
        collaborator = create(:collaborator)

        travel_to Time.zone.parse("2026-06-15 12:00:00") do
          create(:submission, project: project, collaborator: collaborator, status: "accepted", title: "Recent story")
          create(:submission, project: project, collaborator: collaborator, status: "accepted", title: "Old story", created_at: 40.days.ago)

          get admin_root_path, params: { window: "7d" }

          expect(response.body).to include("Recent story")
          expect(response.body).not_to include("Old story")
        end
      end
    end
  end
end
