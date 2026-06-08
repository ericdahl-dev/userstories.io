require "rails_helper"

RSpec.describe User, type: :model do
  describe "validations" do
    it "requires email" do
      user = build(:user, email: "")
      expect(user).not_to be_valid
    end

    it "requires unique email" do
      create(:user, email: "dev@example.com")
      user = build(:user, email: "dev@example.com")
      expect(user).not_to be_valid
    end
  end

  describe ".from_omniauth" do
    let(:auth) do
      OmniAuth::AuthHash.new(
        provider: "github",
        uid: "uid_123",
        info: { email: "dev@example.com" },
        credentials: { token: "token_abc" }
      )
    end

    it "creates user on first call" do
      expect { User.from_omniauth(auth) }.to change(User, :count).by(1)
    end

    it "reuses existing user on second call" do
      User.from_omniauth(auth)
      expect { User.from_omniauth(auth) }.not_to change(User, :count)
    end

    it "updates github_token on each call" do
      User.from_omniauth(auth)
      new_auth = OmniAuth::AuthHash.new(
        provider: "github",
        uid: "uid_123",
        info: { email: "dev@example.com" },
        credentials: { token: "new_token" }
      )
      updated = User.from_omniauth(new_auth)
      expect(updated.github_token).to eq("new_token")
    end
  end
end
