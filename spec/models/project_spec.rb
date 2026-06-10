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

  describe "#rotate_share_token!" do
    it "changes the share_token" do
      project = create(:project)
      original = project.share_token
      project.rotate_share_token!
      expect(project.reload.share_token).not_to eq(original)
    end

    it "persists the new token" do
      project = create(:project)
      project.rotate_share_token!
      expect(project.share_token).to eq(project.reload.share_token)
    end
  end

  describe "#refresh_github_clone!" do
    it "enqueues a clone job" do
      project = create(:project)

      expect {
        project.refresh_github_clone!
      }.to have_enqueued_job(CloneGithubRepoJob).with(project)
    end
  end

  describe "github repo changes" do
    it "invalidates the clone and enqueues a fresh clone" do
      project = create(:project, github_repo: "owner/old-repo")
      clone_service = instance_double(GithubRepoClone, invalidate!: true)

      allow(GithubRepoClone).to receive(:new).with(project).and_return(clone_service)

      expect {
        project.update!(github_repo: "owner/new-repo")
      }.to have_enqueued_job(CloneGithubRepoJob).with(project)

      expect(clone_service).to have_received(:invalidate!)
    end
  end

  describe "creation" do
    it "enqueues a clone job" do
      expect {
        create(:project)
      }.to have_enqueued_job(CloneGithubRepoJob)
    end
  end

  describe ".generate_share_token" do
    it "returns a url-safe base64 string of correct length" do
      token = Project.generate_share_token
      expect(token).to match(/\A[A-Za-z0-9\-_]+\z/)
      expect(token.length).to be >= 24
    end

    it "generates unique values" do
      expect(Project.generate_share_token).not_to eq(Project.generate_share_token)
    end
  end
end
