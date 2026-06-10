module Admin
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action :authorize_admin!

    skip_after_action :verify_policy_scoped

    private

    def authorize_admin!
      authorize :admin, :access?
    end
  end
end
