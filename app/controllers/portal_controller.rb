class PortalController < ApplicationController
  COLLABORATOR_SESSION_TTL = 30.days

  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  before_action :find_project

  def show
  end

  private

  def current_collaborator
    return unless session[:collaborator_id]
    return unless collaborator_session_active?

    @current_collaborator ||= Collaborator.find_by(id: session[:collaborator_id])
  end
  helper_method :current_collaborator

  def collaborator_session_active?
    authenticated_at = session[:collaborator_authenticated_at]
    if authenticated_at.blank?
      clear_collaborator_session!
      return false
    end

    if Time.zone.parse(authenticated_at) < COLLABORATOR_SESSION_TTL.ago
      clear_collaborator_session!
      return false
    end

    true
  end

  def clear_collaborator_session!
    session.delete(:collaborator_id)
    session.delete(:collaborator_authenticated_at)
  end

  def find_project
    @project = Project.find_by!(share_token: params[:share_token])
  rescue ActiveRecord::RecordNotFound
    render plain: "This link is no longer valid.", status: :not_found
  end
end
