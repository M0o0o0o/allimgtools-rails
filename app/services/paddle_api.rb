class PaddleApi
  def self.base_url
    Rails.application.credentials.paddle&.dig(:sandbox) \
      ? "https://sandbox-api.paddle.com"
      : "https://api.paddle.com"
  end

  # GET /customers/{customer_id}
  # Returns { "data" => { "id" => ..., "email" => ... } }
  def self.customer(customer_id)
    get("/customers/#{customer_id}")
  end

  # GET /customers?search={email}
  # Returns the first customer whose email matches exactly.
  def self.customer_by_email(email)
    result = get("/customers?search=#{URI.encode_www_form_component(email)}")
    result&.dig("data")&.find { |c| c["email"]&.downcase == email.downcase }
  end

  # Maps a Paddle price_id to an internal plan name string.
  # Returns "pro", "pro_yearly", or nil if unrecognized.
  def self.resolve_plan(price_id)
    paddle       = Rails.application.credentials.paddle
    pro_price_id = paddle&.dig(:pro_price_id)     || ENV["PADDLE_PRO_PRICE_ID"]
    pro_yearly   = paddle&.dig(:pro_yearly_price_id) || ENV["PADDLE_PRO_YEARLY_PRICE_ID"]
    case price_id
    when pro_price_id  then "pro"
    when pro_yearly    then "pro_yearly"
    else
      Rails.logger.warn "PaddleApi.resolve_plan: unrecognized price_id=#{price_id.inspect}"
      nil
    end
  end

  # GET /subscriptions?customer_id={customer_id}&status=active
  # Returns array of active subscription objects.
  def self.active_subscriptions(customer_id)
    result = get("/subscriptions?customer_id=#{customer_id}&status=active")
    result&.dig("data") || []
  end

  # POST /customers/{customer_id}/portal-sessions
  # Returns the customer portal URL where the user can manage their subscription.
  def self.portal_session(customer_id)
    result = post("/customers/#{customer_id}/portal-sessions", {})
    result&.dig("data", "urls", "general", "overview")
  end

  def self.get(path)
    uri = URI("#{base_url}#{path}")
    req = Net::HTTP::Get.new(uri)
    req["Authorization"] = "Bearer #{Rails.application.credentials.paddle&.dig(:api_key)}"
    req["Content-Type"]  = "application/json"

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true,
                          open_timeout: 5, read_timeout: 10) { |http| http.request(req) }
    unless res.is_a?(Net::HTTPSuccess)
      Rails.logger.error "PaddleApi#get #{path} returned HTTP #{res.code}: #{res.body.truncate(200)}"
      return nil
    end
    JSON.parse(res.body)
  rescue StandardError => e
    Rails.logger.error "PaddleApi#get #{path} failed: #{e.class}: #{e.message}"
    nil
  end

  def self.post(path, body)
    uri = URI("#{base_url}#{path}")
    req = Net::HTTP::Post.new(uri)
    req["Authorization"] = "Bearer #{Rails.application.credentials.paddle&.dig(:api_key)}"
    req["Content-Type"]  = "application/json"
    req.body = body.to_json

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true,
                          open_timeout: 5, read_timeout: 10) { |http| http.request(req) }
    unless res.is_a?(Net::HTTPSuccess)
      Rails.logger.error "PaddleApi#post #{path} returned HTTP #{res.code}: #{res.body.truncate(200)}"
      return nil
    end
    JSON.parse(res.body)
  rescue StandardError => e
    Rails.logger.error "PaddleApi#post #{path} failed: #{e.class}: #{e.message}"
    nil
  end
end
