class MagicToken < ApplicationRecord
  belongs_to :collaborator

  TOKEN_TTL = 15.minutes

  validates :token, presence: true, uniqueness: true
  validates :expires_at, presence: true

  before_validation :generate_token, on: :create

  scope :valid, -> { where(used_at: nil).where("expires_at > ?", Time.current) }

  def expired?
    expires_at < Time.current
  end

  def used?
    used_at.present?
  end

  def consume!
    update!(used_at: Time.current)
  end

  private

  def generate_token
    self.token     ||= SecureRandom.hex(32)
    self.expires_at ||= TOKEN_TTL.from_now
  end
end
