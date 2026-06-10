# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Developer triage", type: :system, js: true do
  let(:user) { create(:user) }
  let(:project) { create(:project, user: user, name: "Horizon App") }
  let(:collaborator) { create(:collaborator, name: "Maya R.") }
  let!(:submission) do
    create(
      :submission,
      project: project,
      collaborator: collaborator,
      title: "Add dark mode to the dashboard",
      body: "As a user who works late, I want a dark theme option.",
      status: "pending"
    )
  end

  before do
    setup_cuprite!
    login_as user, scope: :user

    allow(GithubIssueCreator).to receive(:new).and_return(
      instance_double(
        GithubIssueCreator,
        create!: { number: 42, url: "https://github.com/owner/repo/issues/42" }
      )
    )
  end

  it "signs in, accepts a pending submission, and shows accepted with GitHub issue" do
    visit dashboard_path

    expect(page).to have_content("Triage inbox")
    click_link "Add dark mode to the dashboard"

    expect(page).to have_button("Accept")
    click_button "Accept"

    expect(page).to have_content("Submission accepted and GitHub issue created")
    expect(page).to have_css(".badge-accepted", text: "ACCEPTED")
    expect(page).to have_link("GitHub issue #42", href: "https://github.com/owner/repo/issues/42")

    expect(submission.reload).to have_attributes(
      status: "accepted",
      github_issue_number: 42,
      github_issue_url: "https://github.com/owner/repo/issues/42"
    )
  end
end
