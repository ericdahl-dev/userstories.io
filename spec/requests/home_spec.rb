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
  end
end
