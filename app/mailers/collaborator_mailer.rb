class CollaboratorMailer < ApplicationMailer
  def magic_link(collaborator, token, project)
    @collaborator = collaborator
    @token        = token
    @project      = project
    @login_url    = verify_portal_session_url(
      share_token: project.share_token,
      token: token.token
    )

    mail(to: collaborator.email, subject: "Your login link for userstories.io")
  end
end
