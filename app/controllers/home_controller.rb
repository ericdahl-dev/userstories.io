class HomeController < ApplicationController
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  content_security_policy only: :index do |policy|
    origin = umami_analytics_origin
    next unless origin

    policy.script_src :self, :unsafe_inline, origin
    policy.connect_src :self, origin
  end

  def index
  end
end
