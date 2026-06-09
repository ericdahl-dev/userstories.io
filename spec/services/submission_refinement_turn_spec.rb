require "rails_helper"

RSpec.describe SubmissionRefinementTurn do
  let(:submission) { create(:submission) }
  let(:llm) { instance_double(LlmClient) }

  subject(:turn) { described_class.new(submission, llm_client: llm) }

  before do
    create(:refinement_message, submission: submission, role: "assistant", body: "Initial refinement")
    create(:refinement_message, submission: submission, role: "collaborator", body: "First reply")
    create(:refinement_message, submission: submission, role: "collaborator", body: "Second reply")

    allow(GithubClient).to receive(:new).and_return(
      instance_double(GithubClient, file_content: nil, directory_paths: [])
    )
  end

  it "builds the user prompt when repository source is present" do
    user = create(:user, github_token: "token")
    project = create(:project, user: user, github_repo: "owner/repo")
    submission = create(:submission, project: project)
    create(:refinement_message, submission: submission, role: "assistant", body: "Initial refinement")
    create(:refinement_message, submission: submission, role: "collaborator", body: "Follow-up")

    turn = described_class.new(submission, llm_client: llm)
    allow(GithubClient).to receive(:new).and_call_original
    fake_octokit = instance_double(Octokit::Client)
    allow(Octokit::Client).to receive(:new).with(access_token: "token").and_return(fake_octokit)
    allow(fake_octokit).to receive(:contents).with("owner/repo", path: anything).and_raise(Octokit::NotFound)
    allow(fake_octokit).to receive(:contents).with("owner/repo", path: "README.md").and_return(
      double(type: "file", size: 100, content: Base64.encode64("class App\nend"))
    )

    expect { turn.send(:user_prompt) }.not_to raise_error
    expect(turn.send(:user_prompt)).to include("class App")
  end

  it "uses wrap-up instructions when no replies remain" do
    captured_messages = nil
    allow(llm).to receive(:chat) do |messages:|
      captured_messages = messages
      "## Refined story\n**Title:** Final\n**Details:** Done"
    end

    turn.run!

    system_prompt = captured_messages.find { |m| m[:role] == "system" }[:content]
    expect(system_prompt).to include("final allowed reply")
    expect(system_prompt).to include("Wrap up")
  end
end
