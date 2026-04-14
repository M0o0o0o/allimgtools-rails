class AuthController < ApplicationController
  layout "auth"

  def login
    redirect_to root_path if authenticated?
  end

  def google_callback
    auth = request.env["omniauth.auth"]
    user = User.from_omniauth(auth)

    start_new_session_for user
    redirect_to safe_origin_path, notice: t("auth.login_success", name: user.name)
  rescue => e
    Rails.logger.error "OAuth callback error: #{e.class}: #{e.message}"
    redirect_to root_path, alert: t("auth.login_failed")
  end

  def failure
    redirect_to login_path, alert: t("auth.login_failed")
  end

  def destroy
    terminate_session
    redirect_to root_path, status: :see_other
  end

  private

  def safe_origin_path
    origin = request.env["omniauth.origin"]
    return root_path if origin.blank?

    uri = URI.parse(origin) rescue nil
    return root_path unless uri
    uri.host.nil? || uri.host == request.host ? origin : root_path
  end
end
