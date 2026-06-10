class User < ApplicationRecord
  include BillingPlan

  encrypts :github_token

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [ :github ]

  has_many :projects, dependent: :destroy
  has_many :admin_credit_grants, dependent: :destroy
  has_many :granted_admin_credit_grants, class_name: "AdminCreditGrant", foreign_key: :granted_by_id, dependent: :destroy, inverse_of: :granted_by

  def admin?
    AdminAllowlist.include?(email)
  end

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
      user.github_token = auth.credentials.token
    end.tap do |user|
      attrs = { github_token: auth.credentials.token }
      attrs[:email] = auth.info.email if auth.info.email.present?
      user.update!(attrs)
    end
  end
end
