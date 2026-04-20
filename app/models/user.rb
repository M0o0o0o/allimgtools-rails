class User < ApplicationRecord
  has_secure_password validations: false
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  PLANS = %w[pro pro_yearly].freeze

  validates :subscription_plan, inclusion: { in: PLANS }, allow_nil: true

  def subscribed?
    subscribed_until.present? && subscribed_until > Time.current
  end

  def plan
    subscribed? ? subscription_plan : "free"
  end

  def free?
    !subscribed?
  end

  def self.from_omniauth(auth)
    find_or_create_by(provider: auth.provider, uid: auth.uid) do |user|
      user.email_address   = auth.info.email
      user.name            = auth.info.name
      user.avatar_url      = auth.info.image
      user.terms_agreed_at = Time.current
    end
  end
end
