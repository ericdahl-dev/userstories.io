class Portal::SessionsController < PortalController
  def new
  end

  def create
    collaborator = Collaborator.for_login(email: params[:email])

    token = collaborator.magic_tokens.create!
    CollaboratorMailer.magic_link(collaborator, token, @project).deliver_later

    redirect_to portal_path(share_token: @project.share_token),
                notice: "Check your email for a login link."
  rescue ActiveRecord::RecordInvalid
    flash.now[:alert] = "Please enter a valid email address."
    render :new, status: :unprocessable_content
  end

  def verify
    token = MagicToken.valid.find_by(token: params[:token])

    if token.nil?
      redirect_to portal_path(share_token: @project.share_token),
                  alert: "This login link has expired or already been used."
      return
    end

    collaborator = token.collaborator
    token.consume!
    reset_session
    session[:collaborator_id] = token.collaborator_id
    session[:collaborator_authenticated_at] = Time.current.iso8601

    PostHog.identify(
      distinct_id: collaborator.email,
      properties: { name: collaborator.name, email: collaborator.email }
    )
    PostHog.capture(
      distinct_id: collaborator.email,
      event: "collaborator_signed_in",
      properties: { project_id: @project.id }
    )

    redirect_to portal_submissions_path(share_token: @project.share_token)
  end

  def destroy
    clear_collaborator_session!

    redirect_to portal_path(share_token: @project.share_token),
                notice: "Signed out."
  end
end
