class Project < ApplicationRecord
  belongs_to :user
  has_many :submissions, dependent: :destroy

  validates :name, presence: true
  validates :github_repo, presence: true
  validates :share_token, presence: true, uniqueness: true

  before_validation :set_share_token, on: :create

  def rotate_share_token!
    update!(share_token: self.class.generate_share_token)
  end

  def self.generate_share_token
    SecureRandom.urlsafe_base64(24)
  end

  private

  def set_share_token
    self.share_token ||= self.class.generate_share_token
  end
end
