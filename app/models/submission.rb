class Submission < ApplicationRecord
  belongs_to :collaborator
  belongs_to :project

  STATUSES = %w[pending accepted shipped dismissed].freeze

  validates :title, presence: true
  validates :body, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :pending_review, -> { where(status: "pending") }
  scope :accepted,       -> { where(status: "accepted") }
  scope :shipped,        -> { where(status: "shipped") }
  scope :recent,         -> { order(created_at: :desc) }

  def accept!(github_issue_number:, github_issue_url:)
    update!(
      status: "accepted",
      github_issue_number: github_issue_number,
      github_issue_url: github_issue_url
    )
  end

  def ship!
    update!(status: "shipped")
  end
end
