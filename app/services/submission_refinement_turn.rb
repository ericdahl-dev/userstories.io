class SubmissionRefinementTurn
  Error = Class.new(StandardError)

  BASE_SYSTEM_PROMPT = <<~PROMPT.freeze
    You help collaborators refine user stories for a software project before developer triage.
    Ground every refinement in the supplied repository source files and project submission history.
    Cite similar stories by title and status — never invent submission IDs.
    Say a feature is already implemented only with evidence from shipped stories, closed GitHub issues, or code references.
    Be helpful and concise. This is a short refinement pass, not an open-ended workshop.
    Update the refined story when appropriate and keep the same markdown section structure when you revise it.
  PROMPT

  WRAP_UP_PROMPT = <<~PROMPT.freeze
    This is the collaborator's final allowed reply. Wrap up — no new questions.
    Summarize the final refined story and confirm they can submit for review.
    Include ## Refined story with **Title:** and **Details:** sections.
  PROMPT

  def initialize(submission, llm_client: LlmClient.new)
    @submission = submission
    @llm_client = llm_client
  end

  def run!
    content = @llm_client.chat(
      messages: [
        { role: "system", content: system_prompt },
        { role: "user", content: user_prompt }
      ],
      user: @submission.project.user
    )

    persist_assistant_turn!(content)
  end

  def system_prompt
    prompt = BASE_SYSTEM_PROMPT.dup
    prompt << "\n\n" << WRAP_UP_PROMPT if @submission.refinement_replies_remaining.zero?
    prompt
  end

  def user_prompt
    <<~PROMPT
      Project: #{@submission.project.name}
      Replies remaining after this turn: #{@submission.refinement_replies_remaining}

      Repository source bundle:
      #{repo_context}

      Project submission history:
      #{history_context}

      Conversation so far:
      #{conversation_thread}
    PROMPT
  end

  private

  def repo_context
    GithubRepoContext.new(@submission.project).to_prompt
  end

  def history_context
    SubmissionHistoryContext.new(@submission).to_prompt
  end

  def conversation_thread
    @submission.refinement_messages.chronological.map do |message|
      role = message.collaborator? ? "Collaborator" : "Assistant"
      "#{role}:\n#{message.body}"
    end.join("\n\n")
  end

  def persist_assistant_turn!(content)
    parsed = RefinementStoryParser.parse(content)

    @submission.transaction do
      @submission.refinement_messages.create!(role: "assistant", body: content)

      if parsed
        @submission.update!(
          refined_title: parsed[:title],
          refined_body: parsed[:body],
          refined_at: Time.current
        )
      end
    end
  end
end
