require "test_helper"

class AuthControllerTest < ActionDispatch::IntegrationTest
  setup    { OmniAuth.config.test_mode = true }
  teardown { OmniAuth.config.test_mode = false }

  # ── login ─────────────────────────────────────────────────────────────────

  test "login renders for unauthenticated user" do
    get login_path
    assert_response :success
  end

  test "login redirects authenticated user to root" do
    sign_in_as(users(:free_user))
    get login_path
    assert_redirected_to root_path
  end

  # ── google_callback ───────────────────────────────────────────────────────

  test "google_callback creates session and redirects" do
    user = users(:free_user)
    mock_auth = {
      provider: user.provider,
      uid:      user.uid,
      info:     { email: user.email_address, name: user.name, image: nil }
    }

    get "/auth/google_oauth2/callback",
        env: { "omniauth.auth" => OmniAuth::AuthHash.new(mock_auth) }

    assert_response :redirect
    assert cookies[:session_id].present?
  end

  test "google_callback redirects to root on error" do
    get "/auth/google_oauth2/callback",
        env: { "omniauth.auth" => nil }

    assert_redirected_to root_path
  end

  # ── failure ───────────────────────────────────────────────────────────────

  test "failure redirects to login with alert" do
    post "/auth/failure"
    assert_redirected_to login_path
    assert_match "Sign in failed", flash[:alert]
  end

  # ── destroy (logout) ─────────────────────────────────────────────────────

  test "destroy terminates session and redirects to root" do
    sign_in_as(users(:free_user))

    delete logout_path

    assert_redirected_to root_path
    assert_empty cookies[:session_id]
  end

  test "destroy works even without active session" do
    delete logout_path
    assert_redirected_to root_path
  end
end
