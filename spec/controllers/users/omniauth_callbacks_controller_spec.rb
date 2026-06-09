require "rails_helper"

RSpec.describe Users::OmniauthCallbacksController, type: :controller do
  include Devise::Test::ControllerHelpers

  before do
    @routes = ActionDispatch::Routing::RouteSet.new
    @routes.draw do
      get "github" => "users/omniauth_callbacks#github"
      get "failure" => "users/omniauth_callbacks#failure"
    end

    request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe "GET #github" do
    let(:oauth_uid) { "oauth_uid_#{SecureRandom.hex(4)}" }
    let(:auth_hash) do
      OmniAuth::AuthHash.new(
        provider: "github",
        uid: oauth_uid,
        info: { email: "oauth_#{oauth_uid}@example.com" },
        credentials: { token: "token_abc" },
        extra: { raw_info: {} }
      )
    end

    before { request.env["omniauth.auth"] = auth_hash }

    it "signs in an existing user and redirects to the dashboard" do
      user = create(
        :user,
        email: "oauth_#{oauth_uid}@example.com",
        provider: "github",
        uid: oauth_uid
      )

      get :github

      expect(response).to redirect_to("/dashboard")
      expect(controller.current_user).to eq(user)
    end

    it "creates a new user on first GitHub login" do
      expect { get :github }.to change(User, :count).by(1)
    end

    it "redirects to registration when the user cannot be saved" do
      invalid_user = build(:user, email: "")
      allow(invalid_user).to receive(:persisted?).and_return(false)
      allow(invalid_user).to receive(:errors).and_return(
        ActiveModel::Errors.new(invalid_user).tap { |errors| errors.add(:email, "can't be blank") }
      )
      allow(User).to receive(:from_omniauth).and_return(invalid_user)

      get :github

      expect(response).to redirect_to("/users/sign_up")
      expect(session["devise.github_data"]).to be_present
    end
  end

  describe "GET #failure" do
    it "redirects to root with an alert" do
      get :failure

      expect(response).to redirect_to("/")
      expect(flash[:alert]).to eq("GitHub authentication failed.")
    end
  end
end
