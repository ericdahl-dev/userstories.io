# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Developers", type: :request do
  let(:admin) { create(:user, email: "ops@example.com") }
  let(:developer) { create(:user, email: "dev@example.com") }

  before do
    allow(AdminAllowlist).to receive(:include?) { |email| email == admin.email }
  end

  describe "GET /admin/developers" do
    it "redirects unauthenticated users to sign-in" do
      get admin_developers_path

      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirects non-admin users" do
      sign_in developer

      get admin_developers_path

      expect(response).to redirect_to(root_path)
    end

    it "lists developers for admins" do
      sign_in admin
      developer

      get admin_developers_path, params: { q: "dev@" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("dev@example.com")
    end
  end

  describe "POST /admin/developers/:id/grant_credits" do
    before { sign_in admin }

    it "grants credits to a developer" do
      expect {
        post grant_credits_admin_developer_path(developer), params: { amount: 7, reason: "Support comp" }
      }.to change { developer.reload.refinement_credit_balance }.by(7)

      expect(response).to redirect_to(admin_developer_path(developer))
      follow_redirect!
      expect(response.body).to include("Granted 7 refinement credits")
      expect(response.body).to include("Support comp")
    end

    it "allows an admin to grant credits to themselves" do
      expect {
        post grant_credits_admin_developer_path(admin), params: { amount: 3 }
      }.to change { admin.reload.refinement_credit_balance }.by(3)
    end

    it "rejects non-admin users" do
      sign_out admin
      sign_in developer

      expect {
        post grant_credits_admin_developer_path(developer), params: { amount: 3 }
      }.not_to change { developer.reload.refinement_credit_balance }

      expect(response).to redirect_to(root_path)
    end
  end
end
