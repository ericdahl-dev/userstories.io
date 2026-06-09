class RefinementChatBroadcaster
  def initialize(submission)
    @submission = submission
    @project = submission.project
  end

  def append_message!(message)
    Turbo::StreamsChannel.broadcast_append_to(
      @submission,
      target: "refinement_messages",
      partial: "portal/refinements/message",
      locals: { message: message }
    )
  end

  def show_typing_indicator!
    Turbo::StreamsChannel.broadcast_append_to(
      @submission,
      target: "refinement_messages",
      partial: "portal/refinements/typing_indicator",
      locals: {}
    )
  end

  def hide_typing_indicator!
    Turbo::StreamsChannel.broadcast_remove_to(@submission, target: "refinement_typing_indicator")
  end

  def refresh_composer!
    Turbo::StreamsChannel.broadcast_update_to(
      @submission,
      target: "refinement_composer",
      partial: "portal/refinements/composer",
      locals: { submission: @submission.reload, project: @project }
    )
  end

  def refresh_reply_counter!
    Turbo::StreamsChannel.broadcast_update_to(
      @submission,
      target: "refinement_reply_counter",
      partial: "portal/refinements/reply_counter",
      locals: { submission: @submission.reload }
    )
  end

  def show_failure_alert!
    Turbo::StreamsChannel.broadcast_append_to(
      @submission,
      target: "refinement_messages",
      partial: "portal/refinements/failure_alert",
      locals: {}
    )
  end

  def complete_assistant_reply!(message)
    hide_typing_indicator!
    append_message!(message)
    refresh_composer!
    refresh_reply_counter!
  end

  def processing_started!
    show_typing_indicator!
    refresh_composer!
  end

  def processing_failed!
    hide_typing_indicator!
    show_failure_alert! if @submission.refinement_messages.where(role: "assistant").none?
    refresh_composer!
  end
end
