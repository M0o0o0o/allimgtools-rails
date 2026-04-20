require "test_helper"

class PaddleApiTest < ActiveSupport::TestCase
  # ── base_url ──────────────────────────────────────────────────────────────

  test "base_url returns sandbox URL when sandbox credential is true" do
    Rails.application.credentials.stub(:paddle, { sandbox: true }) do
      assert_equal "https://sandbox-api.paddle.com", PaddleApi.base_url
    end
  end

  test "base_url returns production URL when sandbox credential is false" do
    Rails.application.credentials.stub(:paddle, { sandbox: false }) do
      assert_equal "https://api.paddle.com", PaddleApi.base_url
    end
  end

  test "base_url returns production URL when credentials are nil" do
    Rails.application.credentials.stub(:paddle, nil) do
      assert_equal "https://api.paddle.com", PaddleApi.base_url
    end
  end

  # ── resolve_plan ─────────────────────────────────────────────────────────

  test "resolve_plan returns 'pro' for matching pro_price_id" do
    Rails.application.credentials.stub(:paddle, { pro_price_id: "pri_monthly_test" }) do
      assert_equal "pro", PaddleApi.resolve_plan("pri_monthly_test")
    end
  end

  test "resolve_plan returns 'pro_yearly' for PADDLE_PRO_YEARLY_PRICE_ID env var" do
    original = ENV["PADDLE_PRO_YEARLY_PRICE_ID"]
    ENV["PADDLE_PRO_YEARLY_PRICE_ID"] = "pri_yearly_test"

    Rails.application.credentials.stub(:paddle, { pro_price_id: "pri_monthly_test" }) do
      assert_equal "pro_yearly", PaddleApi.resolve_plan("pri_yearly_test")
    end
  ensure
    ENV["PADDLE_PRO_YEARLY_PRICE_ID"] = original
  end

  test "resolve_plan returns nil for unrecognized price_id" do
    Rails.application.credentials.stub(:paddle, { pro_price_id: "known_id" }) do
      assert_nil PaddleApi.resolve_plan("unknown_price_id")
    end
  end

  # ── customer_by_email ─────────────────────────────────────────────────────

  test "customer_by_email returns matching customer" do
    body = {
      "data" => [
        { "id" => "ctm_001", "email" => "user@example.com" },
        { "id" => "ctm_002", "email" => "other@example.com" }
      ]
    }

    stub_http_response(body: body) do
      result = PaddleApi.customer_by_email("user@example.com")
      assert_equal "ctm_001", result["id"]
    end
  end

  test "customer_by_email returns nil when no match" do
    body = { "data" => [ { "id" => "ctm_001", "email" => "other@example.com" } ] }

    stub_http_response(body: body) do
      result = PaddleApi.customer_by_email("nomatch@example.com")
      assert_nil result
    end
  end

  test "customer_by_email returns nil on HTTP error" do
    stub_http_response(body: { "error" => "not found" }, code: "404", success: false) do
      result = PaddleApi.customer_by_email("user@example.com")
      assert_nil result
    end
  end

  # ── customer ─────────────────────────────────────────────────────────────

  test "customer returns parsed response" do
    body = { "data" => { "id" => "ctm_001", "email" => "user@example.com" } }

    stub_http_response(body: body) do
      result = PaddleApi.customer("ctm_001")
      assert_equal "ctm_001", result["data"]["id"]
    end
  end

  test "customer returns nil on network error" do
    Net::HTTP.stub(:start, ->(*_args, **_opts) { raise Errno::ECONNREFUSED }) do
      result = PaddleApi.customer("ctm_001")
      assert_nil result
    end
  end

  # ── active_subscriptions ──────────────────────────────────────────────────

  test "active_subscriptions returns subscription array" do
    body = { "data" => [ { "id" => "sub_001", "status" => "active" } ] }

    stub_http_response(body: body) do
      result = PaddleApi.active_subscriptions("ctm_001")
      assert_equal 1, result.size
      assert_equal "sub_001", result.first["id"]
    end
  end

  test "active_subscriptions returns empty array on error" do
    stub_http_response(body: { "error" => "server error" }, code: "500", success: false) do
      result = PaddleApi.active_subscriptions("ctm_001")
      assert_equal [], result
    end
  end

  test "active_subscriptions returns empty array on nil response" do
    Net::HTTP.stub(:start, ->(*_args, **_opts) { raise Timeout::Error }) do
      result = PaddleApi.active_subscriptions("ctm_001")
      assert_equal [], result
    end
  end

  # ── portal_session ────────────────────────────────────────────────────────

  test "portal_session returns overview URL" do
    body = {
      "data" => {
        "urls" => {
          "general" => { "overview" => "https://billing.paddle.com/overview" }
        }
      }
    }

    stub_http_response(body: body) do
      url = PaddleApi.portal_session("ctm_001")
      assert_equal "https://billing.paddle.com/overview", url
    end
  end

  test "portal_session returns nil on error" do
    stub_http_response(body: { "error" => "not found" }, code: "404", success: false) do
      assert_nil PaddleApi.portal_session("ctm_001")
    end
  end
end
