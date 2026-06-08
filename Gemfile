source "https://rubygems.org"

gem "rails", "~> 8.1.3"
gem "propshaft"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "tailwindcss-rails"
gem "jbuilder"

# Auth
gem "devise"
gem "bcrypt", "~> 3.1.7"
gem "omniauth-github"
gem "omniauth-rails_csrf_protection"

# Authorization
gem "pundit"

# Background jobs (Postgres-backed; no Redis)
gem "good_job"

# GitHub API
gem "octokit"

# Database-backed cache & cable (no Redis)
gem "solid_cache"
gem "solid_cable"

gem "bootsnap", require: false
gem "thruster", require: false
gem "image_processing", "~> 1.2"
gem "aws-sdk-s3", require: false

gem "tzinfo-data", platforms: %i[ windows jruby ]

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "dotenv-rails"
  gem "rspec-rails", "~> 8.0"
  gem "factory_bot_rails"
  gem "bundler-audit", require: false
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
end

group :development do
  gem "web-console"
end

group :test do
  gem "capybara"
  gem "cuprite"
  gem "simplecov", require: false
  gem "simplecov_json_formatter", require: false
end
