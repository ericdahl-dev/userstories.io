require "rails_helper"

RSpec.describe CollaboratorMailer, type: :mailer do
  describe "#magic_link" do
    let(:collaborator) { create(:collaborator, name: "Alex", email: "alex@example.com") }
    let(:project) { create(:project, name: "Portal Alpha") }
    let(:token) { create(:magic_token, collaborator: collaborator) }

    subject(:mail) { described_class.magic_link(collaborator, token, project) }

    it "delivers to the collaborator" do
      expect(mail.to).to eq([ "alex@example.com" ])
      expect(mail.subject).to eq("Your login link for userstories.io")
    end

    it "includes the project name and one-time login URL" do
      body = mail.text_part.body.to_s

      expect(body).to include("Alex")
      expect(body).to include("Portal Alpha")
      expect(body).to include(token.token)
      expect(body).to include(verify_portal_session_url(share_token: project.share_token, token: token.token))
    end
  end
end
