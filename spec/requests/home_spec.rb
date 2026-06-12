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

    it "renders Open Graph and Twitter card metadata" do
      get root_path

      expect(response.body).to include('<meta property="og:title" content="userstories.io - Stakeholder feedback, structured and in GitHub">')
      expect(response.body).to include('<meta property="og:description" content="Collect user stories from collaborators via a shareable link. Triage in your inbox and open GitHub issues when you accept.">')
      expect(response.body).to include('<meta property="og:image" content="http://www.example.com/social-card.png">')
      expect(response.body).to include('<meta property="og:url" content="http://www.example.com/">')
      expect(response.body).to include('<meta name="twitter:card" content="summary_large_image">')
    end
  end
end

RSpec.describe "Security headers", type: :request do
  it "sets Content-Security-Policy header" do
    get root_path
    expect(response.headers["Content-Security-Policy"]).to be_present
  end
end
