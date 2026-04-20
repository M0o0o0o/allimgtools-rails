require "test_helper"

class PaddleWebhookJobTest < ActiveSupport::TestCase
  # ── Helpers ───────────────────────────────────────────────────────────────

  def perform(event)
    PaddleWebhookJob.perform_now(event)
  end

  def activated_event(user, price_id: PADDLE_TEST_PRICE_ID, next_billed_at: 1.month.from_now.iso8601)
    {
      "event_type" => "subscription.activated",
      "data" => {
        "id"            => "sub_new_001",
        "customer_id"   => user.customer_id,
        "next_billed_at" => next_billed_at,
        "items"         => [ { "price" => { "id" => price_id } } ]
      }
    }
  end

  # ── subscription.activated ───────────────────────────────────────────────

  test "activated sets subscription fields on user" do
    user = users(:free_user)
    user.update!(customer_id: "ctm_free_test")

    perform(activated_event(user))

    user.reload
    assert_equal "sub_new_001", user.subscription_id
    assert_equal "pro", user.subscription_plan
    assert user.subscribed?
  end

  test "activated sets subscribed_until to next_billed_at + 1 day" do
    user = users(:free_user)
    user.update!(customer_id: "ctm_free_test2")
    billed_at = 2.months.from_now

    perform(activated_event(user, next_billed_at: billed_at.iso8601))

    expected = Time.zone.parse(billed_at.iso8601) + 1.day
    assert_in_delta expected, user.reload.subscribed_until, 2.seconds
  end

  test "activated uses 1.month.from_now when next_billed_at is nil" do
    user = users(:free_user)
    user.update!(customer_id: "ctm_free_test3")
    event = activated_event(user)
    event["data"].delete("next_billed_at")

    perform(event)

    assert_in_delta 1.month.from_now, user.reload.subscribed_until, 5.seconds
  end

  test "activated does nothing when customer_id not found" do
    event = {
      "event_type" => "subscription.activated",
      "data"       => { "id" => "sub_x", "customer_id" => "ctm_unknown_xyz",
                        "next_billed_at" => nil, "items" => [] }
    }
    assert_nothing_raised { perform(event) }
  end

  test "activated resolves pro_yearly plan" do
    user = users(:free_user)
    user.update!(customer_id: "ctm_free_test4")

    original = ENV["PADDLE_PRO_YEARLY_PRICE_ID"]
    ENV["PADDLE_PRO_YEARLY_PRICE_ID"] = "pri_01yearly"

    perform(activated_event(user, price_id: "pri_01yearly"))
    assert_equal "pro_yearly", user.reload.subscription_plan
  ensure
    ENV["PADDLE_PRO_YEARLY_PRICE_ID"] = original
    user.update!(customer_id: nil, subscription_id: nil, subscription_plan: nil, subscribed_until: nil)
  end

  # ── subscription.renewed ─────────────────────────────────────────────────

  test "renewed updates subscribed_until" do
    user = users(:pro_user)
    new_date = 3.months.from_now

    perform(
      "event_type" => "subscription.renewed",
      "data"       => { "customer_id" => user.customer_id,
                        "next_billed_at" => new_date.iso8601 }
    )

    expected = Time.zone.parse(new_date.iso8601) + 1.day
    assert_in_delta expected, user.reload.subscribed_until, 2.seconds
  end

  test "renewed does nothing for unknown customer_id" do
    assert_nothing_raised do
      perform(
        "event_type" => "subscription.renewed",
        "data"       => { "customer_id" => "ctm_nobody", "next_billed_at" => nil }
      )
    end
  end

  # ── subscription.updated ─────────────────────────────────────────────────

  test "updated changes plan and subscribed_until" do
    user = users(:pro_user)
    new_date = 2.months.from_now

    perform(
      "event_type" => "subscription.updated",
      "data"       => {
        "customer_id"    => user.customer_id,
        "next_billed_at" => new_date.iso8601,
        "items"          => [ { "price" => { "id" => PADDLE_TEST_PRICE_ID } } ]
      }
    )

    user.reload
    assert_equal "pro", user.subscription_plan
    assert user.subscribed?
  end

  # ── subscription.cancelled ───────────────────────────────────────────────

  test "cancelled sets subscribed_until to scheduled effective_at" do
    user        = users(:pro_user)
    effective   = 2.weeks.from_now

    perform(
      "event_type" => "subscription.cancelled",
      "data"       => {
        "customer_id"       => user.customer_id,
        "scheduled_change"  => { "effective_at" => effective.iso8601 }
      }
    )

    expected = Time.zone.parse(effective.iso8601)
    assert_in_delta expected, user.reload.subscribed_until, 2.seconds
  end

  test "cancelled sets subscribed_until to nil when no effective_at" do
    user = users(:pro_user)

    perform(
      "event_type" => "subscription.cancelled",
      "data"       => { "customer_id" => user.customer_id, "scheduled_change" => {} }
    )

    assert_nil user.reload.subscribed_until
  end

  # ── subscription.past_due ────────────────────────────────────────────────

  test "past_due gives 3-day grace period when subscribed_until is in the future" do
    user = users(:pro_user)
    original = user.subscribed_until

    perform(
      "event_type" => "subscription.past_due",
      "data"       => { "customer_id" => user.customer_id }
    )

    # subscribed_until should be min(original, 3.days.from_now)
    reloaded = user.reload.subscribed_until
    assert_in_delta [ original, 3.days.from_now ].min, reloaded, 5.seconds
  end

  test "past_due sets 3-day grace period when user had no subscribed_until" do
    user = users(:free_user)
    user.update!(customer_id: "ctm_free_due")

    perform(
      "event_type" => "subscription.past_due",
      "data"       => { "customer_id" => user.customer_id }
    )

    assert_in_delta 3.days.from_now, user.reload.subscribed_until, 5.seconds
  ensure
    user.update!(customer_id: nil, subscribed_until: nil)
  end

  # ── fallback: customer_id not saved ──────────────────────────────────────

  test "activated falls back to email lookup when customer_id not saved" do
    user = users(:free_user)
    # Ensure no customer_id saved
    user.update!(customer_id: nil)

    customer_data = { "id" => "ctm_looked_up", "email" => user.email_address }
    PaddleApi.stub(:customer, { "data" => customer_data }) do
      perform(
        "event_type" => "subscription.activated",
        "data"       => {
          "id"             => "sub_fallback",
          "customer_id"    => "ctm_looked_up",
          "next_billed_at" => 1.month.from_now.iso8601,
          "items"          => [ { "price" => { "id" => PADDLE_TEST_PRICE_ID } } ]
        }
      )
    end

    user.reload
    assert_equal "ctm_looked_up", user.customer_id
    assert_equal "pro", user.subscription_plan
  ensure
    user.update!(customer_id: nil, subscription_id: nil,
                 subscription_plan: nil, subscribed_until: nil)
  end

  # ── unknown event type ────────────────────────────────────────────────────

  test "ignores unknown event types without error" do
    assert_nothing_raised do
      perform("event_type" => "transaction.completed", "data" => {})
    end
  end
end
