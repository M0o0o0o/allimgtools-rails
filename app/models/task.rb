class Task < ApplicationRecord
  has_many :uploads, foreign_key: :task_id, primary_key: :task_id

  TOOLS = %w[compress resize rotate convert].freeze
  STATUSES = %w[pending processing done failed].freeze

  DAILY_UPLOAD_LIMIT = 5

  def self.daily_upload_count(ip_address)
    Upload.where(ip_address: ip_address)
          .where(created_at: Time.current.beginning_of_day..)
          .where.not(status: "failed")
          .count
  end

  def self.limit_reached?(ip_address)
    daily_upload_count(ip_address) >= DAILY_UPLOAD_LIMIT
  end
end
