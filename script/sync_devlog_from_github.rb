#!/usr/bin/env ruby
# frozen_string_literal: true

warn "script/sync_devlog_from_github.rb is deprecated; use: script/devlog.rb update"
args = []
args << "--pr" << ENV["DEVLOG_PR_NUMBER"] if ENV["DEVLOG_PR_NUMBER"]&.strip&.then { |v| !v.empty? }
args << "--force" if ENV["DEVLOG_FORCE"] == "true"
exec(File.expand_path("devlog.rb", __dir__), "update", *args)
