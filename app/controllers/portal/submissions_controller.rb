class Portal::SubmissionsController < ApplicationController
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  before_action :find_project
  before_action :require_collaborator

  def index
    @submissions = current_collaborator.submissions
                                       .where(project: @project)
                                       .recent
  end

  def new
    @submission = Submission.new
  end

  def create
    @submission = current_collaborator.submissions.build(submission_params.merge(project: @project))

    if @submission.save
      redirect_to portal_submissions_path(share_token: @project.share_token),
                  notice: "Your story has been submitted!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def find_project
    @project = Project.find_by!(share_token: params[:share_token])
  rescue ActiveRecord::RecordNotFound
    render plain: "This link is no longer valid.", status: :not_found
  end

  def require_collaborator
    unless current_collaborator
      redirect_to new_portal_session_path(share_token: @project.share_token),
                  alert: "Please log in to continue."
    end
  end

  def submission_params
    params.require(:submission).permit(:title, :body)
  end
end
