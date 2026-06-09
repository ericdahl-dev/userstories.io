class Portal::RefinementsController < PortalController
  before_action :require_collaborator
  before_action :set_submission

  def show
    @messages = @submission.refinement_messages.chronological
  end

  def create_message
    if @submission.refinement_locked?
      redirect_to portal_submission_refine_path(share_token: @project.share_token, id: @submission),
                  alert: "Refinement is locked."
      return
    end

    if @submission.refinement_at_cap?
      @messages = @submission.refinement_messages.chronological
      flash.now[:alert] = "Refinement complete — submit for review when you're ready."
      return render :show, status: :unprocessable_entity
    end

    if @submission.refinement_processing?
      redirect_to portal_submission_refine_path(share_token: @project.share_token, id: @submission),
                  alert: "Please wait for the assistant to finish responding."
      return
    end

    body = message_params[:body].to_s.strip
    if body.blank?
      @messages = @submission.refinement_messages.chronological
      flash.now[:alert] = "Message can't be blank."
      return render :show, status: :unprocessable_entity
    end

    @submission.refinement_messages.create!(role: "collaborator", body: body)
    @submission.update!(refinement_status: "processing")
    RefinementTurnJob.perform_later(@submission)

    redirect_to portal_submission_refine_path(share_token: @project.share_token, id: @submission)
  end

  def finalize
    @submission.lock_refinement!
    redirect_to portal_submissions_path(share_token: @project.share_token),
                notice: "Your story has been submitted for review!"
  end

  private

  def require_collaborator
    unless current_collaborator
      redirect_to new_portal_session_path(share_token: @project.share_token),
                  alert: "Please log in to continue."
    end
  end

  def set_submission
    @submission = current_collaborator.submissions.find_by!(id: params[:id], project: @project)
  rescue ActiveRecord::RecordNotFound
    redirect_to portal_submissions_path(share_token: @project.share_token),
                alert: "Submission not found."
  end

  def message_params
    params.require(:refinement_message).permit(:body)
  end
end
