require "rails_helper"

RSpec.describe "Dark mode", type: :system, js: true do
  include Warden::Test::Helpers

  let(:user) { create(:user) }

  before do
    driven_by :cuprite
    login_as user, scope: :user
  end

  after { Warden.test_reset! }

  it "toggles the dark class on the document root" do
    visit dashboard_path
    page.execute_script("localStorage.setItem('theme', 'light'); document.documentElement.classList.remove('dark');")

    expect(page).to have_css("html:not(.dark)")

    find("[data-theme-toggle]").click

    expect(page).to have_css("html.dark")

    visit dashboard_path

    expect(page).to have_css("html.dark")
  end
end
