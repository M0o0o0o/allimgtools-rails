module Admin
  class DashboardController < BaseController
    def index
      @total_users = User.count
      @today_uploads = Upload.where(created_at: Time.current.beginning_of_day..).count
    end
  end
end
