class SubscriptionsController < ApplicationController
  before_action :require_authentication

  # POST /subscription/checkout_complete
  # Called by Paddle.js onComplete callback after a successful checkout.
  # Saves the Paddle customer_id so webhook events can be matched to this user.
  def checkout_complete
    customer_id = params.require(:customer_id)

    # Guard: don't overwrite if another user already owns this customer_id
    if User.where.not(id: Current.user.id).exists?(customer_id: customer_id)
      return render json: { error: "Invalid request." }, status: :unprocessable_entity
    end

    Current.user.update!(customer_id: customer_id)

    # Immediately sync subscription so user is upgraded without waiting for webhook
    subscriptions = PaddleApi.active_subscriptions(customer_id)
    active_sub    = subscriptions.first
    if active_sub
      price_id         = active_sub.dig("items", 0, "price", "id")
      raw_billed_at    = active_sub["next_billed_at"]
      subscribed_until = raw_billed_at ? Time.zone.parse(raw_billed_at) + 1.day : 1.month.from_now

      Current.user.update!(
        subscription_id:   active_sub["id"],
        subscription_plan: PaddleApi.resolve_plan(price_id),
        subscribed_until:  subscribed_until
      )
    end

    render json: { ok: true }
  end

  # POST /subscription/sync
  # Manually reconciles subscription status by querying Paddle API directly.
  # Handles two failure cases:
  #   - customer_id not saved (Path A failure): looks up customer by email
  #   - subscribed_until not set (webhook exhausted): fetches active subscription
  def sync
    customer_id = resolve_customer_id
    if customer_id.blank?
      return redirect_to my_page_path, alert: "No Paddle account found for this email. Please contact support."
    end

    subscriptions = PaddleApi.active_subscriptions(customer_id)
    active_sub    = subscriptions.first

    if active_sub.nil?
      return redirect_to my_page_path, alert: "No active subscription found. If you just paid, please wait a moment and try again."
    end

    price_id        = active_sub.dig("items", 0, "price", "id")
    raw_billed_at   = active_sub["next_billed_at"]
    subscribed_until = raw_billed_at ? Time.zone.parse(raw_billed_at) + 1.day : 1.month.from_now

    Current.user.update!(
      customer_id:       customer_id,
      subscription_id:   active_sub["id"],
      subscription_plan: PaddleApi.resolve_plan(price_id),
      subscribed_until:  subscribed_until
    )

    redirect_to my_page_path, notice: "Subscription verified. Welcome to Pro!"
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
    Rails.logger.error "SubscriptionsController#sync update failed: #{e.message}"
    redirect_to my_page_path, alert: "Something went wrong while saving your subscription. Please try again."
  end

  # GET /subscription/portal
  # Generates a Paddle customer portal session URL and redirects the user there.
  def portal
    customer_id = Current.user.customer_id
    if customer_id.blank?
      return redirect_to my_page_path, alert: "No billing account found. Please contact support."
    end

    url = PaddleApi.portal_session(customer_id)
    if url.blank?
      return redirect_to my_page_path, alert: "Could not open billing portal. Please try again."
    end

    redirect_to url, allow_other_host: true
  end

  private

  # Returns customer_id from DB, or fetches it from Paddle API via email (케이스 1 복구)
  def resolve_customer_id
    return Current.user.customer_id if Current.user.customer_id.present?

    customer = PaddleApi.customer_by_email(Current.user.email_address)
    customer&.dig("id")
  end
end
