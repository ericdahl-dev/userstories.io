require "rails_helper"

RSpec.describe CloneGithubRepoJob, type: :job do
  let(:project) { create(:project, user: create(:user, github_token: "token")) }
  let(:clone_service) { instance_double(GithubRepoClone, ensure!: true) }

  before do
    allow(GithubRepoClone).to receive(:new).with(project).and_return(clone_service)
  end

  it "ensures the repo clone exists" do
    described_class.perform_now(project)

    expect(clone_service).to have_received(:ensure!)
  end

  it "does not raise when cloning fails" do
    allow(clone_service).to receive(:ensure!).and_raise(StandardError, "git missing")

    expect { described_class.perform_now(project) }.not_to raise_error
  end
end
