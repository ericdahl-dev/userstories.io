require "rails_helper"

RSpec.describe GithubRepoClone do
  let(:user) { create(:user, github_token: "gho_testtoken") }
  let(:project) { create(:project, user: user, github_repo: "owner/repo") }

  subject(:clone_service) { described_class.new(project) }

  after do
    described_class.git_runner = nil
    FileUtils.rm_rf(described_class.base_dir)
  end

  describe "#ensure!" do
    it "clones the repo and marks status succeeded" do
      described_class.git_runner = lambda do |url, destination|
        FileUtils.mkdir_p(destination)
        File.write(destination.join("README.md"), "# Repo")
        expect(url).to include("x-access-token:gho_testtoken@github.com/owner/repo.git")
        true
      end

      expect(clone_service.ensure!).to be(true)

      project.reload
      expect(project.github_clone_status).to eq("succeeded")
      expect(project.github_clone_refreshed_at).to be_present
      expect(clone_service.clone_path).to eq(clone_service.send(:clone_dir).to_s)
    end

    it "returns true without re-cloning when cache is fresh" do
      described_class.git_runner = lambda do |_url, destination|
        FileUtils.mkdir_p(destination)
        true
      end

      clone_service.ensure!
      project.update!(github_clone_refreshed_at: 1.hour.ago)

      expect(described_class).not_to receive(:default_git_clone)
      expect(clone_service.ensure!).to be(true)
    end

    it "re-clones when cache is stale" do
      calls = 0
      described_class.git_runner = lambda do |_url, destination|
        calls += 1
        FileUtils.mkdir_p(destination)
        true
      end

      clone_service.ensure!
      project.update!(github_clone_refreshed_at: 25.hours.ago)

      expect(clone_service.ensure!).to be(true)
      expect(calls).to eq(2)
    end

    it "marks failed and returns false when clone fails" do
      described_class.git_runner = ->(_url, _destination) { false }

      expect(clone_service.ensure!).to be(false)

      project.reload
      expect(project.github_clone_status).to eq("failed")
      expect(clone_service.clone_path).to be_nil
    end

    it "returns false when repo or token is missing" do
      user.update_column(:github_token, nil)

      expect(clone_service.ensure!).to be(false)
    end
  end

  describe "#invalidate!" do
    it "removes the clone directory and clears status" do
      described_class.git_runner = lambda do |_url, destination|
        FileUtils.mkdir_p(destination)
        File.write(destination.join("README.md"), "old")
        true
      end

      clone_service.ensure!
      clone_service.invalidate!

      project.reload
      expect(project.github_clone_status).to be_nil
      expect(project.github_clone_refreshed_at).to be_nil
      expect(clone_service.send(:clone_dir)).not_to exist
    end
  end

  describe "#refresh!" do
    it "invalidates and re-clones" do
      calls = 0
      described_class.git_runner = lambda do |_url, destination|
        calls += 1
        FileUtils.mkdir_p(destination)
        File.write(destination.join("README.md"), "v#{calls}")
        true
      end

      clone_service.ensure!
      clone_service.refresh!

      expect(calls).to eq(2)
      expect(File.read(clone_service.send(:clone_dir).join("README.md"))).to eq("v2")
    end
  end
end
