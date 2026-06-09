# frozen_string_literal: true

REQUIRED_ENCRYPTION_ENV_VARS = %w[
  ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY
  ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY
  ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT
].freeze

if Rails.env.production? || Rails.env.development?
  missing = REQUIRED_ENCRYPTION_ENV_VARS.reject { |key| ENV[key].present? }
  raise "Missing Active Record encryption ENV vars: #{missing.join(', ')}" if missing.any?

  Rails.application.config.active_record.encryption.primary_key = ENV.fetch("ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY")
  Rails.application.config.active_record.encryption.deterministic_key = ENV.fetch("ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY")
  Rails.application.config.active_record.encryption.key_derivation_salt = ENV.fetch("ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT")
end
