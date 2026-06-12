class User < ApplicationRecord
  encrypts :github_token

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [ :github ]

  has_many :projects, dependent: :destroy

  def posthog_distinct_id
    email
  end

  def posthog_properties
    { email: email, provider: provider, date_joined: created_at&.iso8601 }
  end

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
      user.github_token = auth.credentials.token
    end.tap do |user|
      user.update!(github_token: auth.credentials.token)
    end
  end
end
