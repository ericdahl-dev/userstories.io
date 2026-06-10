class AdminAllowlist
  def self.include?(email)
    emails.include?(email.to_s.downcase)
  end

  def self.emails
    ENV.fetch("ADMIN_EMAILS", "").split(",").map { |email| email.strip.downcase }.compact_blank
  end
end
