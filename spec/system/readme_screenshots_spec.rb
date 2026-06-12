# frozen_string_literal: true

# Generates README screenshots into docs/screenshots/.
# Run: bundle exec rspec spec/system/readme_screenshots_spec.rb

require "rails_helper"

RSpec.describe "README screenshots", :screenshot, type: :system, js: true do
  include Warden::Test::Helpers

  OUTPUT = Rails.root.join("docs/screenshots")

  before do
    driven_by :cuprite
    FileUtils.mkdir_p(OUTPUT)
    page.driver.resize(*[ 1440, 900 ])
  end

  after { Warden.test_reset! }

  def capture(name)
    path = OUTPUT.join("#{name}.png")
    page.save_screenshot(path.to_s, full: false)
    puts "  ✓ #{path.relative_path_from(Rails.root)}"
  end

  def use_light_theme!
    page.execute_script(<<~JS)
      localStorage.setItem('theme', 'light');
      document.documentElement.classList.remove('dark');
    JS
  end

  def sign_in_collaborator!(project, collaborator)
    token = collaborator.magic_tokens.create!(expires_at: 15.minutes.from_now)
    visit verify_portal_session_path(share_token: project.share_token, token: token.token)
  end

  it "captures product screenshots" do
    user = create(:user, email: "alex@example.com")
    project = create(:project,
      user: user,
      name: "Horizon App",
      github_repo: "acme/horizon-app")

    maya = create(:collaborator, name: "Maya R.", email: "maya@example.com")
    tom = create(:collaborator, name: "Tom B.", email: "tom@example.com")
    priya = create(:collaborator, name: "Priya K.", email: "priya@example.com")

    dark_mode = create(:submission,
      project: project,
      collaborator: maya,
      title: "Add dark mode to the dashboard",
      body: "As a user who works late, I want a dark theme option on the dashboard, so that I can reduce eye strain during evening sessions.",
      status: "pending")

    create(:submission,
      project: project,
      collaborator: tom,
      title: "Export submissions as CSV",
      body: "As a project admin, I want to download all submissions as a CSV file, so that I can share progress with stakeholders offline.",
      status: "pending")

    create(:submission,
      project: project,
      collaborator: priya,
      title: "Show estimated delivery date on orders",
      body: "As a customer, I want to see an estimated delivery date on my order confirmation, so that I know when to expect my package.",
      status: "accepted",
      github_issue_number: 142,
      github_issue_url: "https://github.com/acme/horizon-app/issues/142")

    create(:refinement_message,
      submission: dark_mode,
      role: "assistant",
      body: <<~MD)
        ## Refined story
        **Title:** Add dark mode to the dashboard
        **Details:** Provide a user-toggleable dark theme across dashboard views, persisting the preference per account.

        ## Similar stories on this project
        - _Export submissions as CSV_ (pending, Jun 8) — another UX improvement request

        ## Already implemented?
        - Maybe — theme tokens exist in Tailwind config but no toggle is wired up yet

        ## Let's work it out
        - Should dark mode follow the system preference, or always require a manual toggle?
        - Do you need it on mobile views as well as desktop?
      MD

    create(:refinement_message,
      submission: dark_mode,
      role: "collaborator",
      body: "System preference by default, with a manual override in settings. Yes, mobile too.")

    visit root_path
    use_light_theme!
    capture "landing-page"

    login_as user, scope: :user

    visit dashboard_path
    use_light_theme!
    expect(page).to have_content("Triage inbox")
    capture "triage-inbox"

    visit project_submission_path(project, dark_mode)
    use_light_theme!
    expect(page).to have_button("Accept")
    capture "submission-review"

    logout(:user)

    sign_in_collaborator!(project, maya)
    visit portal_submissions_path(share_token: project.share_token)
    use_light_theme!
    expect(page).to have_content("Your submissions")
    capture "collaborator-portal"

    visit portal_submission_refine_path(share_token: project.share_token, id: dark_mode)
    use_light_theme!
    expect(page).to have_content("Chat with the assistant")
    capture "refinement-chat"
  end
end
