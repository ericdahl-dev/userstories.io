class Collaborator < ApplicationRecord
  has_many :submissions, dependent: :destroy
  has_many :projects, through: :submissions
  has_many :magic_tokens, dependent: :destroy

  validates :email, presence: true, uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true

  normalizes :email, with: ->(e) { e.strip.downcase }
end
