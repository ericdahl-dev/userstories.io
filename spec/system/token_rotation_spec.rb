# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Token rotation", type: :system, js: true do
  let(:user) { create(:user) }
  let(:project) { create(:project, user: user, name: "Horizon App") }
  let!(:old_share_token) { project.share_token }

  before do
    setup_cuprite!
    login_as user, scope: :user
  end

  it "rotates the share token and invalidates the old portal link" do
    visit project_path(project)

    expect(page).to have_content(old_share_token)

    click_button "Rotate"

    expect(page).to have_current_path(project_path(project))
    expect(project.reload.share_token).not_to eq(old_share_token)

    visit portal_path(share_token: old_share_token)

    expect(page).to have_content("This link is no longer valid.")
  end
end
