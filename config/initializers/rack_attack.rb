class Rack::Attack
  PORTAL_SESSIONS_CREATE = %r{\A/p/[^/]+/sessions\z}.freeze

  def self.portal_magic_link_create?(req)
    req.post? && req.path.match?(PORTAL_SESSIONS_CREATE)
  end

  def self.normalize_magic_link_email(email)
    email.to_s.downcase.gsub(/\s+/, "")
  end

  Rack::Attack.cache.store = if Rails.env.test?
    ActiveSupport::Cache::MemoryStore.new
  else
    Rails.cache
  end

  throttle("magic_link/ip", limit: 5, period: 60) do |req|
    req.ip if portal_magic_link_create?(req)
  end

  throttle("magic_link/email", limit: 3, period: 300) do |req|
    next unless portal_magic_link_create?(req)

    email = normalize_magic_link_email(req.params["email"])
    email.presence
  end
end
