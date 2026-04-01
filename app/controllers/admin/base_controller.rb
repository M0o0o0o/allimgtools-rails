module Admin
  class BaseController < ApplicationController
    layout "admin"
    before_action :require_admin

    private

    def require_admin
      resume_session
      redirect_to new_session_path, alert: "Please sign in as admin." unless Current.user&.admin?
    end
  end
end
