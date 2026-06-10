require "capybara/cuprite"

Capybara.register_driver(:cuprite) do |app|
  options = {
    window_size: [ 1400, 1400 ],
    process_timeout: 30,
    timeout: 10,
    headless: true
  }

  if ENV["CI"]
    options[:browser_options] = {
      "no-sandbox" => nil,
      "disable-dev-shm-usage" => nil
    }
  end

  Capybara::Cuprite::Driver.new(app, **options)
end

Capybara.javascript_driver = :cuprite
