class Portal::SubmissionsController < PortalController
  before_action :require_collaborator

  def index
    @submissions = current_collaborator.submissions
                                       .where(project: @project)
                                       .visible_to_collaborator
                                       .recent

    sync_github_statuses(@submissions)
    @refresh_github_status = @submissions.any?(&:github_status_refresh_needed?)
  end

  def new
    @submission = Submission.new
  end

  def create
    @submission = current_collaborator.submissions.build(submission_params.merge(project: @project))

    if @submission.save
      PostHog.capture(
        distinct_id: current_collaborator.email,
        event: "submission_created",
        properties: { project_id: @project.id, submission_id: @submission.id }
      )
      redirect_to portal_submission_refine_path(share_token: @project.share_token, id: @submission),
                  notice: "Story received — let's refine it before review."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def require_collaborator
    unless current_collaborator
      redirect_to new_portal_session_path(share_token: @project.share_token),
                  alert: "Please log in to continue."
    end
  end

  def submission_params
    params.require(:submission).permit(:title, :body)
  end

  def sync_github_statuses(submissions)
    submissions.select(&:github_sync_due?).each do |submission|
      if submission.github_issue_summary.blank?
        SubmissionGithubSync.new(submission).sync!
      else
        SyncSubmissionGithubStatusJob.perform_later(submission)
      end
    end
  end
end
