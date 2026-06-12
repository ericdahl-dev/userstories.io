require "rails_helper"

RSpec.describe "Home", type: :request do
  describe "GET /" do
    it "returns 200" do
      get root_path
      expect(response).to have_http_status(:ok)
    end

    it "is not the Rails default welcome page" do
      get root_path
      expect(response.body).not_to include("Yay! You're on Rails!")
    end

    it "includes the product value proposition" do
      get root_path
      expect(response.body).to include("GitHub")
    end

    it "includes Open Graph meta tags" do
      get root_path
      expect(response.body).to include('property="og:title"')
      expect(response.body).to include('property="og:description"')
      expect(response.body).to include('property="og:image"')
      expect(response.body).to include('property="og:url"')
      expect(response.body).to include('property="og:type" content="website"')
      expect(response.body).to include('property="og:site_name" content="userstories.io"')
    end

    it "populates Open Graph content with page-specific values" do
      get root_path
      expect(response.body).to include("userstories.io - Stakeholder feedback")
      expect(response.body).to include("Collect user stories from collaborators")
      expect(response.body).to match(/property="og:image" content="https?:\/\/.*apple-touch-icon\.png"/)
    end

    it "includes Twitter Card meta tags" do
      get root_path
      expect(response.body).to include('name="twitter:card" content="summary"')
      expect(response.body).to include('name="twitter:title"')
      expect(response.body).to include('name="twitter:description"')
      expect(response.body).to include('name="twitter:image"')
    end

    it "uses an absolute URL for the OG image" do
      get root_path
      expect(response.body).to match(/property="og:image" content="https?:\/\//)
    end
  end
end

RSpec.describe "Security headers", type: :request do
  it "sets Content-Security-Policy header" do
    get root_path
    expect(response.headers["Content-Security-Policy"]).to be_present
  end
end
