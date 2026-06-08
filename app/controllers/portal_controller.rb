class PortalController < ApplicationController
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  before_action :find_project

  def show
  end

  private

  def current_collaborator
    return unless session[:collaborator_id]

    @current_collaborator ||= Collaborator.find_by(id: session[:collaborator_id])
  end
  helper_method :current_collaborator

  def find_project
    @project = Project.find_by!(share_token: params[:share_token])
  rescue ActiveRecord::RecordNotFound
    render plain: "This link is no longer valid.", status: :not_found
  end
end
