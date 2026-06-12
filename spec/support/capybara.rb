require "capybara/cuprite"

Capybara.register_driver(:cuprite) do |app|
  process_timeout = ENV.fetch("FERRUM_PROCESS_TIMEOUT", ENV["CI"] ? "120" : "30").to_i

  options = {
    window_size: [ 1400, 1400 ],
    process_timeout: process_timeout,
    timeout: ENV["CI"] ? 30 : 10,
    headless: true
  }

  if ENV["CI"]
    options[:browser_options] = {
      "no-sandbox" => nil,
      "disable-dev-shm-usage" => nil,
      "disable-gpu" => nil
    }
  end

  Capybara::Cuprite::Driver.new(app, options)
end

Capybara.javascript_driver = :cuprite
