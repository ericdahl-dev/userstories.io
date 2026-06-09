RSpec.configure do |config|
  config.before do
    next unless defined?(Rack::Attack)

    Rack::Attack.enabled = true
    Rack::Attack.cache.store.clear
  end
end
