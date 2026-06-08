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

  describe ".for_login" do
    it "creates collaborator with name from email prefix when new" do
      collaborator = Collaborator.for_login(email: "alice@example.com")
      expect(collaborator.email).to eq("alice@example.com")
      expect(collaborator.name).to eq("alice")
      expect(collaborator).to be_persisted
    end

    it "normalizes email (strips and downcases)" do
      collaborator = Collaborator.for_login(email: "  ALICE@EXAMPLE.COM  ")
      expect(collaborator.email).to eq("alice@example.com")
    end

    it "returns existing collaborator without changing name" do
      existing = create(:collaborator, email: "alice@example.com", name: "Alice Smith")
      result = Collaborator.for_login(email: "alice@example.com")
      expect(result.id).to eq(existing.id)
      expect(result.name).to eq("Alice Smith")
    end

    it "sets name from email prefix if existing record has blank name" do
      existing = create(:collaborator, email: "alice@example.com", name: "Alice")
      existing.update_column(:name, "")
      result = Collaborator.for_login(email: "alice@example.com")
      expect(result.name).to eq("alice")
    end
  end
end
