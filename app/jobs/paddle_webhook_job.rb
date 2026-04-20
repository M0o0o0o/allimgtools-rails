class PaddleWebhookJob < ApplicationJob
  queue_as :default

  retry_on ActiveRecord::StatementInvalid, ActiveRecord::Deadlocked,
           wait: :polynomially_longer, attempts: 3
  discard_on ActiveRecord::RecordInvalid

  def perform(event)
    event_type = event["event_type"]
    data       = event["data"]

    case event_type
    when "subscription.activated"
      handle_activated(data)
    when "subscription.renewed"
      handle_renewed(data)
    when "subscription.updated"
      handle_updated(data)
    when "subscription.cancelled"
      handle_cancelled(data)
    when "subscription.past_due"
      handle_past_due(data)
    end
  end

  private

  def handle_activated(data)
    user = find_user(data)
    return unless user

    user.update!(
      subscription_id:   data["id"],
      subscription_plan: resolve_plan(data),
      subscribed_until:  next_billed_at(data)
    )
  end

  def handle_renewed(data)
    user = find_user(data)
    return unless user

    user.update!(subscribed_until: next_billed_at(data))
  end

  def handle_updated(data)
    user = find_user(data)
    return unless user

    user.update!(
      subscription_plan: resolve_plan(data),
      subscribed_until:  next_billed_at(data)
    )
  end

  def handle_cancelled(data)
    user = find_user(data)
    return unless user

    # 취소해도 현재 결제 기간 끝까지 유지 — effective_at이 있으면 그 날짜로, 없으면 즉시 해제
    effective_at = data.dig("scheduled_change", "effective_at")
    subscribed_until = effective_at ? Time.zone.parse(effective_at) : nil

    user.update!(subscribed_until: subscribed_until)
  end

  def handle_past_due(data)
    user = find_user(data)
    return unless user

    # 결제 실패 — 3일 유예기간 부여
    user.update!(subscribed_until: [ user.subscribed_until, 3.days.from_now ].compact.min)
  end

  def find_user(data)
    customer_id = data["customer_id"]
    return unless customer_id

    user = User.find_by(customer_id: customer_id)
    return user if user

    # Fallback: customer_id가 저장 안 된 경우 Paddle API로 이메일 조회
    email = PaddleApi.customer(customer_id)&.dig("data", "email")
    return unless email

    User.find_by(email_address: email)&.tap do |u|
      u.update!(customer_id: customer_id)
    end
  end

  def resolve_plan(data)
    PaddleApi.resolve_plan(data.dig("items", 0, "price", "id"))
  end

  def next_billed_at(data)
    raw = data["next_billed_at"]
    raw ? Time.zone.parse(raw) + 1.day : 1.month.from_now
  end
end
