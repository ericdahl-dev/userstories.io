require "rails_helper"

RSpec.describe Collaborator, type: :model do
  describe "validations" do
    it "requires email" do
      collaborator = build(:collaborator, email: "")
      expect(collaborator).not_to be_valid
    end

    it "requires valid email format" do
      collaborator = build(:collaborator, email: "not-an-email")
      expect(collaborator).not_to be_valid
    end

    it "requires unique email (case-insensitive)" do
      create(:collaborator, email: "user@example.com")
      collaborator = build(:collaborator, email: "USER@EXAMPLE.COM")
      expect(collaborator).not_to be_valid
    end

    it "requires name" do
      collaborator = build(:collaborator, name: "")
      expect(collaborator).not_to be_valid
    end
  end

  describe "email normalization" do
    it "downcases and strips email on save" do
      collaborator = create(:collaborator, email: "  USER@EXAMPLE.COM  ")
      expect(collaborator.email).to eq("user@example.com")
    end
  end
end
