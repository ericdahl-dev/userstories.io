class SubmissionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project
  before_action :set_submission, only: %i[show accept dismiss ship]

  skip_after_action :verify_authorized, only: :index

  def index
    @submissions = policy_scope(Submission).where(project: @project).recent
  end

  def show
    authorize @submission
  end

  def accept
    authorize @submission

    @submission.with_lock do
      raise Submission::InvalidTransition unless @submission.acceptable?

      result = GithubIssueCreator.new(@submission).create!
      @submission.accept!(
        github_issue_number: result[:number],
        github_issue_url: result[:url]
      )
    end

    redirect_to project_submission_path(@project, @submission),
                notice: "Submission accepted and GitHub issue created."
  rescue Submission::InvalidTransition
    redirect_to project_submission_path(@project, @submission),
                alert: "This submission has already been accepted or is no longer pending."
  rescue GithubIssueCreator::Error => e
    redirect_to project_submission_path(@project, @submission),
                alert: "GitHub issue creation failed: #{e.message}"
  end

  def dismiss
    authorize @submission
    @submission.dismiss!
    redirect_to project_submissions_path(@project), notice: "Submission dismissed."
  end

  def ship
    authorize @submission
    @submission.ship!
    redirect_to project_submission_path(@project, @submission), notice: "Marked as shipped."
  end

  private

  def set_project
    @project = current_user.projects.find(params[:project_id])
  end

  def set_submission
    @submission = @project.submissions.find(params[:id])
  end
end
