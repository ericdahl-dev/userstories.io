#!/usr/bin/env ruby
# frozen_string_literal: true

warn "script/new_devlog_entry.rb is deprecated; use: script/devlog.rb new ..."
exec(File.expand_path("devlog.rb", __dir__), "new", *ARGV)
