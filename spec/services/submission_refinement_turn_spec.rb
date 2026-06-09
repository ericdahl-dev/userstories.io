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
