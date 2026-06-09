class SubmissionRefiner
  Error = Class.new(StandardError)

  SYSTEM_PROMPT = <<~PROMPT.freeze
    You help collaborators refine user stories for a software project before developer triage.
    Ground every refinement in the supplied repository source files and project submission history.
    Cite similar stories by title and status — never invent submission IDs.
    Say a feature is already implemented only with evidence from shipped stories, closed GitHub issues, or code references.
    Be helpful and concise. This is a short refinement pass, not an open-ended workshop.
    Respond in markdown with exactly these sections:

    ## Refined story
    **Title:** ...
    **Details:** ...

    ## Similar stories on this project
    - _Story title_ (status, date) — how it relates
    - or "None found"

    ## Already implemented?
    - Yes/No/Maybe — evidence from code and/or shipped stories

    ## Let's work it out
    - 1–3 clarifying questions or suggestions to sharpen the ask
  PROMPT

  def initialize(submission, llm_client: LlmClient.new)
    @submission = submission
    @llm_client = llm_client
  end

  def refine!
    content = @llm_client.chat(
      messages: [
        { role: "system", content: SYSTEM_PROMPT },
        { role: "user", content: user_prompt }
      ]
    )

    persist_assistant_turn!(content)
  end

  def user_prompt
    <<~PROMPT
      Project: #{@submission.project.name}

      Original story:
      Title: #{@submission.title}
      Details:
      #{@submission.body}

      Repository source bundle:
      #{repo_context}

      Project submission history:
      #{history_context}
    PROMPT
  end

  private

  def repo_context
    GithubRepoContext.new(@submission.project).to_prompt
  end

  def history_context
    SubmissionHistoryContext.new(@submission).to_prompt
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
