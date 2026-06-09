class RefinementMessage < ApplicationRecord
  ROLES = %w[collaborator assistant].freeze

  belongs_to :submission

  validates :role, inclusion: { in: ROLES }
  validates :body, presence: true

  scope :chronological, -> { order(created_at: :asc) }

  def collaborator? = role == "collaborator"
  def assistant? = role == "assistant"
end
