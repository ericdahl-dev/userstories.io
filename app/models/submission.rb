class Submission < ApplicationRecord
  belongs_to :collaborator
  belongs_to :project

  STATUSES = %w[pending accepted shipped dismissed].freeze

  class InvalidTransition < StandardError; end

  validates :title, presence: true
  validates :body, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :pending_review, -> { where(status: "pending") }
  scope :accepted,       -> { where(status: "accepted") }
  scope :shipped,        -> { where(status: "shipped") }
  scope :recent,         -> { order(created_at: :desc) }

  def acceptable?  = status == "pending"
  def dismissable? = status == "pending"
  def shippable?   = status == "accepted"

  def accept!(github_issue_number:, github_issue_url:)
    raise InvalidTransition, "can only accept pending submissions" unless acceptable?

    update!(
      status: "accepted",
      github_issue_number: github_issue_number,
      github_issue_url: github_issue_url
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
end
