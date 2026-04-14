class User < ApplicationRecord
  has_secure_password validations: false
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  def self.from_omniauth(auth)
    find_or_create_by(provider: auth.provider, uid: auth.uid) do |user|
      user.email_address   = auth.info.email
      user.name            = auth.info.name
      user.avatar_url      = auth.info.image
      user.terms_agreed_at = Time.current
    end
  end
end
