class DashboardController < ApplicationController
  before_action :authenticate_user!

  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  def index
    @pending_submissions = policy_scope(Submission).pending_review.recent
                                                   .includes(:collaborator, project: :user)
                                                   .page(params[:page]).per(50)
  end
end
