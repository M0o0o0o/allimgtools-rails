require "test_helper"

class UserTest < ActiveSupport::TestCase
  # ── Email normalization ──────────────────────────────────────────────────

  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal "downcased@example.com", user.email_address
  end

  # ── subscribed? ──────────────────────────────────────────────────────────

  test "subscribed? is true when subscribed_until is in the future" do
    user = User.new(subscribed_until: 1.hour.from_now)
    assert user.subscribed?
  end

  test "subscribed? is false when subscribed_until is in the past" do
    user = User.new(subscribed_until: 1.hour.ago)
    assert_not user.subscribed?
  end

  test "subscribed? is false when subscribed_until is nil" do
    user = User.new(subscribed_until: nil)
    assert_not user.subscribed?
  end

  test "subscribed? uses fixture pro_user correctly" do
    assert users(:pro_user).subscribed?
  end

  test "subscribed? uses fixture expired_user correctly" do
    assert_not users(:expired_user).subscribed?
  end

  # ── plan ─────────────────────────────────────────────────────────────────

  test "plan returns subscription_plan when subscribed" do
    user = User.new(subscribed_until: 1.hour.from_now, subscription_plan: "pro")
    assert_equal "pro", user.plan
  end

  test "plan returns 'free' when not subscribed" do
    user = User.new(subscribed_until: nil)
    assert_equal "free", user.plan
  end

  test "plan returns 'free' when subscription is expired" do
    user = User.new(subscribed_until: 1.second.ago, subscription_plan: "pro")
    assert_equal "free", user.plan
  end

  # ── free? ─────────────────────────────────────────────────────────────────

  test "free? is true when not subscribed" do
    user = User.new(subscribed_until: nil)
    assert user.free?
  end

  test "free? is false when subscribed" do
    user = User.new(subscribed_until: 1.hour.from_now)
    assert_not user.free?
  end

  # ── subscription_plan validation ─────────────────────────────────────────

  test "valid subscription plans are accepted" do
    user = users(:free_user)
    user.subscribed_until = 1.month.from_now

    %w[pro pro_yearly].each do |plan|
      user.subscription_plan = plan
      assert user.valid?, "Expected #{plan} to be valid"
    end
  end

  test "invalid subscription plan is rejected" do
    user = users(:free_user)
    user.subscription_plan = "enterprise"
    assert_not user.valid?
    assert_includes user.errors[:subscription_plan], "is not included in the list"
  end

  test "nil subscription_plan is allowed" do
    user = users(:free_user)
    user.subscription_plan = nil
    assert user.valid?
  end

  # ── from_omniauth ─────────────────────────────────────────────────────────

  test "from_omniauth creates a new user" do
    auth = build_omniauth(provider: "google", uid: "uid_brand_new",
                          email: "brandnew@example.com", name: "Brand New")

    assert_difference "User.count", 1 do
      user = User.from_omniauth(auth)
      assert_equal "google", user.provider
      assert_equal "uid_brand_new", user.uid
      assert_equal "brandnew@example.com", user.email_address
      assert_equal "Brand New", user.name
      assert user.terms_agreed_at.present?
    end
  end

  test "from_omniauth returns existing user without duplication" do
    existing = users(:free_user)
    auth = build_omniauth(provider: existing.provider, uid: existing.uid,
                          email: existing.email_address, name: existing.name)

    assert_no_difference "User.count" do
      user = User.from_omniauth(auth)
      assert_equal existing.id, user.id
    end
  end

  test "from_omniauth sets avatar_url for new user" do
    auth = build_omniauth(provider: "google", uid: "uid_avatar",
                          email: "avatar@example.com", name: "Avatar",
                          image: "https://example.com/avatar.jpg")
    user = User.from_omniauth(auth)
    assert_equal "https://example.com/avatar.jpg", user.avatar_url
  end

  private

  def build_omniauth(provider:, uid:, email:, name:, image: nil)
    OpenStruct.new(
      provider: provider,
      uid:      uid,
      info:     OpenStruct.new(email: email, name: name, image: image)
    )
  end
end
