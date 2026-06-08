class Collaborator < ApplicationRecord
  has_many :submissions, dependent: :destroy
  has_many :projects, through: :submissions
  has_many :magic_tokens, dependent: :destroy

  validates :email, presence: true, uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true

  normalizes :email, with: ->(e) { e.strip.downcase }

  def self.for_login(email:)
    email = email.to_s.strip.downcase
    record = find_or_initialize_by(email: email)
    record.name = email.split("@").first if record.name.blank?
    record.save!
    record
  end
end
