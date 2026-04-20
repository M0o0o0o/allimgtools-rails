require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  # ── Public pages ──────────────────────────────────────────────────────────

  test "home renders" do
    get root_path
    assert_response :success
  end

  test "pricing renders" do
    get pricing_path
    assert_response :success
  end

  test "faq renders" do
    get faq_path
    assert_response :success
  end

  test "terms renders" do
    get terms_path
    assert_response :success
  end

  test "privacy renders" do
    get privacy_path
    assert_response :success
  end

  # ── my_page (auth required) ───────────────────────────────────────────────

  test "my_page redirects unauthenticated user" do
    get my_page_path
    assert_redirected_to new_session_path
  end

  test "my_page renders for authenticated user" do
    sign_in_as(users(:free_user))
    get my_page_path
    assert_response :success
  end

  test "my_page renders for pro user" do
    sign_in_as(users(:pro_user))
    get my_page_path
    assert_response :success
  end

  # ── destroy_account ───────────────────────────────────────────────────────

  test "destroy_account redirects unauthenticated user" do
    delete destroy_account_path
    assert_redirected_to new_session_path
  end

  test "destroy_account deletes user and redirects to root" do
    # Use a dedicated user to avoid fixture pollution
    user = User.create!(email_address: "todelete@example.com", name: "Delete Me",
                        provider: "google", uid: "uid_delete_me")
    sign_in_as(user)

    assert_difference "User.count", -1 do
      delete destroy_account_path
    end

    assert_redirected_to root_path
    assert_match "deleted", flash[:notice]
  end
end
