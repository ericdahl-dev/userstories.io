class PwaController < ApplicationController
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  def manifest
    render formats: :json, content_type: "application/manifest+json"
  end
end
