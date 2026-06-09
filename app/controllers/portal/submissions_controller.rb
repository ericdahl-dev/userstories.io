class Portal::SubmissionsController < PortalController
  before_action :require_collaborator

  def index
    @submissions = current_collaborator.submissions
                                       .where(project: @project)
                                       .recent

    enqueue_github_status_syncs(@submissions)
  end

  def new
    @submission = Submission.new
  end

  def create
    @submission = current_collaborator.submissions.build(submission_params.merge(project: @project))

    if @submission.save
      RefineSubmissionJob.perform_later(@submission) if RefinementQuotaGuard.allowed?(@submission)
      redirect_to portal_submission_refine_path(share_token: @project.share_token, id: @submission)
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

  def enqueue_github_status_syncs(submissions)
    submissions.select(&:github_sync_due?).each do |submission|
      SyncSubmissionGithubStatusJob.perform_later(submission)
    end
  end
end
