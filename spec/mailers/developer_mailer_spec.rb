require "rails_helper"

RSpec.describe DeveloperMailer, type: :mailer do
  describe "#refinement_finalized" do
    let(:developer) { create(:user, email: "dev@example.com") }
    let(:project) { create(:project, user: developer, name: "Portal Alpha") }
    let(:collaborator) { create(:collaborator, name: "Alex") }
    let(:submission) do
      create(
        :submission,
        project: project,
        collaborator: collaborator,
        title: "Add dark mode",
        refined_title: "Add system-aware dark mode toggle",
        refined_body: "As a user, I want a dark mode toggle that respects system preferences.",
        refinement_locked_at: Time.current
      )
    end

    before do
      create(
        :refinement_message,
        submission: submission,
        role: "assistant",
        body: "## Already implemented?\nMaybe — theme toggle exists in header."
      )
    end

    subject(:mail) { described_class.refinement_finalized(submission) }

    it "delivers to the project owner" do
      expect(mail.to).to eq([ "dev@example.com" ])
      expect(mail.subject).to eq("Story ready for review: Add system-aware dark mode toggle")
    end

    it "includes original and refined titles, collaborator, and review link" do
      body = mail.text_part.body.to_s

      expect(body).to include("Alex")
      expect(body).to include("Portal Alpha")
      expect(body).to include("Add dark mode")
      expect(body).to include("Add system-aware dark mode toggle")
      expect(body).to include(project_submission_url(project, submission))
      expect(body).to include("Already implemented?")
    end
  end
end
