#!/usr/bin/env ruby
# frozen_string_literal: true

# Generates README screenshots into docs/screenshots/.
# Usage: script/generate_screenshots.rb

ENV["SKIP_COVERAGE"] = "1"
exec("bundle", "exec", "rspec", "spec/system/readme_screenshots_spec.rb", *ARGV)
