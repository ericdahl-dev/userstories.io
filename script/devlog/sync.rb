# frozen_string_literal: true

module Devlog
  module Sync
    REQUIRED_LABEL = "devlog"

    module_function

    def devlog_label?(labels)
      labels.map(&:downcase).include?(REQUIRED_LABEL)
    end
  end
end
