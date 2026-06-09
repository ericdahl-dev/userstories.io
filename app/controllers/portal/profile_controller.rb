class Portal::ProfileController < PortalController
  before_action :require_collaborator

  def edit
  end

  def update
    if current_collaborator.update(profile_params)
      redirect_to portal_submissions_path(share_token: @project.share_token),
                  notice: "Display name updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def require_collaborator
    unless current_collaborator
      redirect_to new_portal_session_path(share_token: @project.share_token),
                  alert: "Please log in to continue."
    end
  end

  def profile_params
    params.require(:collaborator).permit(:name)
  end
end
