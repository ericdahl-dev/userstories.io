require "rails_helper"

RSpec.describe "Portal magic link rate limiting", type: :request do
  let(:project) { create(:project) }
  let(:path) { portal_sessions_path(share_token: project.share_token) }

  def post_magic_link(email:, ip: "127.0.0.1")
    post path, params: { email: email }, headers: { "REMOTE_ADDR" => ip }
  end

  describe "IP throttle" do
    it "returns 429 on the 6th POST from the same IP within 60 seconds" do
      5.times { post_magic_link(email: "user#{_1}@example.com") }

      post_magic_link(email: "sixth@example.com")

      expect(response).to have_http_status(:too_many_requests)
    end

    it "still allows GET /sessions/new after IP limit is reached" do
      6.times { post_magic_link(email: "user#{_1}@example.com") }

      get new_portal_session_path(share_token: project.share_token)

      expect(response).to have_http_status(:ok)
    end
  end

  describe "email throttle" do
    it "returns 429 on the 4th POST for the same normalized email within 5 minutes" do
      3.times { |i| post_magic_link(email: "  FLOOD@Example.COM  ", ip: "10.0.0.#{i + 1}") }

      post_magic_link(email: "flood@example.com", ip: "10.0.0.99")

      expect(response).to have_http_status(:too_many_requests)
    end
  end

  describe "under-limit requests" do
    it "still enqueues mail and redirects with success notice" do
      expect {
        post_magic_link(email: "ok@example.com")
      }.to have_enqueued_mail(CollaboratorMailer, :magic_link)

      expect(response).to redirect_to(portal_path(share_token: project.share_token))
    end
  end
end
