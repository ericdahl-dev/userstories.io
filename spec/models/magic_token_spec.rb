require "rails_helper"

RSpec.describe MagicToken, type: :model do
  describe "token generation" do
    it "generates a token on create" do
      token = create(:magic_token)
      expect(token.token).to be_present
    end

    it "sets expires_at 15 minutes from now" do
      token = create(:magic_token)
      expect(token.expires_at).to be_within(5.seconds).of(15.minutes.from_now)
    end
  end

  describe ".valid scope" do
    it "includes unexpired, unconsumed tokens" do
      token = create(:magic_token)
      expect(MagicToken.valid).to include(token)
    end

    it "excludes expired tokens" do
      token = create(:magic_token, expires_at: 1.minute.ago)
      expect(MagicToken.valid).not_to include(token)
    end

    it "excludes consumed tokens" do
      token = create(:magic_token, used_at: 1.minute.ago)
      expect(MagicToken.valid).not_to include(token)
    end
  end

  describe "#expired?" do
    it "returns true when expires_at is in the past" do
      token = build(:magic_token, expires_at: 1.second.ago)
      expect(token).to be_expired
    end

    it "returns false when expires_at is in the future" do
      token = build(:magic_token, expires_at: 1.minute.from_now)
      expect(token).not_to be_expired
    end
  end

  describe "#used?" do
    it "returns true when used_at is set" do
      token = build(:magic_token, used_at: Time.current)
      expect(token).to be_used
    end

    it "returns false when used_at is nil" do
      token = build(:magic_token, used_at: nil)
      expect(token).not_to be_used
    end
  end

  describe "#consume!" do
    it "sets used_at" do
      token = create(:magic_token)
      expect { token.consume! }.to change { token.used_at }.from(nil)
    end

    it "is idempotent — token is used after consume" do
      token = create(:magic_token)
      token.consume!
      expect(token.reload).to be_used
    end
  end
end
