Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self, :https, :data, "https://*.posthog.com"
    policy.img_src     :self, :https, :data, "https://*.posthog.com"
    policy.object_src  :none
    policy.script_src  :self, :unsafe_inline, "https://*.posthog.com"
    policy.style_src   :self, :unsafe_inline, "https://*.posthog.com"
    policy.connect_src :self, "https://*.posthog.com"
    policy.worker_src  :self, :blob, :data
  end
end
