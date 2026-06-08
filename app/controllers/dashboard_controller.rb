class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @pending_submissions = policy_scope(Submission).pending_review.recent
                                                   .includes(:collaborator, project: :user)
  end
end
