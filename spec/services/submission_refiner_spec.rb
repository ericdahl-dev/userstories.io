require "rails_helper"

RSpec.describe SubmissionRefiner do
  let(:user) { create(:user, github_token: "token") }
  let(:project) { create(:project, user: user) }
  let(:submission) { create(:submission, project: project, title: "Dark mode", body: "Add dark mode toggle") }
  let(:llm) { instance_double(LlmClient) }
  let(:prior) { create(:submission, project: project, title: "Theme support", status: "accepted") }

  subject(:refiner) { described_class.new(submission, llm_client: llm) }

  before do
    prior
    allow(GithubClient).to receive(:new).and_return(
      instance_double(
        GithubClient,
        file_content: "class ApplicationController\nend",
        directory_paths: [ "app/controllers/application_controller.rb" ]
      )
    )
  end

  describe "#refine!" do
    let(:assistant_markdown) do
      <<~MD
        ## Refined story
        **Title:** Dark mode toggle in portal
        **Details:** As a collaborator, I want a theme toggle.

        ## Similar stories on this project
        - _Theme support_ (accepted) — related UI work

        ## Already implemented?
        - Maybe — theme toggle exists in shared partial

        ## Let's work it out
        - Should this apply to developer views too?
      MD
    end

    it "stores assistant message and refined fields" do
      allow(llm).to receive(:chat).and_return(assistant_markdown)

      expect { refiner.refine! }.to change { submission.refinement_messages.count }.by(1)

      submission.reload
      expect(submission.refined_title).to eq("Dark mode toggle in portal")
      expect(submission.refined_body).to include("theme toggle")
    end

    it "includes repo source and prior submission in user prompt" do
      captured_messages = nil
      allow(llm).to receive(:chat) do |messages:, **|
        captured_messages = messages
        assistant_markdown
      end

      refiner.refine!

      user_prompt = captured_messages.find { |m| m[:role] == "user" }[:content]
      expect(user_prompt).to include("app/controllers/application_controller.rb")
      expect(user_prompt).to include(prior.title)
      expect(user_prompt).to include("Dark mode")
    end
  end
end
