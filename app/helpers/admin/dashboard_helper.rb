module Admin
  module DashboardHelper
    def window_label(window)
      case window
      when "today" then "Today"
      when "7d" then "7 days"
      when "30d" then "30 days"
      when "all" then "All time"
      else window
      end
    end
  end
end
