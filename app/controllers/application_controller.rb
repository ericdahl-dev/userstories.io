class ApplicationController < ActionController::Base
  include Pundit::Authorization

  allow_browser versions: :modern
  stale_when_importmap_changes

  after_action :verify_authorized, unless: :devise_controller?
  after_action :verify_policy_scoped, only: :index, unless: :devise_controller?

  rescue_from Pundit::NotAuthorizedError, with: :handle_not_authorized

  private

  def current_collaborator
    return unless session[:collaborator_id]

    @current_collaborator ||= Collaborator.find_by(id: session[:collaborator_id])
  end
  helper_method :current_collaborator

  def after_sign_in_path_for(_resource)
    dashboard_path
  end

  def handle_not_authorized
    redirect_back_or_to root_path, alert: "You are not authorized to perform this action."
  end
end
