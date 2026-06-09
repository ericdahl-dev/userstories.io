require "rails_helper"

RSpec.describe "Umami analytics", type: :request do
  describe "when not configured" do
    it "does not include the tracking script on the landing page" do
      get root_path

      expect(response.body).not_to include("data-website-id")
    end
  end

  describe "when configured" do
    let(:user) { create(:user) }

    around do |example|
      original_website_id = ENV["UMAMI_WEBSITE_ID"]
      original_script_url = ENV["UMAMI_SCRIPT_URL"]

      ENV["UMAMI_WEBSITE_ID"] = "test-website-id"
      ENV["UMAMI_SCRIPT_URL"] = "https://analytics.example.com/script.js"

      example.run
    ensure
      ENV["UMAMI_WEBSITE_ID"] = original_website_id
      ENV["UMAMI_SCRIPT_URL"] = original_script_url
    end

    it "includes the tracking script on the landing page only" do
      get root_path

      expect(response.body).to include('src="https://analytics.example.com/script.js"')
      expect(response.body).to include('data-website-id="test-website-id"')
    end

    it "does not include the tracking script on other pages" do
      sign_in user
      get dashboard_path

      expect(response.body).not_to include("data-website-id")
    end

    it "allows the Umami origin in Content-Security-Policy on the landing page" do
      get root_path

      csp = response.headers["Content-Security-Policy"]
      expect(csp).to include("https://analytics.example.com")
    end

    it "does not allow the Umami origin in Content-Security-Policy on other pages" do
      sign_in user
      get dashboard_path

      csp = response.headers["Content-Security-Policy"]
      expect(csp).not_to include("https://analytics.example.com")
    end
  end
end
