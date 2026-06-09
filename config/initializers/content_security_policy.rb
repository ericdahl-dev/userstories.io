def umami_analytics_origin
  script_url = ENV["UMAMI_SCRIPT_URL"].presence
  return unless script_url

  uri = URI.parse(script_url)
  "#{uri.scheme}://#{uri.host}"
rescue URI::InvalidURIError
  nil
end

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data
    policy.object_src  :none
    policy.script_src  :self, :unsafe_inline
    policy.style_src   :self, :unsafe_inline
    policy.connect_src :self
  end
end
