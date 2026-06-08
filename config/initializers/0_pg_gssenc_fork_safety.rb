if RUBY_PLATFORM.include?("darwin") && ENV["PGGSSENCMODE"].to_s.empty?
  ENV["PGGSSENCMODE"] = "disable"
end
