require "test_helper"

class SubscriptionsControllerTest < ActionDispatch::IntegrationTest
  # ── checkout_complete ────────────────────────────────────────────────────

  test "checkout_complete saves customer_id and upgrades user" do
    sign_in_as(users(:free_user))

    active_sub = {
      "id"             => "sub_new_001",
      "next_billed_at" => 1.month.from_now.iso8601,
      "items"          => [ { "price" => { "id" => PADDLE_TEST_PRICE_ID } } ]
    }

    PaddleApi.stub(:active_subscriptions, [ active_sub ]) do
      post subscription_checkout_complete_path,
           params: { customer_id: "ctm_new_001" }
    end

    assert_response :success
    assert_equal({ "ok" => true }, response.parsed_body)

    user = users(:free_user).reload
    assert_equal "ctm_new_001", user.customer_id
    assert_equal "sub_new_001", user.subscription_id
    assert_equal "pro", user.subscription_plan
    assert user.subscribed?
  ensure
    users(:free_user).update!(customer_id: nil, subscription_id: nil,
                              subscription_plan: nil, subscribed_until: nil)
  end

  test "checkout_complete still succeeds when no active subscription found" do
    sign_in_as(users(:free_user))

    PaddleApi.stub(:active_subscriptions, []) do
      post subscription_checkout_complete_path, params: { customer_id: "ctm_noplan" }
    end

    assert_response :success
    assert_equal "ctm_noplan", users(:free_user).reload.customer_id
  ensure
    users(:free_user).update!(customer_id: nil)
  end

  test "checkout_complete rejects customer_id already owned by another user" do
    sign_in_as(users(:free_user))
    # pro_user already owns ctm_pro123
    post subscription_checkout_complete_path, params: { customer_id: "ctm_pro123" }

    assert_response :unprocessable_entity
    assert_match "Invalid request", response.parsed_body["error"]
  end

  test "checkout_complete requires authentication" do
    post subscription_checkout_complete_path, params: { customer_id: "ctm_x" }
    assert_redirected_to new_session_path
  end

  test "checkout_complete sets subscribed_until to 1.month.from_now when next_billed_at is nil" do
    sign_in_as(users(:free_user))

    active_sub = {
      "id"             => "sub_nobill",
      "next_billed_at" => nil,
      "items"          => [ { "price" => { "id" => PADDLE_TEST_PRICE_ID } } ]
    }

    PaddleApi.stub(:active_subscriptions, [ active_sub ]) do
      post subscription_checkout_complete_path, params: { customer_id: "ctm_nobill" }
    end

    assert_in_delta 1.month.from_now, users(:free_user).reload.subscribed_until, 5.seconds
  ensure
    users(:free_user).update!(customer_id: nil, subscription_id: nil,
                              subscription_plan: nil, subscribed_until: nil)
  end

  # ── sync ─────────────────────────────────────────────────────────────────

  test "sync upgrades user when active subscription found via existing customer_id" do
    sign_in_as(users(:free_user))
    users(:free_user).update!(customer_id: "ctm_sync_test")

    active_sub = {
      "id"             => "sub_synced",
      "next_billed_at" => 1.month.from_now.iso8601,
      "items"          => [ { "price" => { "id" => PADDLE_TEST_PRICE_ID } } ]
    }

    PaddleApi.stub(:active_subscriptions, [ active_sub ]) do
      post subscription_sync_path
    end

    assert_redirected_to my_page_path
    assert_match "Welcome to Pro", flash[:notice]
    users(:free_user).reload.tap do |u|
      assert_equal "pro", u.subscription_plan
      assert u.subscribed?
    end
  ensure
    users(:free_user).update!(customer_id: nil, subscription_id: nil,
                              subscription_plan: nil, subscribed_until: nil)
  end

  test "sync falls back to Paddle email lookup when customer_id not saved" do
    sign_in_as(users(:free_user))
    users(:free_user).update!(customer_id: nil)

    customer    = { "id" => "ctm_by_email" }
    active_sub  = {
      "id"             => "sub_email",
      "next_billed_at" => 1.month.from_now.iso8601,
      "items"          => [ { "price" => { "id" => PADDLE_TEST_PRICE_ID } } ]
    }

    PaddleApi.stub(:customer_by_email, customer) do
      PaddleApi.stub(:active_subscriptions, [ active_sub ]) do
        post subscription_sync_path
      end
    end

    assert_redirected_to my_page_path
    assert_equal "ctm_by_email", users(:free_user).reload.customer_id
  ensure
    users(:free_user).update!(customer_id: nil, subscription_id: nil,
                              subscription_plan: nil, subscribed_until: nil)
  end

  test "sync alerts when no Paddle account found" do
    sign_in_as(users(:free_user))
    users(:free_user).update!(customer_id: nil)

    PaddleApi.stub(:customer_by_email, nil) do
      post subscription_sync_path
    end

    assert_redirected_to my_page_path
    assert_match "No Paddle account", flash[:alert]
  end

  test "sync alerts when no active subscription found" do
    sign_in_as(users(:free_user))
    users(:free_user).update!(customer_id: "ctm_no_sub")

    PaddleApi.stub(:active_subscriptions, []) do
      post subscription_sync_path
    end

    assert_redirected_to my_page_path
    assert_match "No active subscription", flash[:alert]
  ensure
    users(:free_user).update!(customer_id: nil)
  end

  test "sync requires authentication" do
    post subscription_sync_path
    assert_redirected_to new_session_path
  end

  # ── portal ────────────────────────────────────────────────────────────────

  test "portal redirects to billing portal URL" do
    sign_in_as(users(:pro_user))

    PaddleApi.stub(:portal_session, "https://billing.paddle.com/portal/123") do
      get subscription_portal_path
    end

    assert_redirected_to "https://billing.paddle.com/portal/123"
  end

  test "portal alerts when customer_id is blank" do
    sign_in_as(users(:free_user))

    get subscription_portal_path

    assert_redirected_to my_page_path
    assert_match "No billing account", flash[:alert]
  end

  test "portal alerts when portal session URL is blank" do
    sign_in_as(users(:pro_user))

    PaddleApi.stub(:portal_session, nil) do
      get subscription_portal_path
    end

    assert_redirected_to my_page_path
    assert_match "Could not open billing portal", flash[:alert]
  end

  test "portal requires authentication" do
    get subscription_portal_path
    assert_redirected_to new_session_path
  end
end
