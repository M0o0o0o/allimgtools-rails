require "test_helper"

class PaddleWebhooksControllerTest < ActionDispatch::IntegrationTest
  WEBHOOK_PATH = "/webhooks/paddle"

  def post_webhook(payload, signature_header: nil, secret: PADDLE_TEST_SECRET)
    payload_str = payload.is_a?(String) ? payload : payload.to_json
    sig = signature_header || paddle_signature(payload_str, secret: secret)[:header]
    post WEBHOOK_PATH,
         params:  payload_str,
         headers: {
           "Content-Type"     => "application/json",
           "Paddle-Signature" => sig
         }
  end

  # ── Signature validation ──────────────────────────────────────────────────

  test "returns 200 and enqueues job for valid signature" do
    payload = { "event_type" => "subscription.activated", "data" => {} }

    with_paddle_credentials do
      assert_enqueued_with(job: PaddleWebhookJob) do
        post_webhook(payload)
      end
    end

    assert_response :ok
  end

  test "returns 401 for missing Paddle-Signature header" do
    with_paddle_credentials do
      post WEBHOOK_PATH,
           params:  { event_type: "x" }.to_json,
           headers: { "Content-Type" => "application/json" }
    end

    assert_response :unauthorized
    assert_match "Invalid signature", response.parsed_body["error"]
  end

  test "returns 401 for wrong HMAC secret" do
    payload = { "event_type" => "x", "data" => {} }
    with_paddle_credentials do
      post_webhook(payload, secret: "wrong_secret")
    end

    assert_response :unauthorized
  end

  test "returns 401 for expired timestamp (> 5 seconds old)" do
    payload     = { "event_type" => "x" }.to_json
    old_ts      = (Time.current.to_i - 10)
    signed      = "#{old_ts}:#{payload}"
    h1          = OpenSSL::HMAC.hexdigest("SHA256", PADDLE_TEST_SECRET, signed)
    old_sig     = "ts=#{old_ts};h1=#{h1}"

    with_paddle_credentials do
      post WEBHOOK_PATH,
           params:  payload,
           headers: { "Content-Type" => "application/json", "Paddle-Signature" => old_sig }
    end

    assert_response :unauthorized
  end

  test "returns 400 for invalid JSON body" do
    with_paddle_credentials do
      ts     = Time.current.to_i
      body   = "not valid json{"
      signed = "#{ts}:#{body}"
      h1     = OpenSSL::HMAC.hexdigest("SHA256", PADDLE_TEST_SECRET, signed)

      post WEBHOOK_PATH,
           params:  body,
           headers: {
             "Content-Type"     => "application/json",
             "Paddle-Signature" => "ts=#{ts};h1=#{h1}"
           }
    end

    assert_response :bad_request
    assert_match "Invalid payload", response.parsed_body["error"]
  end

  test "returns 401 when signature header has no ts part" do
    with_paddle_credentials do
      post WEBHOOK_PATH,
           params:  {}.to_json,
           headers: {
             "Content-Type"     => "application/json",
             "Paddle-Signature" => "h1=somehash"
           }
    end

    assert_response :unauthorized
  end

  test "returns 401 when signature header has no h1 part" do
    with_paddle_credentials do
      post WEBHOOK_PATH,
           params:  {}.to_json,
           headers: {
             "Content-Type"     => "application/json",
             "Paddle-Signature" => "ts=#{Time.current.to_i}"
           }
    end

    assert_response :unauthorized
  end
end
