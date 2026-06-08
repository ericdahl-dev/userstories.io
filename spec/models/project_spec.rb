require "rails_helper"

RSpec.describe Project, type: :model do
  describe "validations" do
    it "requires name" do
      project = build(:project, name: "")
      expect(project).not_to be_valid
    end

    it "requires github_repo" do
      project = build(:project, github_repo: "")
      expect(project).not_to be_valid
    end

    it "requires unique share_token" do
      existing = create(:project)
      project = build(:project, share_token: existing.share_token)
      expect(project).not_to be_valid
    end
  end

  describe "share_token" do
    it "is generated automatically on create" do
      project = create(:project)
      expect(project.share_token).to be_present
    end

    it "generates unique tokens for each project" do
      projects = create_list(:project, 3)
      tokens = projects.map(&:share_token)
      expect(tokens.uniq.length).to eq(3)
    end

    it "does not overwrite an existing token" do
      project = create(:project)
      original_token = project.share_token
      project.update!(name: "New Name")
      expect(project.reload.share_token).to eq(original_token)
    end
  end
end
