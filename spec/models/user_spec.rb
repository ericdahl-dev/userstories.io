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

  describe "github_token encryption" do
    def raw_github_token(user)
      User.connection.select_value("SELECT github_token FROM users WHERE id = #{user.id}")
    end

    it "stores ciphertext in the database, not plaintext" do
      user = create(:user, github_token: "gho_secret_token_value")

      expect(user.github_token).to eq("gho_secret_token_value")
      expect(raw_github_token(user)).not_to eq("gho_secret_token_value")
      expect(raw_github_token(user)).to be_present
    end

    it "round-trips github_token on read and write" do
      user = create(:user, github_token: "initial_token")
      user.update!(github_token: "rotated_token")

      expect(user.reload.github_token).to eq("rotated_token")
    end

    it "re-encrypts legacy plaintext values" do
      user = create(:user, email: "legacy@example.com")
      User.connection.execute(
        "UPDATE users SET github_token = 'legacy_plaintext_token' WHERE id = #{user.id}"
      )

      expect(raw_github_token(user.reload)).to eq("legacy_plaintext_token")

      require Rails.root.join("db/migrate/20260609140000_encrypt_existing_github_tokens")
      EncryptExistingGithubTokens.new.up

      expect(user.reload.github_token).to eq("legacy_plaintext_token")
      expect(raw_github_token(user)).not_to eq("legacy_plaintext_token")
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
