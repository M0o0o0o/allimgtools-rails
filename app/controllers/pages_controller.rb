class PagesController < ApplicationController
  before_action :require_authentication, only: [ :my_page, :destroy_account ]

  def home
  end

  def my_page
  end

  def destroy_account
    current_user = Current.user
    terminate_session
    current_user.destroy!
    redirect_to root_path, notice: "Your account has been deleted."
  end

  def pricing
  end

  def faq
  end

  def terms
  end

  def privacy
  end
end
