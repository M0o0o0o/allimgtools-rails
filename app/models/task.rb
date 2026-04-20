class Task < ApplicationRecord
  has_many :uploads, foreign_key: :task_id, primary_key: :task_id

  TOOLS = %w[compress resize rotate convert].freeze
  STATUSES = %w[pending processing done failed].freeze

  BATCH_LIMIT_FREE = 10
  BATCH_LIMIT_PRO  = 30

  def self.batch_limit_for(user)
    user&.subscribed? ? BATCH_LIMIT_PRO : BATCH_LIMIT_FREE
  end
end
