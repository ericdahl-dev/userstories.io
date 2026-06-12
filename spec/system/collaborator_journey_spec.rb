# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Collaborator journey", type: :system, js: true do
  let(:project) { create(:project, name: "Horizon App") }
  let(:email) { "maya@example.com" }

  before do
    setup_cuprite!
    stub_refinement_llm!
  end

  it "visits portal, signs in via magic link, submits a story, and sees it pending" do
    visit portal_path(share_token: project.share_token)

    expect(page).to have_content("Sign in to continue")
    fill_in "Email address", with: email
    click_button "Send login link"

    expect(page).to have_content("Check your email for a login link")

    visit_magic_link_from_email!

    expect(page).to have_content("Your submissions")
    click_link "New submission"

    fill_in "Title", with: "Add dark mode to the dashboard"
    fill_in "Details", with: "As a user who works late, I want a dark theme option."
    click_button "Submit story"

    expect(page).to have_content("Story received")
    expect(page).to have_content("refine it before review")
    expect(page).to have_content("Chat with the assistant")

    click_link "All submissions"

    expect(page).to have_content("Add dark mode to the dashboard")
    expect(page).to have_css(".badge-pending", text: "PENDING")

    submission = Submission.last
    expect(submission).to have_attributes(
      status: "pending",
      collaborator: Collaborator.find_by!(email: email),
      project: project
    )
  end
end
