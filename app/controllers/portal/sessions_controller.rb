class Portal::SessionsController < ApplicationController
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  before_action :find_project

  def new
  end

  def create
    collaborator = Collaborator.for_login(email: params[:email])

    token = collaborator.magic_tokens.create!
    CollaboratorMailer.magic_link(collaborator, token, @project).deliver_later

    redirect_to portal_path(share_token: @project.share_token),
                notice: "Check your email for a login link."
  end

  def verify
    token = MagicToken.valid.find_by(token: params[:token])

    if token.nil?
      redirect_to portal_path(share_token: @project.share_token),
                  alert: "This login link has expired or already been used."
      return
    end

    token.consume!
    session[:collaborator_id] = token.collaborator_id

    redirect_to portal_submissions_path(share_token: @project.share_token)
  end

  private

  def find_project
    @project = Project.find_by!(share_token: params[:share_token])
  rescue ActiveRecord::RecordNotFound
    render plain: "This link is no longer valid.", status: :not_found
  end
end
