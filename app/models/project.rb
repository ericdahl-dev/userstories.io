class Project < ApplicationRecord
  belongs_to :user
  has_many :submissions, dependent: :destroy

  validates :name, presence: true
  validates :github_repo, presence: true
  validates :share_token, presence: true, uniqueness: true

  before_validation :generate_share_token, on: :create

  private

  def generate_share_token
    self.share_token ||= SecureRandom.urlsafe_base64(24)
  end
end
