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

    it "requires unique name (case-insensitive)" do
      create(:collaborator, name: "swift-penguin-42")
      collaborator = build(:collaborator, name: "SWIFT-PENGUIN-42")
      expect(collaborator).not_to be_valid
    end
  end

  describe "email normalization" do
    it "downcases and strips email on save" do
      collaborator = create(:collaborator, email: "  USER@EXAMPLE.COM  ")
      expect(collaborator.email).to eq("user@example.com")
    end
  end

  describe ".generate_handle" do
    it "returns adjective-noun-number format" do
      handle = Collaborator.generate_handle
      expect(handle).to match(/\A[a-z]+-[a-z]+-\d+\z/)
    end

    it "returns unique handles on repeated calls" do
      handles = 10.times.map { Collaborator.generate_handle }
      expect(handles.uniq.length).to be > 1
    end
  end

  describe ".for_login" do
    it "creates collaborator with generated handle when new" do
      collaborator = Collaborator.for_login(email: "alice@example.com")
      expect(collaborator.email).to eq("alice@example.com")
      expect(collaborator.name).to match(/\A[a-z]+-[a-z]+-\d+\z/)
      expect(collaborator).to be_persisted
    end

    it "normalizes email (strips and downcases)" do
      collaborator = Collaborator.for_login(email: "  ALICE@EXAMPLE.COM  ")
      expect(collaborator.email).to eq("alice@example.com")
    end

    it "returns existing collaborator without changing name" do
      existing = create(:collaborator, email: "alice@example.com", name: "swift-penguin-42")
      result = Collaborator.for_login(email: "alice@example.com")
      expect(result.id).to eq(existing.id)
      expect(result.name).to eq("swift-penguin-42")
    end

    it "generates handle for existing record with blank name" do
      existing = create(:collaborator, email: "alice@example.com", name: "Alice")
      existing.update_column(:name, "")
      result = Collaborator.for_login(email: "alice@example.com")
      expect(result.name).to match(/\A[a-z]+-[a-z]+-\d+\z/)
    end
  end
end
