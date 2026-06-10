module Admin
  class DashboardController < BaseController
    def index
      @metrics = AdminDashboardMetrics.new(window: params[:window])
    end
  end
end
