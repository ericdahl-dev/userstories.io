class Submission < ApplicationRecord
  has_neighbors :embedding

  GITHUB_SYNC_INTERVAL = 5.minutes
  MAX_REFINEMENT_COLLABORATOR_REPLIES = 2
  REFINEMENT_STATUSES = %w[pending processing completed failed].freeze
  EMBEDDING_DIMENSIONS = 1536

  belongs_to :collaborator
  belongs_to :project
  has_many :refinement_messages, dependent: :destroy

  after_commit :enqueue_embedding_generation, on: :create

  STATUSES = %w[pending accepted shipped dismissed].freeze

  class InvalidTransition < StandardError; end

  validates :title, presence: true
  validates :body, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :refinement_status, inclusion: { in: REFINEMENT_STATUSES }

  scope :pending_review, -> { where(status: "pending") }
  scope :accepted,       -> { where(status: "accepted") }
  scope :shipped,        -> { where(status: "shipped") }
  scope :visible_to_collaborator, -> { where.not(status: "dismissed") }
  scope :recent,         -> { order(created_at: :desc) }

  def acceptable?  = status == "pending"
  def dismissable? = status == "pending"
  def shippable?   = status == "accepted"

  def github_status_trackable?
    github_issue_number.present? && status.in?(%w[accepted shipped])
  end

  def github_sync_due?
    github_status_trackable? &&
      (github_issue_synced_at.nil? || github_issue_synced_at <= GITHUB_SYNC_INTERVAL.ago)
  end

  def github_issue_status_pending?
    github_issue_number.present? && github_issue_summary.blank?
  end

  def github_issue_status_unavailable?
    github_issue_summary == SubmissionGithubSync::UNAVAILABLE_SUMMARY
  end

  def github_status_refresh_needed?
    github_status_trackable? && (
      github_issue_status_pending? ||
      (status == "accepted" && github_sync_due?)
    )
  end

  def refinement_collaborator_reply_count
    refinement_messages.where(role: "collaborator").count
  end

  def refinement_replies_remaining
    [ MAX_REFINEMENT_COLLABORATOR_REPLIES - refinement_collaborator_reply_count, 0 ].max
  end

  def refinement_at_cap?
    refinement_collaborator_reply_count >= MAX_REFINEMENT_COLLABORATOR_REPLIES
  end

  def refinement_locked?
    refinement_locked_at.present?
  end

  def refinement_processing?
    refinement_status == "processing"
  end

  def refinement_chat_open?
    !refinement_locked? && !refinement_at_cap?
  end

  def refinement_initial_due?
    !refinement_locked? &&
      RefinementQuotaGuard.allowed?(self) &&
      refinement_messages.where(role: "assistant").none? &&
      refinement_status.in?(%w[pending failed])
  end

  def refinement_turn_due?
    return false if refinement_locked?

    refinement_messages.chronological.last&.collaborator?
  end

  def refinement_finalized?
    refinement_locked_at.present?
  end

  def effective_title
    use_refined_text? ? refined_title : title
  end

  def effective_body
    use_refined_text? ? refined_body : body
  end

  def accept!(github_issue_number:, github_issue_url:)
    raise InvalidTransition, "can only accept pending submissions" unless acceptable?

    update!(
      status: "accepted",
      github_issue_number: github_issue_number,
      github_issue_url: github_issue_url,
      github_issue_state: "open",
      github_issue_summary: "Open · just created",
      github_issue_synced_at: Time.current
    )
  end

  def dismiss!
    raise InvalidTransition, "can only dismiss pending submissions" unless dismissable?

    update!(status: "dismissed")
  end

  def ship!
    raise InvalidTransition, "can only ship accepted submissions" unless shippable?

    update!(status: "shipped")
  end

  def lock_refinement!
    return if refinement_locked?

    update!(refinement_locked_at: Time.current)
  end

  def refinement_assistant_summary(max_chars: 500)
    message = refinement_messages.where(role: "assistant").order(created_at: :asc).first
    return if message.blank?

    message.body.to_s.truncate(max_chars)
  end

  def embeddable_text
    [ title, body ].join("\n\n")
  end

  private

  def enqueue_embedding_generation
    return unless EmbeddingClient.configured?

    GenerateSubmissionEmbeddingJob.perform_later(self)
  end

  def use_refined_text?
    refined_title.present? &&
      refined_body.present? &&
      (refinement_finalized? || refinement_status == "completed")
  end
end
