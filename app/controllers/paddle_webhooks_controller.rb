class PaddleWebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :set_locale

  def receive
    payload   = request.body.read
    signature = request.headers["Paddle-Signature"]

    unless valid_signature?(payload, signature)
      return render json: { error: "Invalid signature." }, status: :unauthorized
    end

    event = JSON.parse(payload)
    PaddleWebhookJob.perform_later(event)

    head :ok
  rescue JSON::ParserError
    render json: { error: "Invalid payload." }, status: :bad_request
  end

  private

  def valid_signature?(payload, signature_header)
    return false if signature_header.blank?

    parts = signature_header.split(";").each_with_object({}) do |part, hash|
      key, value = part.split("=", 2)
      hash[key] = value
    end

    ts = parts["ts"]
    h1 = parts["h1"]
    return false if ts.blank? || h1.blank?

    # Reject requests older than 5 seconds to prevent replay attacks
    return false if (Time.current.to_i - ts.to_i).abs > 5

    signed_payload = "#{ts}:#{payload}"
    secret         = Rails.application.credentials.paddle[:webhook_secret].to_s
    expected       = OpenSSL::HMAC.hexdigest("SHA256", secret, signed_payload)

    ActiveSupport::SecurityUtils.secure_compare(expected, h1)
  end
end
