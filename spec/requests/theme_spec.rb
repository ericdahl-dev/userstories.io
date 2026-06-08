require "rails_helper"

RSpec.describe "Dark mode", type: :request do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  describe "theme bootstrap script" do
    it "is present on the landing page" do
      get root_path
      expect(response.body).to include("localStorage.getItem('theme')")
      expect(response.body).to include('prefers-color-scheme: dark')
    end
  end

  describe "theme toggle" do
    it "renders on the developer dashboard" do
      sign_in user
      get dashboard_path
      expect(response.body).to include('data-theme-toggle')
    end

    it "renders on the collaborator portal" do
      get portal_path(share_token: project.share_token)
      expect(response.body).to include('data-theme-toggle')
    end
  end
end
