require "rails_helper"

RSpec.describe "Security: filter_parameters", type: :request do
  it "filters token from Rails logs" do
    expect(Rails.application.config.filter_parameters).to include(:token)
  end

  it "filters share_token from Rails logs" do
    expect(Rails.application.config.filter_parameters).to include(:share_token)
  end

  it "filters email from Rails logs" do
    expect(Rails.application.config.filter_parameters).to include(:email)
  end
end
