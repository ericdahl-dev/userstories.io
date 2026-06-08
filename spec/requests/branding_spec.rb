require "rails_helper"

RSpec.describe "Branding", type: :request do
  describe "logo in UI" do
    it "renders the brand mark on the landing page" do
      get root_path

      expect(response.body).to include('/icon.svg')
      expect(response.body).to include("userstories.io")
    end

    it "renders the brand mark in the developer nav" do
      user = create(:user)
      sign_in user

      get dashboard_path

      expect(response.body).to include('/icon.svg')
      expect(response.body).to include("userstories.io")
    end
  end

  describe "PWA manifest" do
    it "uses brand colors and icon sizes" do
      get "/manifest.json"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('"theme_color": "#4f46e5"')
      expect(response.body).to include('"background_color": "#ffffff"')
      expect(response.body).to include('"/icon-192.png"')
    end
  end
end
