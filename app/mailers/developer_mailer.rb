class DeveloperMailer < ApplicationMailer
  def refinement_finalized(submission)
    @submission = submission
    @project = submission.project
    @developer = @project.user
    @collaborator = submission.collaborator
    @submission_url = project_submission_url(@project, submission)
    @assistant_summary = submission.refinement_assistant_summary

    mail(
      to: @developer.email,
      subject: "Story ready for review: #{submission.effective_title}"
    )
  end
end
