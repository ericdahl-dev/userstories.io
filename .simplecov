# frozen_string_literal: true

require "simplecov_json_formatter"

SimpleCov.start "rails" do
  add_filter "/spec/"
  enable_coverage :branch
  minimum_coverage line: 85, branch: 50

  formatter SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::JSONFormatter
  ])
end
